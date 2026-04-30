import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mentor_booking_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/roadmap_detail_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/mentor_models.dart';
import '../../../data/models/node_mentoring_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';
import '../../../core/utils/error_handler.dart';

/// V3 Phase 2: Full Learner workspace for ROADMAP_MENTORING interaction.
/// Shows node selector, assignment/evidence/report tabs, and meetings panel.
class RoadmapWorkspacePage extends StatefulWidget {
  final int sessionId;
  final int? bookingId;
  final int? journeyId;

  const RoadmapWorkspacePage({
    super.key,
    required this.sessionId,
    this.bookingId,
    this.journeyId,
  });

  @override
  State<RoadmapWorkspacePage> createState() => _RoadmapWorkspacePageState();
}

class _RoadmapWorkspacePageState extends State<RoadmapWorkspacePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MentorBooking? _booking;
  bool _isLoading = true;
  bool _isCompletingNode = false;

  // Roadmap nodes for the dropdown selector
  List<Map<String, dynamic>> _nodes = [];
  String? _selectedNodeId; // null = Final Assessment

  // Form controllers
  final _submissionTextCtrl = TextEditingController();
  final _evidenceUrlCtrl = TextEditingController();
  bool _hasPreFilled = false;

  // Attachment state
  PlatformFile? _pickedAttachment;
  String? _attachmentPickError;
  static const int _maxAttachmentBytes = 10 * 1024 * 1024; // 10MB
  static const List<String> _allowedExtensions = [
    'pdf',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// True when booking is completed/pendingCompletion — workspace is read-only.
  bool get _isReadOnly =>
      _booking?.status == BookingStatus.completed ||
      _booking?.status == BookingStatus.pendingCompletion;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _submissionTextCtrl.dispose();
    _evidenceUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final bookingProvider = context.read<MentorBookingProvider>();
      final workspaceProvider = context.read<WorkspaceProvider>();
      final roadmapProvider = context.read<RoadmapDetailProvider>();

      // ── Ensure bookings are loaded ──
      if (bookingProvider.bookings.isEmpty) {
        await bookingProvider.loadBookings();
      }

      // ── Resolve booking ──
      MentorBooking? match;
      if (widget.bookingId != null) {
        match = bookingProvider.bookings
            .where((b) => b.id == widget.bookingId)
            .firstOrNull;
      }
      match ??= bookingProvider.bookings
          .where(
            (b) =>
                b.bookingType == 'ROADMAP_MENTORING' &&
                (widget.journeyId == null || b.journeyId == widget.journeyId) &&
                (b.status == BookingStatus.mentoringActive ||
                    b.status == BookingStatus.confirmed ||
                    b.status == BookingStatus.completed ||
                    b.status == BookingStatus.pendingCompletion),
          )
          .firstOrNull;

      _booking = match;

      // ── Populate roadmap nodes from RoadmapDetailProvider ──
      _syncNodesFromRoadmap(roadmapProvider);

      // ── Init workspace provider ──
      final jId = widget.journeyId ?? match?.journeyId;
      if (jId != null && match != null) {
        workspaceProvider.init(journeyId: jId, bookingId: match.id);
        await Future.wait([
          workspaceProvider.loadMeetings(),
          workspaceProvider.loadCompletionGate(),
        ]);

        // ── Auto-select first node so tabs have content on load ──
        if (_nodes.isNotEmpty) {
          _selectedNodeId = _nodes.first['id'] as String?;
          await workspaceProvider.selectNode(_selectedNodeId);
        }
      }
    } catch (e) {
      debugPrint('❌ _loadAll error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNodeSelected(String? nodeId) {
    setState(() => _selectedNodeId = nodeId);
    final wp = context.read<WorkspaceProvider>();
    wp.selectNode(nodeId);
    // Clear form and reset pre-fill flag when switching nodes
    _submissionTextCtrl.clear();
    _evidenceUrlCtrl.clear();
    _hasPreFilled = false;
  }

  void _syncNodesFromRoadmap(RoadmapDetailProvider roadmapProvider) {
    final roadmap = roadmapProvider.currentRoadmap;
    if (roadmap != null && roadmap.roadmap.isNotEmpty) {
      _nodes = roadmap.roadmap
          .map(
            (node) => {
              'id': node.id,
              'title': node.title,
              'type': node.isCoreNode ? 'CORE' : 'SIDE',
              'status': node.nodeStatus,
            },
          )
          .toList();
    } else {
      _nodes = [];
    }
  }

  Map<String, dynamic>? get _selectedNodeMeta {
    for (final node in _nodes) {
      if (node['id'] == _selectedNodeId) return node;
    }
    return null;
  }

  String get _selectedNodeTitle =>
      _selectedNodeMeta?['title'] as String? ?? 'node này';

  bool _requiresResubmissionBeforeComplete(
    NodeEvidenceRecordResponse? evidence,
  ) {
    return evidence?.submissionStatus == NodeSubmissionStatus.reworkRequested;
  }

  bool _isSelectedNodeMarkedComplete(NodeEvidenceRecordResponse? evidence) {
    if (evidence == null) return false;

    // Rework means the learner must submit/update evidence and confirm
    // completion again, even if roadmap progress still says COMPLETED.
    if (_requiresResubmissionBeforeComplete(evidence)) {
      return false;
    }

    if (evidence.latestVerification?.nodeVerificationStatus ==
            NodeVerificationStatus.verified ||
        evidence.verificationStatus == NodeVerificationStatus.verified) {
      return true;
    }

    return evidence.learnerMarkedComplete == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? Center(child: CommonLoading.center())
            : _booking == null
            ? _buildNoBookingState(context, isDark)
            : _buildWorkspaceContent(context, isDark),
      ),
    );
  }

  // ─── No Booking ───────────────────────────────────────────────────────

  Widget _buildNoBookingState(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildAppBar(context, isDark),
        Expanded(
          child: EmptyStateWidget(
            icon: Icons.person_search_outlined,
            title: 'Chưa có Mentor đồng hành',
            subtitle:
                'Bạn chưa có booking ROADMAP_MENTORING nào đang hoạt động.\n'
                'Hãy quay lại Roadmap và bấm "Tìm Mentor đồng hành".',
            ctaLabel: 'Quay lại',
            onCtaPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          Expanded(
            child: Text(
              'Không gian Mentor',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          _buildVerificationGateAction(context),
        ],
      ),
    );
  }

  /// Icon shortcut to Final Verification page. State reflects gate status.
  Widget _buildVerificationGateAction(BuildContext context) {
    final journeyId = widget.journeyId ?? _booking?.journeyId;
    if (journeyId == null) return const SizedBox.shrink();

    return Consumer<WorkspaceProvider>(
      builder: (_, wp, __) {
        final gate = wp.completionGate;
        if (gate == null ||
            gate.finalGateStatus == FinalGateStatus.notRequired) {
          return const SizedBox.shrink();
        }

        final isPassed = gate.finalGateStatus == FinalGateStatus.passed;
        final color = isPassed ? AppTheme.successColor : AppTheme.warningColor;
        final icon = isPassed ? Icons.verified : Icons.lock_outline;
        final tooltip = isPassed
            ? 'Đã xác thực — xem chi tiết'
            : 'Cổng xác thực bị chặn (${gate.blockingReasons.length} lý do)';

        return Tooltip(
          message: tooltip,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () =>
                    context.push('/journey/$journeyId/final-verification'),
                icon: Icon(icon, color: color, size: 22),
              ),
              if (!isPassed && gate.blockingReasons.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '${gate.blockingReasons.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Main Content ─────────────────────────────────────────────────────

  Widget _buildWorkspaceContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildAppBar(context, isDark),
        _buildMentorHeader(context, isDark),
        _buildNodeSelector(context, isDark),
        // Tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorderColor
                    : AppTheme.lightBorderColor,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
            unselectedLabelColor: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            indicatorColor: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Nhiệm vụ'),
              Tab(text: 'Nộp bài'),
              Tab(text: 'Kết quả'),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignmentTab(context, isDark),
              _buildSubmitTab(context, isDark),
              _buildReportTab(context, isDark),
            ],
          ),
        ),
        // Meetings panel at bottom
        _buildMeetingsPanel(context, isDark),
      ],
    );
  }

  // ─── Mentor Header ────────────────────────────────────────────────────

  Widget _buildMentorHeader(BuildContext context, bool isDark) {
    final booking = _booking!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
              backgroundImage: booking.mentorAvatar != null
                  ? NetworkImage(booking.mentorAvatar!)
                  : null,
              child: booking.mentorAvatar == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.mentorName ?? 'Mentor',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.statusText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: booking.meetingLink != null
                  ? () => _launchUrl(booking.meetingLink!)
                  : null,
              icon: Icon(
                Icons.videocam_outlined,
                color: booking.meetingLink != null
                    ? AppTheme.primaryBlueDark
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              tooltip: 'Tham gia video call',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Node Selector Dropdown ───────────────────────────────────────────

  Widget _buildNodeSelector(BuildContext context, bool isDark) {
    // Build items: roadmap nodes + Final Assessment
    final items = <DropdownMenuItem<String?>>[];

    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final id = node['id'] as String?;
      final title = node['title'] as String? ?? 'Node ${i + 1}';
      final type = node['type'] as String?;
      final status = node['status'] as String?;

      items.add(
        DropdownMenuItem<String?>(
          value: id,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.accentCyan : AppTheme.primaryBlue)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              if (type == 'SIDE') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Phụ',
                    style: TextStyle(fontSize: 9, color: AppTheme.warningColor),
                  ),
                ),
              ],
              if (status == 'COMPLETED') ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
              ] else if (status == 'LOCKED') ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_outline, size: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
              ],
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String?>(
        value: _selectedNodeId,
        decoration: InputDecoration(
          labelText: 'Chọn Node',
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        items: items,
        onChanged: _onNodeSelected,
        isExpanded: true,
        dropdownColor: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TAB 1: ASSIGNMENT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAssignmentTab(BuildContext context, bool isDark) {
    return Consumer<WorkspaceProvider>(
      builder: (context, wp, _) {
        if (wp.isLoadingNode) {
          return Center(child: CommonLoading.small());
        }

        final assignment = wp.assignment;
        if (assignment == null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: 'Mentor chưa giao nhiệm vụ',
              subtitle:
                  'Khi mentor thiết lập yêu cầu cho node này,\n'
                  'nội dung nhiệm vụ sẽ hiển thị tại đây.',
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source badge
              Row(
                children: [
                  _buildBadge(
                    assignment.assignmentSource ==
                            AssignmentSource.mentorRefined
                        ? 'Mentor biên soạn'
                        : 'Hệ thống tạo',
                    assignment.assignmentSource ==
                            AssignmentSource.mentorRefined
                        ? AppTheme.primaryBlue
                        : AppTheme.warningColor,
                  ),
                  const Spacer(),
                  if (assignment.createdAt != null)
                    Text(
                      DateFormat('dd/MM/yyyy').format(assignment.createdAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (assignment.title != null) ...[
                Text(
                  assignment.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (assignment.description != null)
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: _buildMarkdown(assignment.description!, isDark),
                ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TAB 2: SUBMIT EVIDENCE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSubmitTab(BuildContext context, bool isDark) {
    return Consumer<WorkspaceProvider>(
      builder: (context, wp, _) {
        if (wp.isLoadingNode) {
          return Center(child: CommonLoading.small());
        }

        // Pre-fill if existing evidence (guarded with flag to prevent rebuild reset)
        if (!_hasPreFilled &&
            wp.evidence != null &&
            _submissionTextCtrl.text.isEmpty) {
          _submissionTextCtrl.text = wp.evidence!.submissionText ?? '';
          _evidenceUrlCtrl.text = wp.evidence!.evidenceUrl ?? '';
          _hasPreFilled = true;
        }
        if (!_hasPreFilled &&
            wp.outputAssessment != null &&
            _submissionTextCtrl.text.isEmpty) {
          _submissionTextCtrl.text = wp.outputAssessment!.submissionText ?? '';
          _evidenceUrlCtrl.text = wp.outputAssessment!.evidenceUrl ?? '';
          _hasPreFilled = true;
        }

        // Show rework feedback if mentor requested changes
        final showReworkBanner =
            wp.evidence?.reworkRequested == true &&
            wp.evidence?.latestReview?.feedback != null;

        final hasExisting = wp.evidence != null || wp.outputAssessment != null;
        final statusBadge = wp.evidence?.submissionStatus;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Nộp minh chứng',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (statusBadge != null)
                    _buildBadge(
                      statusBadge.displayName,
                      statusBadge == NodeSubmissionStatus.submitted
                          ? AppTheme.successColor
                          : statusBadge == NodeSubmissionStatus.reworkRequested
                          ? AppTheme.warningColor
                          : AppTheme.primaryBlue,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Rework banner: show mentor feedback when rework requested
              if (showReworkBanner) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Mentor yêu cầu làm lại',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildMarkdown(
                        wp.evidence!.latestReview!.feedback!,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _submissionTextCtrl,
                      maxLines: 4,
                      readOnly: _isReadOnly,
                      decoration: InputDecoration(
                        hintText: 'Mô tả bài làm, phương pháp, kết quả...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _evidenceUrlCtrl,
                      readOnly: _isReadOnly,
                      decoration: InputDecoration(
                        hintText: 'Link Google Drive, GitHub, URL...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.link, size: 20),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAttachmentZone(context, isDark, wp),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isReadOnly || wp.isSubmitting || wp.isUploading
                            ? null
                            : _onSubmitEvidence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlueDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: wp.isUploading
                            ? Text(
                                'Đang tải file ${(wp.uploadProgress * 100).toStringAsFixed(0)}%',
                              )
                            : wp.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                hasExisting
                                    ? 'Cập nhật minh chứng'
                                    : 'Nộp minh chứng',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (wp.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  wp.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildNodeCompletionCard(context, isDark, wp),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentZone(
    BuildContext context,
    bool isDark,
    WorkspaceProvider wp,
  ) {
    final picked = _pickedAttachment;
    final existingUrl =
        wp.evidence?.attachmentUrl ?? wp.outputAssessment?.attachmentUrl;

    final borderColor = isDark
        ? AppTheme.darkBorderColor
        : AppTheme.lightBorderColor;
    final accent = isDark ? AppTheme.accentCyan : AppTheme.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _isReadOnly || wp.isUploading || picked != null
              ? null
              : _onPickAttachment,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: picked != null
                  ? accent.withValues(alpha: 0.06)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: picked != null ? accent : borderColor,
                width: picked != null ? 1.5 : 1,
                style: picked != null ? BorderStyle.solid : BorderStyle.solid,
              ),
            ),
            child: picked != null
                ? Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (picked.extension ?? 'FILE').toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              picked.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatBytes(picked.size),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isReadOnly && !wp.isUploading)
                        IconButton(
                          onPressed: _onRemoveAttachment,
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Bỏ file',
                        ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 28,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Đính kèm file (PDF / DOCX / Ảnh)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tối đa 10MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_attachmentPickError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 14,
                color: AppTheme.errorColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _attachmentPickError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (wp.isUploading) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: wp.uploadProgress > 0 ? wp.uploadProgress : null,
              minHeight: 6,
              backgroundColor: borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
        if (picked == null && existingUrl != null && existingUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openUrl(existingUrl),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'File đã đính kèm — Tải xuống',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      ErrorHandler.showWarningSnackBar(context, 'Liên kết không hợp lệ');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ErrorHandler.showWarningSnackBar(context, 'Không thể mở liên kết');
    }
  }

  Future<void> _onPickAttachment() async {
    setState(() => _attachmentPickError = null);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > _maxAttachmentBytes) {
        setState(() => _attachmentPickError = 'File vượt quá 10MB');
        return;
      }
      final ext = (file.extension ?? '').toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        setState(() => _attachmentPickError =
            'Định dạng không hỗ trợ. Cho phép: ${_allowedExtensions.join(", ")}');
        return;
      }
      setState(() => _pickedAttachment = file);
    } catch (e) {
      setState(() => _attachmentPickError = 'Không thể chọn file: $e');
    }
  }

  void _onRemoveAttachment() {
    setState(() {
      _pickedAttachment = null;
      _attachmentPickError = null;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _onSubmitEvidence() async {
    final text = _submissionTextCtrl.text.trim();
    final urlText = _evidenceUrlCtrl.text.trim();
    if (text.isEmpty && urlText.isEmpty && _pickedAttachment == null) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng nhập nội dung, link hoặc đính kèm file.',
      );
      return;
    }

    // URL validation
    if (urlText.isNotEmpty) {
      final uri = Uri.tryParse(urlText);
      if (uri == null || (!uri.hasScheme || !uri.host.contains('.'))) {
        ErrorHandler.showWarningSnackBar(
          context,
          'URL không hợp lệ. VD: https://drive.google.com/...',
        );
        return;
      }
    }

    final wp = context.read<WorkspaceProvider>();

    // Step 1: upload attachment if a new file was picked
    String? attachmentUrl =
        wp.evidence?.attachmentUrl ?? wp.outputAssessment?.attachmentUrl;
    if (_pickedAttachment != null && _pickedAttachment!.path != null) {
      final actorId = context.read<AuthProvider>().user?.id;
      if (actorId == null) {
        ErrorHandler.showErrorSnackBar(context, 'Bạn cần đăng nhập lại.');
        return;
      }
      final uploadedUrl = await wp.uploadAttachment(
        filePath: _pickedAttachment!.path!,
        fileName: _pickedAttachment!.name,
        actorId: actorId,
      );
      if (uploadedUrl == null) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            wp.error ?? 'Tải file lên thất bại',
          );
        }
        return;
      }
      attachmentUrl = uploadedUrl;
    }

    // Step 2: submit evidence
    final success = await wp.submitEvidence(
      submissionText: text,
      evidenceUrl: urlText.isNotEmpty ? urlText : null,
      attachmentUrl: attachmentUrl,
    );

    if (success && mounted) {
      setState(() => _pickedAttachment = null);
      ErrorHandler.showSuccessSnackBar(
        context,
        'Đã nộp minh chứng thành công!',
      );
      _tabController.animateTo(2); // Switch to Report tab
    }
  }

  Future<void> _completeSelectedNode(BuildContext context) async {
    final nodeId = _selectedNodeId;
    if (nodeId == null) return;

    final wp = context.read<WorkspaceProvider>();
    if (wp.evidence == null) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Bạn cần nộp minh chứng trước khi đánh dấu hoàn thành node.',
      );
      return;
    }

    if (_isSelectedNodeMarkedComplete(wp.evidence)) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'Node này đã được đánh dấu hoàn thành rồi.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đánh dấu hoàn thành node?'),
        content: Text(
          'Sau bước này, mentor sẽ có thể bắt đầu đánh giá bài nộp cho "$_selectedNodeTitle".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isCompletingNode = true);

    try {
      final roadmapProvider = context.read<RoadmapDetailProvider>();
      await roadmapProvider.completeNode(widget.sessionId, nodeId);
      if (!mounted) return;

      _syncNodesFromRoadmap(roadmapProvider);
      await wp.selectNode(nodeId);
      await wp.loadCompletionGate();
      if (!mounted) return;

      ErrorHandler.showSuccessSnackBar(
        context,
        'Đã đánh dấu hoàn thành node. Mentor giờ có thể bắt đầu đánh giá.',
      );
      _tabController.animateTo(2);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isCompletingNode = false);
      }
    }
  }

  Widget _buildNodeCompletionCard(
    BuildContext context,
    bool isDark,
    WorkspaceProvider wp,
  ) {
    final evidence = wp.evidence;
    final hasEvidence = evidence != null;
    final isCompleted = _isSelectedNodeMarkedComplete(evidence);
    final requiresResubmission = _requiresResubmissionBeforeComplete(evidence);
    final isResubmitted =
        evidence?.submissionStatus == NodeSubmissionStatus.resubmitted;
    final canComplete =
        hasEvidence &&
        !isCompleted &&
        !requiresResubmission &&
        !_isReadOnly &&
        !_isCompletingNode &&
        !wp.isSubmitting;

    final title = isCompleted
        ? 'Node đã sẵn sàng để mentor đánh giá'
        : requiresResubmission
        ? 'Mentor yêu cầu bạn làm lại node này'
        : isResubmitted
        ? 'Bước 2: Xác nhận lại hoàn thành node'
        : 'Bước 2: Đánh dấu hoàn thành node';
    final subtitle = isCompleted
        ? 'Bạn đã xác nhận hoàn thành "$_selectedNodeTitle". Mentor có thể review bài nộp và quyết định bước xác thực tiếp theo.'
        : requiresResubmission
        ? 'Mentor đã yêu cầu chỉnh sửa bài nộp của "$_selectedNodeTitle". Hãy cập nhật minh chứng trước, sau đó quay lại đây để xác nhận hoàn thành lại node.'
        : hasEvidence
        ? isResubmitted
              ? 'Bạn đã nộp lại minh chứng cho "$_selectedNodeTitle". Hãy xác nhận hoàn thành lại node để mentor có thể review lần tiếp theo.'
              : 'Bạn đã nộp minh chứng cho "$_selectedNodeTitle". Hãy xác nhận hoàn thành node để mentor có thể bắt đầu đánh giá.'
        : 'Sau khi nộp minh chứng, bạn cần quay lại đây để xác nhận đã hoàn tất node. Mentor chỉ review khi node đã được learner đánh dấu hoàn thành.';
    final color = isCompleted
        ? AppTheme.successColor
        : requiresResubmission
        ? AppTheme.warningColor
        : hasEvidence
        ? AppTheme.warningColor
        : (isDark ? AppTheme.accentCyan : AppTheme.primaryBlue);

    return GlassCard(
      backgroundColor: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_outline
                    : Icons.assignment_turned_in_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canComplete
                  ? () => _completeSelectedNode(context)
                  : null,
              icon: _isCompletingNode
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isCompleted
                          ? Icons.verified_outlined
                          : Icons.done_all_outlined,
                      size: 18,
                    ),
              label: Text(
                isCompleted
                    ? 'Đã hoàn thành node'
                    : requiresResubmission
                    ? 'Cập nhật minh chứng trước'
                    : hasEvidence
                    ? isResubmitted
                          ? 'Xác nhận hoàn thành lại node'
                          : 'Đánh dấu hoàn thành node'
                    : 'Nộp minh chứng trước',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? AppTheme.successColor : color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TAB 3: REPORT
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildReportTab(BuildContext context, bool isDark) {
    return Consumer<WorkspaceProvider>(
      builder: (context, wp, _) {
        if (wp.isLoadingNode) {
          return Center(child: CommonLoading.small());
        }

        final evidence = wp.evidence;
        if (evidence == null) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: EmptyStateWidget(
              icon: Icons.rate_review_outlined,
              title: 'Chưa có kết quả',
              subtitle:
                  'Bạn cần nộp minh chứng trước.\n'
                  'Sau khi mentor xem xét, kết quả sẽ hiển thị tại đây.',
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNodeCompletionCard(context, isDark, wp),
              const SizedBox(height: 16),
              // Verification status
              if (evidence.verificationStatus != null)
                Row(
                  children: [
                    _buildStatusChip(evidence.verificationStatus!),
                    const Spacer(),
                    if (evidence.submittedAt != null)
                      Text(
                        'Nộp: ${_formatDate(evidence.submittedAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),

              // Latest Review
              if (evidence.latestReview != null) ...[
                _buildSectionTitle('Đánh giá của Mentor', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildBadge(
                            _reviewResultLabel(
                              evidence.latestReview!.reviewResult,
                            ),
                            _reviewResultColor(
                              evidence.latestReview!.reviewResult,
                            ),
                          ),
                          if (evidence.latestReview!.score != null) ...[
                            const Spacer(),
                            Text(
                              '${evidence.latestReview!.score}/100',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.accentCyan
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (evidence.latestReview!.feedback != null) ...[
                        const SizedBox(height: 10),
                        _buildMarkdown(evidence.latestReview!.feedback!, isDark),
                      ],
                    ],
                  ),
                ),
              ],

              // Latest Verification
              if (evidence.latestVerification != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Xác thực Node', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBadge(
                        evidence
                                .latestVerification!
                                .nodeVerificationStatus
                                ?.displayName ??
                            'Chờ xử lý',
                        _verificationStatusColor(
                          evidence.latestVerification!.nodeVerificationStatus ??
                              NodeVerificationStatus.pending,
                        ),
                      ),
                      if (evidence.latestVerification!.verificationNote !=
                          null) ...[
                        const SizedBox(height: 8),
                        _buildMarkdown(
                          evidence.latestVerification!.verificationNote!,
                          isDark,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Show submitted content
              if (evidence.submissionText != null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Bài làm đã nộp', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evidence.submissionText!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      if (evidence.evidenceUrl != null &&
                          evidence.evidenceUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _openUrl(evidence.evidenceUrl!),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.link,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  evidence.evidenceUrl!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (evidence.attachmentUrl != null &&
                          evidence.attachmentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openUrl(evidence.attachmentUrl!),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file,
                                size: 14,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              const Flexible(
                                child: Text(
                                  'Tải file đính kèm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Mentor feedback (if separate)
              if (evidence.mentorFeedback != null &&
                  evidence.latestReview?.feedback == null) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Phản hồi Mentor', isDark),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: _buildMarkdown(evidence.mentorFeedback!, isDark),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  MEETINGS PANEL (bottom collapsible)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMeetingsPanel(BuildContext context, bool isDark) {
    return Consumer<WorkspaceProvider>(
      builder: (context, wp, _) {
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppTheme.darkBorderColor
                    : AppTheme.lightBorderColor,
              ),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            leading: const Icon(Icons.calendar_month, size: 18),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Lịch hẹn với Mentor (${wp.meetings.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCreateMeetingSheet(context, isDark),
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
                  ),
                  tooltip: 'Đề xuất meeting mới',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            children: [
              if (wp.isLoadingMeetings)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CommonLoading.small(),
                )
              else if (wp.meetings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Chưa có meeting nào. Bấm + để đề xuất.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                )
              else
                ...wp.meetings.map(
                  (m) => _buildMeetingCard(context, isDark, m, wp),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeetingCard(
    BuildContext context,
    bool isDark,
    RoadmapFollowUpMeetingDTO m,
    WorkspaceProvider wp,
  ) {
    final status = m.status?.toUpperCase() ?? 'SCHEDULED';
    final canAccept = status == 'PENDING_LEARNER';
    final canJoin = m.canJoin == true;
    final canDelete =
        status == 'PENDING_MENTOR'; // Learner can delete own pending meetings

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.title ?? 'Meeting',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                _buildBadge(m.statusLabel, _meetingStatusColor(status)),
              ],
            ),
            if (m.purpose != null) ...[
              const SizedBox(height: 4),
              Text(
                m.purpose!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  m.scheduledAtLocal != null
                      ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(m.scheduledAtLocal!)
                      : 'Chưa xác định',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                if (m.durationMinutes != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${m.durationMinutes} phút',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
            // Action buttons
            if (canAccept || canJoin || canDelete) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canDelete)
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận xoá'),
                            content: const Text(
                              'Bạn có chắc muốn xoá lịch hẹn này?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Huỷ'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Xoá',
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && m.id != null) {
                          final ok = await wp.deleteMeeting(m.id!);
                          if (ok && mounted) {
                            ErrorHandler.showSuccessSnackBar(
                              context,
                              'Đã xoá lịch hẹn',
                            );
                          } else if (!ok && mounted) {
                            ErrorHandler.showErrorSnackBar(
                              context,
                              wp.error ?? 'Không thể xoá lịch hẹn',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppTheme.errorColor,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(right: 8),
                      tooltip: 'Xoá lịch hẹn',
                    ),
                  if (canAccept) ...[
                    TextButton(
                      onPressed: () async {
                        final reason = await _showRejectReasonDialog(context);
                        if (reason != null && m.id != null) {
                          final ok = await wp.rejectMeeting(
                            m.id!,
                            reason: reason,
                          );
                          if (ok && mounted) {
                            ErrorHandler.showSuccessSnackBar(
                              context,
                              'Đã từ chối lịch hẹn',
                            );
                          } else if (!ok && mounted) {
                            ErrorHandler.showErrorSnackBar(
                              context,
                              wp.error ?? 'Không thể từ chối lịch hẹn',
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Từ chối',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (m.id != null) {
                          final ok = await wp.acceptMeeting(m.id!);
                          if (ok && mounted) {
                            ErrorHandler.showSuccessSnackBar(
                              context,
                              'Đã chấp nhận lịch hẹn!',
                            );
                          } else if (!ok && mounted) {
                            ErrorHandler.showErrorSnackBar(
                              context,
                              wp.error ?? 'Không thể chấp nhận lịch hẹn',
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Chấp nhận'),
                    ),
                  ],
                  if (canJoin && m.meetingLink != null)
                    ElevatedButton.icon(
                      onPressed: () => _launchUrl(m.meetingLink!),
                      icon: const Icon(Icons.videocam, size: 16),
                      label: const Text('Tham gia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlueDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Create Meeting Sheet ─────────────────────────────────────────────

  void _showCreateMeetingSheet(BuildContext context, bool isDark) {
    final titleCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    int selectedDuration = 45;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? AppTheme.darkCardBackground
          : AppTheme.lightCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đề xuất Meeting mới',
                style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: purposeCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Mục đích *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (ctx2, setSheetState) {
                  return Column(
                    children: [
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, size: 18),
                        title: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: ctx2,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: ctx2,
                                initialTime: TimeOfDay.fromDateTime(
                                  selectedDate,
                                ),
                              );
                              if (time != null) {
                                final combined = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                // Block past times for today
                                if (combined.isBefore(DateTime.now())) {
                                  if (ctx2.mounted) {
                                    ScaffoldMessenger.of(ctx2).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Không thể chọn thời gian trong quá khứ',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                setSheetState(() {
                                  selectedDate = combined;
                                });
                              }
                            }
                          },
                          child: const Text(
                            'Chọn',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Thời lượng: ',
                            style: TextStyle(fontSize: 13),
                          ),
                          DropdownButton<int>(
                            value: selectedDuration,
                            items: [30, 45, 60, 90].map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text(
                                  '$d phút',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setSheetState(() => selectedDuration = v);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        purposeCtrl.text.trim().isEmpty) {
                      ErrorHandler.showWarningSnackBar(
                        context,
                        'Vui lòng điền tiêu đề và mục đích',
                      );
                      return;
                    }
                    final wp = context.read<WorkspaceProvider>();
                    final success = await wp.createMeeting(
                      CreateFollowUpMeetingRequest(
                        title: titleCtrl.text.trim(),
                        purpose: purposeCtrl.text.trim(),
                        scheduledAt: selectedDate.toUtc().toIso8601String(),
                        durationMinutes: selectedDuration,
                      ),
                    );
                    if (success) {
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ErrorHandler.showSuccessSnackBar(
                          context,
                          'Đã gửi yêu cầu meeting!',
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Gửi đề xuất'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showRejectReasonDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối meeting', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Lý do (tùy chọn)',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMarkdown(String data, bool isDark) {
    final baseColor = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    return MarkdownBody(
      data: data,
      onTapLink: (_, href, _) {
        if (href != null && href.isNotEmpty) _openUrl(href);
      },
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 13, height: 1.5, color: baseColor),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        h3: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
        listBullet: TextStyle(fontSize: 13, color: baseColor),
        a: const TextStyle(
          color: AppTheme.primaryBlue,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        blockquote: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(NodeVerificationStatus status) {
    return _buildBadge(status.displayName, _verificationStatusColor(status));
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Color _verificationStatusColor(NodeVerificationStatus status) {
    switch (status) {
      case NodeVerificationStatus.pending:
        return Colors.grey;
      case NodeVerificationStatus.underReview:
        return AppTheme.warningColor;
      case NodeVerificationStatus.approved:
        return AppTheme.successColor;
      case NodeVerificationStatus.rejected:
        return AppTheme.errorColor;
      case NodeVerificationStatus.verified:
        return AppTheme.primaryBlue;
    }
  }

  String _reviewResultLabel(NodeReviewResult? result) {
    switch (result) {
      case NodeReviewResult.approved:
        return 'Đạt';
      case NodeReviewResult.reworkRequested:
        return 'Yêu cầu làm lại';
      case NodeReviewResult.rejected:
        return 'Không đạt';
      default:
        return 'Chờ xử lý';
    }
  }

  Color _reviewResultColor(NodeReviewResult? result) {
    switch (result) {
      case NodeReviewResult.approved:
        return AppTheme.successColor;
      case NodeReviewResult.reworkRequested:
        return AppTheme.warningColor;
      case NodeReviewResult.rejected:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  Color _meetingStatusColor(String status) {
    switch (status) {
      case 'PENDING_MENTOR':
      case 'PENDING_LEARNER':
        return AppTheme.warningColor;
      case 'ACCEPTED':
        return AppTheme.successColor;
      case 'REJECTED':
      case 'CANCELLED':
        return AppTheme.errorColor;
      case 'COMPLETED':
        return AppTheme.primaryBlue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
