import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/final_verification_provider.dart';
import '../../../data/models/final_verification_models.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/error_handler.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/animated_success_overlay.dart';
import '../../widgets/ai_generation_loading_view.dart';
import '../../widgets/error_dialog.dart';

class FinalVerificationPage extends StatefulWidget {
  final int journeyId;

  const FinalVerificationPage({super.key, required this.journeyId});

  @override
  State<FinalVerificationPage> createState() => _FinalVerificationPageState();
}

class _FinalVerificationPageState extends State<FinalVerificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinalVerificationProvider>().load(widget.journeyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const SkillVerseAppBar(
        title: 'Xác minh hoàn thành',
        icon: Icons.verified_outlined,
        useGradientTitle: true,
      ),
      body: SafeArea(
        child: Consumer<FinalVerificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) return const CommonLoading();

            if (provider.isBusy) {
              return const AiGenerationLoadingView(
                speech: 'Đang xử lý yêu cầu...',
                title: 'Đang gửi',
                description: 'Vui lòng đợi trong giây lát',
                etaText: '',
                steps: [('Gửi dữ liệu', Icons.upload_outlined)],
              );
            }

            if (provider.error != null && provider.gate == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              );
            }

            final gate = provider.gate;
            if (gate == null) {
              return const EmptyStateWidget(
                icon: Icons.verified_outlined,
                title: 'Chưa có dữ liệu',
                subtitle: 'Không thể tải thông tin xác minh. Thử lại sau.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.load(widget.journeyId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGateStatusCard(context, gate, isDark),
                    const SizedBox(height: 16),
                    _buildOutputAssessmentSection(
                        context, provider, gate, isDark),
                    if (provider.history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildHistorySection(
                          context, provider.history, isDark),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Gate status card ────────────────────────────────────────────────────

  Widget _buildGateStatusCard(
    BuildContext context,
    JourneyCompletionGateResponse gate,
    bool isDark,
  ) {
    final statusStr = switch (gate.finalGateStatus) {
      FinalGateStatus.notRequired => 'NOT_REQUIRED',
      FinalGateStatus.passed => 'COMPLETED_VERIFIED',
      FinalGateStatus.blocked => 'AWAITING_VERIFICATION',
    };

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trạng thái xác minh',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                ),
              ),
              StatusBadge(status: statusStr),
            ],
          ),
          if (gate.finalGateStatus == FinalGateStatus.notRequired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.infoColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lộ trình này đang ở chế độ Tự học (Self-Study). Bạn không bắt buộc phải xác minh để hoàn thành. Tuy nhiên, nếu bạn muốn nhận Chứng chỉ kỹ năng (Verified Skills) cho Portfolio, bạn cần thuê Mentor phỏng vấn 1 buổi duy nhất để đánh giá tổng kết.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/mentors?action=journey_mentoring&journeyId=${widget.journeyId}',
                  );
                },
                icon: const Icon(Icons.person_search),
                label: const Text('Thuê Mentor phỏng vấn (1 buổi)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            if (gate.blockingReasons != null &&
                gate.blockingReasons!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...gate.blockingReasons!.map(
                (reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_outlined,
                          size: 16, color: AppTheme.warningColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (gate.finalGateStatus == FinalGateStatus.passed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Hành trình đã được xác minh hoàn thành!',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Output assessment ───────────────────────────────────────────────────

  Widget _buildOutputAssessmentSection(
    BuildContext context,
    FinalVerificationProvider provider,
    JourneyCompletionGateResponse gate,
    bool isDark,
  ) {
    if (gate.journeyOutputVerificationRequired != true) {
      return const SizedBox.shrink();
    }

    final assessment = provider.outputAssessment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Sản phẩm nộp', icon: Icons.upload_file_outlined),
        const SizedBox(height: 8),
        if (assessment == null)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const EmptyStateWidget(
                  icon: Icons.upload_file_outlined,
                  title: 'Chưa nộp sản phẩm',
                  subtitle:
                      'Nộp sản phẩm cuối khoá để mentor xác nhận hoàn thành hành trình',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSubmitDialog(context, provider),
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Nộp sản phẩm'),
                  ),
                ),
              ],
            ),
          )
        else
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sản phẩm của bạn',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                      ),
                    ),
                    StatusBadge(
                      status: switch (assessment.assessmentStatus) {
                        AssessmentStatus.approved => 'COMPLETED_VERIFIED',
                        AssessmentStatus.rejected => 'REJECTED',
                        _ => 'PENDING',
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if ((assessment.submissionText ?? '').isNotEmpty)
                  Text(
                    assessment.submissionText!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                if (assessment.evidenceUrl != null &&
                    assessment.evidenceUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openLink(assessment.evidenceUrl!),
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
                            assessment.evidenceUrl!,
                            maxLines: 1,
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
                if (assessment.attachmentUrl != null &&
                    assessment.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _openLink(assessment.attachmentUrl!),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.attach_file,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Flexible(
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
                if (assessment.submittedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Nộp ${DateTimeHelper.formatRelativeTime(assessment.submittedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
                if (assessment.assessmentStatus == AssessmentStatus.rejected &&
                    assessment.feedback != null &&
                    assessment.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.feedback_outlined,
                                size: 14, color: AppTheme.errorColor),
                            const SizedBox(width: 6),
                            Text(
                              'Phản hồi từ mentor',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildMarkdown(assessment.feedback!, isDark),
                      ],
                    ),
                  ),
                ],
                if (assessment.assessmentStatus != AssessmentStatus.approved &&
                    gate.finalGateStatus != FinalGateStatus.passed) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSubmitDialog(context, provider),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Cập nhật sản phẩm'),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ─── History ─────────────────────────────────────────────────────────────

  Widget _buildHistorySection(
    BuildContext context,
    List<VerificationEvidenceReportResponse> history,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Lịch sử xác minh', icon: Icons.history_outlined),
        const SizedBox(height: 8),
        ...history.map(
          (report) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lần ${report.attemptNumber ?? '-'}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                        ),
                      ),
                      StatusBadge(
                        status: switch (report.gateDecision) {
                          GateDecision.pass => 'COMPLETED_VERIFIED',
                          GateDecision.fail => 'REJECTED',
                          _ => 'PENDING',
                        },
                      ),
                    ],
                  ),
                  if (report.summaryReport != null) ...[
                    const SizedBox(height: 8),
                    _buildMarkdown(report.summaryReport!, isDark),
                  ],
                  if (report.meetingJitsiLink != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(report.meetingJitsiLink!);
                        if (uri != null) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.video_call, size: 16),
                      label: const Text('Xem phòng họp'),
                    ),
                  ],
                  if (report.submittedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateTimeHelper.formatRelativeTime(report.submittedAt!),
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
            ),
          ),
        ),
      ],
    );
  }

  // ─── Submit dialog ────────────────────────────────────────────────────────

  void _showSubmitDialog(
      BuildContext context, FinalVerificationProvider provider) {
    final textCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    PlatformFile? pickedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Consumer<FinalVerificationProvider>(
              builder: (_, p, __) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nộp sản phẩm',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả sản phẩm *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Link minh chứng (tuỳ chọn)',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSheetAttachmentZone(
                    ctx,
                    p,
                    onPick: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const [
                          'pdf',
                          'docx',
                          'jpg',
                          'jpeg',
                          'png',
                          'gif',
                          'webp',
                        ],
                        withData: false,
                      );
                      if (res == null || res.files.isEmpty) return;
                      final file = res.files.first;
                      if (file.size > 10 * 1024 * 1024) {
                        if (!mounted) return;
                        ErrorHandler.showWarningSnackBar(
                          ctx,
                          'File vượt quá 10MB',
                        );
                        return;
                      }
                      setSheetState(() => pickedFile = file);
                    },
                    onRemove: () => setSheetState(() => pickedFile = null),
                    pickedFile: pickedFile,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: p.isUploading || p.isBusy
                          ? null
                          : () async {
                              if (textCtrl.text.trim().isEmpty) return;
                              final stateContext = this.context;

                              // Step 1: upload if a new file was picked
                              String? attachmentUrl;
                              if (pickedFile != null &&
                                  pickedFile!.path != null) {
                                final actorId = stateContext
                                    .read<AuthProvider>()
                                    .user
                                    ?.id;
                                if (actorId == null) {
                                  ErrorHandler.showErrorSnackBar(
                                    stateContext,
                                    'Bạn cần đăng nhập lại.',
                                  );
                                  return;
                                }
                                attachmentUrl = await provider.uploadAttachment(
                                  filePath: pickedFile!.path!,
                                  fileName: pickedFile!.name,
                                  actorId: actorId,
                                );
                                if (attachmentUrl == null) {
                                  if (!mounted) return;
                                  ErrorHandler.showErrorSnackBar(
                                    stateContext,
                                    provider.error ?? 'Tải file thất bại',
                                  );
                                  return;
                                }
                              }

                              if (!mounted) return;
                              Navigator.pop(ctx);
                              final ok = await provider.submitOutput(
                                widget.journeyId,
                                SubmitJourneyOutputRequest(
                                  submissionText: textCtrl.text.trim(),
                                  evidenceUrl: urlCtrl.text.trim().isEmpty
                                      ? null
                                      : urlCtrl.text.trim(),
                                  attachmentUrl: attachmentUrl,
                                ),
                              );
                              if (!mounted) return;
                              if (ok) {
                                await AnimatedSuccessOverlay.show(
                                  context: stateContext,
                                  title: 'Đã gửi thành công!',
                                  subtitle:
                                      'Mentor sẽ xem xét sản phẩm của bạn sớm.',
                                );
                              } else if (provider.error != null) {
                                ErrorDialog.show(
                                  context: stateContext,
                                  title: 'Lỗi',
                                  message: provider.error!,
                                );
                              }
                            },
                      child: p.isUploading
                          ? Text(
                              'Đang tải file ${(p.uploadProgress * 100).toStringAsFixed(0)}%',
                            )
                          : const Text('Gửi'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSheetAttachmentZone(
    BuildContext ctx,
    FinalVerificationProvider p, {
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required PlatformFile? pickedFile,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    if (pickedFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBlue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pickedFile.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              '${(pickedFile.size / 1024 / 1024).toStringAsFixed(1)} MB',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            IconButton(
              onPressed: p.isUploading ? null : onRemove,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: p.isUploading ? null : onPick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_outlined, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Đính kèm file (PDF/DOCX/Ảnh, max 10MB)',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildMarkdown(String data, bool isDark) {
    final baseColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    return MarkdownBody(
      data: data,
      onTapLink: (_, href, _) {
        if (href != null && href.isNotEmpty) _openLink(href);
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
}
