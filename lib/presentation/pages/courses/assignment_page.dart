import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/assignment_models.dart';
import '../../../data/services/assignment_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/html_helper.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_grading_provider.dart';
import '../../providers/auth_provider.dart';

/// AssignmentPage — student submits assignments and views grading results
/// Navigates from: CourseLearningPage → push('/assignment/:assignmentId')
class AssignmentPage extends StatefulWidget {
  final int assignmentId;
  final VoidCallback? onSubmitted;
  final bool isInline;

  const AssignmentPage({
    super.key,
    required this.assignmentId,
    this.onSubmitted,
    this.isInline = false,
  });

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final AssignmentService _assignmentService = AssignmentService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  AssignmentDetailDto? _assignment;
  List<AssignmentSubmissionDetailDto> _submissions = [];

  // Form state
  final _textController = TextEditingController();
  final _linkController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _assignmentService.getAssignmentById(widget.assignmentId),
        _assignmentService.getMySubmissions(widget.assignmentId),
      ]);

      setState(() {
        _assignment = results[0] as AssignmentDetailDto;
        _submissions = results[1] as List<AssignmentSubmissionDetailDto>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // ── Grading Mode Helpers ──────────────────────────────────────────────────

  /// True when this assignment uses AI auto-grading.
  bool get _isAiGrading => _assignment?.aiGradingEnabled == true;

  // ── Submission Gate Logic ─────────────────────────────────────────────────

  /// Check if student can submit.
  /// Blocked only while the current attempt is still being processed by AI/mentor,
  /// or when the latest attempt has already passed.
  ///
  /// Legacy `AI_PENDING` submissions are treated as an AI-reviewed result for the
  /// current attempt: learner may submit a new attempt if not passed, or request
  /// mentor review if they disagree with the AI result.
  bool get _canSubmit {
    if (_submissions.isEmpty) return true;
    final latest = _submissions.first;
    final isBlocked =
        latest.status == SubmissionStatus.pending ||
        latest.status == SubmissionStatus.latePending;
    final isPassed = latest.isPassed == true;
    return !isBlocked && !isPassed;
  }

  AssignmentSubmissionDetailDto? get _latestSubmission {
    return _submissions.isNotEmpty ? _submissions.first : null;
  }

  /// True when the latest submission is waiting for mentor grading (PENDING or LATE_PENDING).
  bool get _isPendingSubmission {
    if (_submissions.isEmpty) return false;
    final s = _submissions.first.status;
    return s == SubmissionStatus.pending || s == SubmissionStatus.latePending;
  }

  /// Legacy state where AI result exists but backend still labels the attempt as AI_PENDING.
  bool get _isAiPendingSubmission {
    if (_submissions.isEmpty) return false;
    return _submissions.first.status == SubmissionStatus.aiPending;
  }

  // ── File Picking ──────────────────────────────────────────────────────────

  /// Max upload size allowed by backend (10 MB)
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  /// Extensions accepted by backend MediaServiceImpl
  static const List<String> _allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'txt',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'zip',
    'rar',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size against backend 10MB limit
        if (file.size > _maxFileSizeBytes) {
          if (mounted) {
            ErrorHandler.showWarningSnackBar(
              context,
              'File vượt quá 10MB. Vui lòng chọn file nhỏ hơn.',
            );
          }
          return;
        }

        setState(() => _selectedFile = file);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Không thể chọn file: $e');
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final assignment = _assignment;
    if (assignment == null) return;

    final subType = assignment.submissionType;

    // Validate based on submission type
    if (subType == SubmissionType.text ||
        subType == SubmissionType.textAndFile) {
      if (_textController.text.trim().isEmpty) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Vui lòng nhập nội dung bài tập',
        );
        return;
      }
    }

    if (subType == SubmissionType.link ||
        subType == SubmissionType.linkAndFile) {
      if (_linkController.text.trim().isEmpty) {
        ErrorHandler.showWarningSnackBar(context, 'Vui lòng nhập đường dẫn');
        return;
      }
      final url = _linkController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Đường dẫn không hợp lệ (phải bắt đầu bằng http:// hoặc https://)',
        );
        return;
      }
    }

    if (subType == SubmissionType.file ||
        subType == SubmissionType.textAndFile ||
        subType == SubmissionType.linkAndFile) {
      if (_selectedFile == null) {
        ErrorHandler.showWarningSnackBar(context, 'Vui lòng chọn file để nộp');
        return;
      }
    }

    // Confirm dialog
    final confirmed = await _showConfirmDialog(
      'Xác nhận nộp bài',
      'Bạn có chắc muốn nộp bài? Sau khi nộp không thể sửa.',
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      int? fileMediaId;

      // Upload file first if needed
      if (_selectedFile != null &&
          (subType == SubmissionType.file ||
              subType == SubmissionType.textAndFile ||
              subType == SubmissionType.linkAndFile)) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        fileMediaId = await _uploadFileWithProgress(_selectedFile!);

        setState(() => _isUploading = false);
      }

      // Build submission DTO
      final submission = AssignmentSubmissionCreateDto(
        submissionText: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : null,
        linkUrl: _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        fileMediaId: fileMediaId,
      );

      await _assignmentService.submitAssignment(
        assignmentId: widget.assignmentId,
        submission: submission,
      );

      // Clear form
      _textController.clear();
      _linkController.clear();
      setState(() {
        _selectedFile = null;
        _isSubmitting = false;
      });

      if (mounted) {
        final msg = _isAiGrading
            ? '✅ Đã nộp bài! AI sẽ chấm tự động.'
            : '✅ Nộp bài thành công! Bài đang chờ Mentor chấm.';
        ErrorHandler.showSuccessSnackBar(context, msg);
      }

      // Reload data
      await _loadData();

      if (widget.onSubmitted != null) {
        widget.onSubmitted!();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isUploading = false;
      });
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Future<int> _uploadFileWithProgress(PlatformFile file) async {
    if (file.path == null) {
      throw Exception('File không có đường dẫn');
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      throw Exception(
        'Không xác định được người dùng. Vui lòng đăng nhập lại.',
      );
    }

    return _assignmentService.uploadMediaFile(
      file.path!,
      file.name,
      actorId: userId,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _getSubmissionTypeLabel(SubmissionType? type) {
    switch (type) {
      case SubmissionType.text:
        return 'Nộp văn bản';
      case SubmissionType.link:
        return 'Nộp đường dẫn';
      case SubmissionType.file:
        return 'Nộp file';
      case SubmissionType.textAndFile:
        return 'Nộp văn bản + file';
      case SubmissionType.linkAndFile:
        return 'Nộp đường dẫn + file';
      default:
        return 'Nộp bài';
    }
  }

  String _getSubmissionTypeHint(SubmissionType? type) {
    switch (type) {
      case SubmissionType.text:
        return 'Nhập nội dung bài làm của bạn...';
      case SubmissionType.link:
        return 'Nhập đường dẫn (GitHub, Figma, Google Drive...)';
      case SubmissionType.file:
        return 'Chọn file để nộp (tài liệu, code, hình ảnh...)';
      case SubmissionType.textAndFile:
        return 'Nhập nội dung và đính kèm file';
      case SubmissionType.linkAndFile:
        return 'Nhập đường dẫn và đính kèm file minh chứng';
      default:
        return 'Nộp bài tập của bạn';
    }
  }

  IconData _getStatusIcon(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
      case SubmissionStatus.latePending:
        return Icons.hourglass_empty;
      case SubmissionStatus.aiPending:
        return Icons.smart_toy_outlined;
      case SubmissionStatus.graded:
      case SubmissionStatus.lateGraded:
        return Icons.check_circle;
      case SubmissionStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
        return AppTheme.warningColor;
      case SubmissionStatus.latePending:
        return Colors.orange;
      case SubmissionStatus.aiPending:
        return Colors.deepPurple;
      case SubmissionStatus.graded:
      case SubmissionStatus.lateGraded:
        return AppTheme.successColor;
      case SubmissionStatus.rejected:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
        return 'Đang chờ chấm';
      case SubmissionStatus.latePending:
        return 'Nộp muộn - Đang chờ';
      case SubmissionStatus.aiPending:
        return 'AI đã chấm, chờ Mentor xác nhận';
      case SubmissionStatus.graded:
        return 'Đã chấm';
      case SubmissionStatus.lateGraded:
        return 'Nộp muộn - Đã chấm';
      case SubmissionStatus.rejected:
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Inline mode: no Scaffold, embed directly in parent
    if (widget.isInline) {
      return _buildBody();
    }

    // Full-screen mode (standalone)
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Bài tập',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          if (_submissions.isNotEmpty)
            IconButton(
              icon: Icon(_showHistory ? Icons.edit_note : Icons.history),
              onPressed: () => setState(() => _showHistory = !_showHistory),
              tooltip: _showHistory ? 'Xem bài nộp' : 'Lịch sử nộp bài',
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return CommonLoading.center();

    if (_errorMessage != null) {
      return ErrorStateWidget(message: _errorMessage!, onRetry: _loadData);
    }

    if (_assignment == null) {
      return const Center(child: Text('Không tìm thấy bài tập'));
    }

    if (_showHistory) {
      return _buildHistoryView();
    }

    return _buildSubmissionView();
  }

  Widget _buildSubmissionView() {
    final assignment = _assignment!;
    final latest = _latestSubmission;
    final subType = assignment.submissionType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assignment header
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (assignment.description != null) ...[
                  const SizedBox(height: 8),
                  Text(HtmlHelper.cleanHtml(assignment.description!)),
                ],
                const SizedBox(height: 12),

                // Meta info
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (assignment.maxScore != null)
                      _buildMetaChip(
                        Icons.stars,
                        'Tối đa: ${assignment.maxScore} điểm',
                      ),
                    if (assignment.dueAt != null)
                      _buildMetaChip(
                        Icons.schedule,
                        'Hạn: ${DateTimeHelper.formatSmart(assignment.dueAt!)}',
                        color: _isOverdue(assignment.dueAt!)
                            ? AppTheme.errorColor
                            : null,
                      ),
                    _buildMetaChip(
                      Icons.upload_file,
                      _getSubmissionTypeLabel(subType),
                    ),
                    _buildGradingModeChip(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rubric criteria (shown before submission)
          if (assignment.criteria != null &&
              assignment.criteria!.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tiêu chí chấm điểm',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...assignment.criteria!.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${c.maxPoints}đ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (c.description != null)
                                  Text(
                                    c.description!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Latest submission result (if exists and is graded or late-graded)
          if (latest != null &&
              (latest.status == SubmissionStatus.graded ||
                  latest.status == SubmissionStatus.lateGraded)) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.successColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasMentorReviewed(latest)
                            ? Icons.verified_outlined
                            : _isAiAutoConfirmed(latest)
                            ? Icons.smart_toy_outlined
                            : latest.isAiGraded == true
                            ? Icons.smart_toy_outlined
                            : Icons.assignment_turned_in,
                        color: _hasMentorReviewed(latest)
                            ? AppTheme.successColor
                            : (latest.isAiGraded == true ||
                                  _isAiAutoConfirmed(latest))
                            ? Colors.deepPurple
                            : AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hasMentorReviewed(latest)
                            ? 'Kết quả Mentor chấm'
                            : _isAiAutoConfirmed(latest)
                            ? 'Kết quả AI chấm tự động'
                            : latest.isAiGraded == true
                            ? 'Đã được AI chấm'
                            : 'Kết quả chấm gần nhất',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Score
                  Row(
                    children: [
                      Text(
                        NumberFormatter.formatScore(latest.score),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: (latest.isPassed ?? false)
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      Text(
                        ' / ${NumberFormatter.formatScore(assignment.maxScore?.toDouble())}',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      if (latest.isLate == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nộp muộn',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Status
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(latest.status),
                        size: 16,
                        color: _getStatusColor(latest.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(latest.status),
                        style: TextStyle(
                          color: _getStatusColor(latest.status),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Grading breakdown
                  if (latest.criteriaScores != null &&
                      latest.criteriaScores!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...latest.criteriaScores!.map(
                      (cs) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              cs.passed == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: cs.passed == true
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cs.criteriaName ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${cs.score ?? 0}/${cs.maxPoints ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Feedback
                  if (latest.feedback != null &&
                      latest.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSubmissionFeedbackLabel(latest),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest.feedback!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  // Review source + time
                  if (_getSubmissionReviewMeta(latest) != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getSubmissionReviewMeta(latest)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  // Submitted content preview
                  if (latest.submissionText != null ||
                      latest.linkUrl != null ||
                      latest.fileMediaUrl != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Nội dung đã nộp',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    if (latest.submissionText != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latest.submissionText!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (latest.linkUrl != null) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _openUrl(latest.linkUrl!),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                latest.linkUrl!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (latest.fileMediaUrl != null) ...[
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _openUrl(latest.fileMediaUrl!),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attachment,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'File đính kèm — Nhấn để mở',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── AI Grading Result ────────────────────────────────────
          if (latest != null) _buildAiGradingSection(latest),

          // Pending submission blockers
          if (_isPendingSubmission)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAiGrading
                        ? Icons.smart_toy_outlined
                        : Icons.info_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAiGrading
                          ? 'AI đang xử lý bài nộp của bạn. Bạn không thể nộp lại lúc này.'
                          : 'Bài của bạn đang chờ Mentor chấm. Bạn không thể nộp lại lúc này.',
                      style: const TextStyle(color: Colors.amber, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (_isAiPendingSubmission)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latest?.isPassed == true
                          ? 'AI đã chấm xong bài này và đây là kết quả hiện tại của bạn. Nếu chưa đồng ý, bạn có thể yêu cầu Mentor chấm tay.'
                          : 'AI đã chấm xong lần nộp này. Bạn có thể nộp lại bài mới để cải thiện kết quả, hoặc yêu cầu Mentor chấm tay nếu không đồng ý.',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Submission form (if can submit)
          if (_canSubmit) ...[
            Text(
              'Nộp bài',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Text input
            if (subType == SubmissionType.text ||
                subType == SubmissionType.textAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Nội dung bài làm',
                    hintText: _getSubmissionTypeHint(subType),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Link input
            if (subType == SubmissionType.link ||
                subType == SubmissionType.linkAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: 'Đường dẫn',
                    hintText: _getSubmissionTypeHint(subType),
                    prefixIcon: const Icon(Icons.link),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // File picker
            if (subType == SubmissionType.file ||
                subType == SubmissionType.textAndFile ||
                subType == SubmissionType.linkAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Text(
                          'File đính kèm',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_selectedFile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedFile!.size > 0)
                                    Text(
                                      _formatFileSize(_selectedFile!.size),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _selectedFile = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Chọn file'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                    // Upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đang tải lên: ${(_uploadProgress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isUploading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themeOrangeStart,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting || _isUploading
                    ? CommonLoading.button()
                    : const Text(
                        'Nộp bài',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ] else if (latest?.isPassed == true) ...[
            // Already passed
            _buildSuccessBanner(
              'Bài tập đã hoàn thành!',
              'Bạn đã đạt yêu cầu và không thể nộp thêm.',
            ),
          ],

          const SizedBox(height: 24),

          // Toggle to history
          if (_submissions.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _showHistory = true),
              icon: const Icon(Icons.history),
              label: Text('Xem lịch sử nộp bài (${_submissions.length})'),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Chưa có bài nộp nào'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _showHistory = false),
              child: const Text('Quay lại nộp bài'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toggle back
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextButton.icon(
            onPressed: () => setState(() => _showHistory = false),
            icon: const Icon(Icons.edit_note),
            label: const Text('Quay lại bài nộp mới nhất'),
          ),
        ),

        // Submission timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              final sub = _submissions[index];
              return _buildSubmissionHistoryItem(sub, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionHistoryItem(
    AssignmentSubmissionDetailDto sub,
    int attemptNumber,
  ) {
    final statusColor = _getStatusColor(sub.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$attemptNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Line connector (only if not last)
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderColor: statusColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(sub.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(sub.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (sub.score != null)
                        Text(
                          '${NumberFormatter.formatScore(sub.score)}/${NumberFormatter.formatScore(_assignment?.maxScore?.toDouble())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (sub.isPassed ?? false)
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sub.submittedAt != null
                            ? DateTimeHelper.formatSmart(sub.submittedAt!)
                            : '—',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (sub.isLate == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Muộn',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Review source
                  if (_getSubmissionReviewLabel(sub) != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getSubmissionReviewLabel(sub)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  // Grading criteria
                  if (sub.criteriaScores != null &&
                      sub.criteriaScores!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...sub.criteriaScores!.map(
                      (cs) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              cs.passed == true
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 14,
                              color: cs.passed == true
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                cs.criteriaName ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${cs.score ?? 0}/${cs.maxPoints ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Feedback preview
                  if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 12,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getSubmissionFeedbackLabel(sub),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sub.feedback!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildGradingModeChip() {
    final isAi = _isAiGrading;
    final icon = isAi ? Icons.smart_toy_outlined : Icons.person_outline;
    final label = isAi ? 'AI chấm tự động' : 'Mentor chấm thủ công';
    final color = isAi ? Colors.deepPurple : AppTheme.accentCyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _getSubmissionReviewLabel(AssignmentSubmissionDetailDto sub) {
    if (sub.disputeFlag == true) {
      return 'Đã gửi yêu cầu Mentor xem xét lại';
    }

    final graderName = sub.graderName?.trim();
    if (_hasMentorReviewed(sub)) {
      if (graderName != null && graderName.isNotEmpty) {
        return 'Mentor đã chấm: $graderName';
      }
      return 'Mentor đã chấm';
    }

    if (_isAiAutoConfirmed(sub)) {
      return 'AI chấm tự động (đã xác nhận)';
    }

    if (sub.isAiGraded == true) {
      if (sub.status == SubmissionStatus.aiPending) {
        return 'AI đã chấm, chờ Mentor xác nhận';
      }
      return 'Đã được AI chấm';
    }

    if (graderName != null && graderName.isNotEmpty) {
      return 'Chấm bởi $graderName';
    }

    return null;
  }

  String? _getSubmissionReviewMeta(AssignmentSubmissionDetailDto sub) {
    final label = _getSubmissionReviewLabel(sub);
    if (label == null) return null;

    final timestamp = sub.disputeFlag == true ? sub.disputeAt : sub.gradedAt;
    if (timestamp == null) return label;

    return '$label · ${DateTimeHelper.formatSmart(timestamp)}';
  }

  String _getSubmissionFeedbackLabel(AssignmentSubmissionDetailDto sub) {
    if (_hasMentorReviewed(sub)) return 'Phản hồi từ Mentor';
    if (_isAiAutoConfirmed(sub)) return 'Nhận xét từ AI (tự động)';
    return sub.isAiGraded == true ? 'Nhận xét từ AI' : 'Phản hồi từ giảng viên';
  }

  bool _hasMentorReviewed(AssignmentSubmissionDetailDto sub) {
    final graderName = sub.graderName?.trim();
    return sub.graderId != null ||
        (graderName != null && graderName.isNotEmpty);
  }

  /// True when AI graded AND auto-confirmed (trustAi=true path).
  /// Backend sets: isAiGraded=true, mentorConfirmed=true, gradedBy=null, score=aiScore.
  bool _isAiAutoConfirmed(AssignmentSubmissionDetailDto sub) {
    return sub.isAiGraded == true &&
        sub.mentorConfirmed == true &&
        sub.graderId == null;
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.accentCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AI Grading Section ────────────────────────────────────────────────

  Widget _buildAiGradingSection(AssignmentSubmissionDetailDto submission) {
    // Hide when not AI-graded.
    // Hide when a REAL mentor has overridden (graderId is set by human grader).
    // NOTE: Do NOT use _hasMentorReviewed() here because graderName may be
    // populated by the backend even for AI-only submissions.
    if (submission.isAiGraded != true || submission.graderId != null) {
      return const SizedBox.shrink();
    }

    return Consumer<AiGradingProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: Colors.deepPurple.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.deepPurple,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isAiAutoConfirmed(submission)
                              ? 'Kết quả AI chấm tự động'
                              : 'Đánh giá sơ bộ bằng AI',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                        ),
                      ),
                      if (submission.aiConfidence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(
                              submission.aiConfidence!,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getConfidenceColor(
                                submission.aiConfidence!,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'Tin cậy: ${(submission.aiConfidence! * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getConfidenceColor(
                                submission.aiConfidence!,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (submission.aiScore != null) ...[
                    Row(
                      children: [
                        Text(
                          NumberFormatter.formatScore(submission.aiScore),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          ' / ${_assignment?.maxScore ?? 100}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (submission.criteriaScores != null &&
                      submission.criteriaScores!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    ...submission.criteriaScores!.map(
                      (cs) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              cs.passed == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 16,
                              color: cs.passed == true
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cs.criteriaName ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (cs.feedback != null &&
                                      cs.feedback!.isNotEmpty)
                                    Text(
                                      cs.feedback!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${NumberFormatter.formatScore(cs.score?.toDouble())}/${NumberFormatter.formatScore(cs.maxPoints?.toDouble())}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (submission.aiFeedback != null &&
                      submission.aiFeedback!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 16,
                          color: Colors.deepPurple.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nhận xét từ AI',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      submission.aiFeedback!,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],

                  if (submission.disputeFlag == true) ...[
                    const SizedBox(height: 12),
                    _buildDisputeStatusBanner(submission),
                  ] else if (!_isAiAutoConfirmed(submission)) ...[
                    // Show dispute button only when AI graded but
                    // mentor hasn't confirmed yet (AI pending review).
                    // When auto-confirmed (trustAi), student already passed.
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: provider.isDisputing
                            ? null
                            : () => _showDisputeDialog(submission.id),
                        icon: provider.isDisputing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.gavel_outlined, size: 16),
                        label: Text(
                          provider.isDisputing
                              ? 'Đang gửi...'
                              : 'Yêu cầu Mentor chấm lại',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: BorderSide(
                            color: Colors.deepPurple.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Open a URL with error handling
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ErrorHandler.showWarningSnackBar(context, 'Không thể mở liên kết');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Lỗi khi mở liên kết: $e');
      }
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.5) return Colors.orange;
    return AppTheme.errorColor;
  }

  Widget _buildDisputeStatusBanner(AssignmentSubmissionDetailDto submission) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                color: Colors.teal,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đã gửi yêu cầu Mentor xem xét lại',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (submission.disputeAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Gửi lúc: ${DateTimeHelper.formatSmart(submission.disputeAt!)}',
              style: const TextStyle(color: Colors.teal, fontSize: 11),
            ),
          ],
          if (submission.disputeReason != null &&
              submission.disputeReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Lý do: ${submission.disputeReason!}',
              style: const TextStyle(
                color: Colors.teal,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Mentor sẽ xem xét và chấm lại bài của bạn.',
            style: TextStyle(color: Colors.teal, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(int submissionId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu Mentor chấm lại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nếu bạn không đồng ý với kết quả AI, bạn có thể yêu cầu Mentor trực tiếp chấm lại bài.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Lý do (không bắt buộc)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<AiGradingProvider>();
              final success = await provider.disputeAiGrade(
                submissionId,
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : null,
              );
              if (mounted) {
                if (success) {
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Đã gửi yêu cầu cho Mentor!',
                  );
                  // Refresh submission state so disputeFlag/disputeAt reflect immediately.
                  await _loadData();
                } else {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    'Không thể gửi yêu cầu. Vui lòng thử lại.',
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime dueAt) {
    return DateTime.now().isAfter(dueAt);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
