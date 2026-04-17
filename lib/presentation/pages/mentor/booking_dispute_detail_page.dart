import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/booking_dispute_models.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/booking_dispute_provider.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import 'submit_evidence_sheet.dart';

class BookingDisputeDetailPage extends StatefulWidget {
  final int disputeId;

  const BookingDisputeDetailPage({super.key, required this.disputeId});

  @override
  State<BookingDisputeDetailPage> createState() =>
      _BookingDisputeDetailPageState();
}

class _BookingDisputeDetailPageState extends State<BookingDisputeDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((ts) {
      context.read<BookingDisputeProvider>().loadDispute(widget.disputeId);
    });
  }

  Future<void> _refresh() =>
      context.read<BookingDisputeProvider>().loadDispute(widget.disputeId);

  void _showSubmitEvidenceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ChangeNotifierProvider.value(
        value: context.read<BookingDisputeProvider>(),
        child: const SubmitEvidenceSheet(),
      ),
    );
  }

  void _showReplyDialog(BuildContext pageCtx, int evidenceId) {
    final controller = TextEditingController();
    showDialog(
      context: pageCtx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Phản hồi bằng chứng'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập phản hồi của bạn...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          Consumer<BookingDisputeProvider>(
            builder: (consumerCtx, provider, child) => ElevatedButton(
              onPressed: provider.isBusy
                  ? null
                  : () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) {
                        ErrorHandler.showErrorSnackBar(
                          pageCtx,
                          'Vui lòng nhập nội dung phản hồi.',
                        );
                        return;
                      }
                      try {
                        await provider.respondToEvidence(
                          evidenceId: evidenceId,
                          content: text,
                        );
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      } catch (e) {
                        if (pageCtx.mounted) {
                          ErrorHandler.showErrorSnackBar(
                            pageCtx,
                            ErrorHandler.getErrorMessage(e),
                          );
                        }
                      }
                    },
              child: provider.isBusy
                  ? CommonLoading.button()
                  : const Text('Gửi'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const SkillVerseAppBar(title: 'Chi tiết khiếu nại'),
      body: Consumer<BookingDisputeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return CommonLoading.center();
          }

          if (provider.errorMessage != null && provider.dispute == null) {
            return ErrorStateWidget(
              message: provider.errorMessage!,
              onRetry: _refresh,
            );
          }

          if (provider.dispute == null) {
            return const EmptyStateWidget(
              icon: Icons.gavel,
              title: 'Không tìm thấy khiếu nại',
              subtitle: 'Khiếu nại này không tồn tại hoặc đã bị xóa.',
              iconGradient: AppTheme.blueGradient,
            );
          }

          final dispute = provider.dispute!;
          final currentUserId = context.read<AuthProvider>().user?.id;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(dispute, isDark),
                if (dispute.resolution != null) ...[
                  const SizedBox(height: 16),
                  _buildResolutionCard(dispute, isDark),
                ],
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Bằng chứng (${provider.evidences.length})',
                  icon: Icons.folder_open_outlined,
                ),
                const SizedBox(height: 12),
                if (provider.evidences.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: 'Chưa có bằng chứng',
                    subtitle: 'Gửi bằng chứng để hỗ trợ khiếu nại của bạn.',
                    iconGradient: AppTheme.blueGradient,
                  )
                else
                  ...provider.evidences.map(
                    (e) => _buildEvidenceCard(
                      context,
                      e,
                      isDark,
                      currentUserId,
                      provider.canSubmitEvidence,
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<BookingDisputeProvider>(
        builder: (fabCtx, provider, child) {
          if (!provider.canSubmitEvidence || provider.dispute == null) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _showSubmitEvidenceSheet,
            icon: const Icon(Icons.add),
            label: const Text('Gửi bằng chứng'),
            backgroundColor: AppTheme.primaryBlueDark,
          );
        },
      ),
    );
  }

  // ─── Header Card ──────────────────────────────────────────────────────────

  Widget _buildHeaderCard(BookingDisputeDto dispute, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.custom(
                label: dispute.status.displayName,
                color: _statusColor(dispute.status),
              ),
              const Spacer(),
              Text(
                DateTimeHelper.formatSmart(dispute.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lý do khiếu nại',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            dispute.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mã booking: #${dispute.bookingId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Resolution Card ──────────────────────────────────────────────────────

  Widget _buildResolutionCard(BookingDisputeDto dispute, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, size: 18, color: AppTheme.successColor),
              const SizedBox(width: 8),
              Text(
                'Kết quả giải quyết',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (dispute.resolution != null)
            _buildResolutionRow(
              'Loại giải quyết',
              _resolutionLabel(dispute.resolution!),
            ),
          if (dispute.refundAmount != null && dispute.refundAmount! > 0)
            _buildResolutionRow(
              'Hoàn tiền',
              NumberFormatter.formatCurrency(dispute.refundAmount!),
            ),
          if (dispute.releasedAmount != null && dispute.releasedAmount! > 0)
            _buildResolutionRow(
              'Giải phóng cho Mentor',
              NumberFormatter.formatCurrency(dispute.releasedAmount!),
            ),
          if (dispute.resolutionNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              dispute.resolutionNotes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── Evidence Card ────────────────────────────────────────────────────────

  Widget _buildEvidenceCard(
    BuildContext context,
    BookingDisputeEvidenceDto evidence,
    bool isDark,
    int? currentUserId,
    bool canReply,
  ) {
    final isOwn = evidence.submittedBy == currentUserId;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _evidenceIcon(evidence.evidenceType),
                size: 16,
                color: AppTheme.primaryBlueDark,
              ),
              const SizedBox(width: 6),
              Text(
                _evidenceTypeLabel(evidence.evidenceType),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (evidence.isOfficial) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified,
                  size: 14,
                  color: AppTheme.accentCyan,
                ),
              ],
              const Spacer(),
              if (evidence.reviewStatus != null)
                StatusBadge.custom(
                  label: _reviewStatusLabel(evidence.reviewStatus!),
                  color: _reviewStatusColor(evidence.reviewStatus!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (evidence.content != null)
            Text(
              evidence.content!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
          if (evidence.fileUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(evidence.fileUrl!);
                  if (uri == null ||
                      !await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      )) {
                    if (context.mounted) {
                      ErrorHandler.showErrorSnackBar(
                        context,
                        'Không thể mở file đính kèm.',
                      );
                    }
                  }
                },
                child: Text(
                  evidence.fileName ?? evidence.fileUrl!,
                  style: const TextStyle(
                    color: AppTheme.primaryBlueDark,
                    decoration: TextDecoration.underline,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          if (evidence.description != null) ...[
            const SizedBox(height: 4),
            Text(
              evidence.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwn ? 'Bạn' : 'Đối phương',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isOwn
                      ? AppTheme.primaryBlueDark
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                DateTimeHelper.formatSmart(evidence.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          if (evidence.responses.isNotEmpty) ...[
            const Divider(height: 16),
            ...evidence.responses.map((r) => _buildResponseTile(r, isDark)),
          ],
          if (canReply && !isOwn) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(context, evidence.id),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Phản hồi'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlueDark,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseTile(BookingDisputeResponseDto r, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: AppTheme.lightTextSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.respondedByName.isNotEmpty
                      ? r.respondedByName
                      : 'Người dùng',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: r.isAdminResponse
                        ? AppTheme.warningColor
                        : AppTheme.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateTimeHelper.formatSmart(r.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Color _statusColor(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return AppTheme.warningColor;
      case DisputeStatus.underInvestigation:
        return AppTheme.primaryBlueDark;
      case DisputeStatus.awaitingResponse:
        return Colors.orange;
      case DisputeStatus.resolved:
        return AppTheme.successColor;
      case DisputeStatus.dismissed:
        return AppTheme.lightTextSecondary;
      case DisputeStatus.escalated:
        return AppTheme.errorColor;
      case DisputeStatus.unknown:
        return AppTheme.lightTextSecondary;
    }
  }

  String _resolutionLabel(DisputeResolution r) {
    switch (r) {
      case DisputeResolution.fullRefund:
        return 'Hoàn tiền toàn bộ';
      case DisputeResolution.fullRelease:
        return 'Giải phóng toàn bộ';
      case DisputeResolution.partialRefund:
        return 'Hoàn tiền một phần';
      case DisputeResolution.partialRelease:
        return 'Giải phóng một phần';
    }
  }

  IconData _evidenceIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.text:
        return Icons.text_snippet_outlined;
      case EvidenceType.file:
        return Icons.attach_file;
      case EvidenceType.link:
        return Icons.link;
      case EvidenceType.screenshot:
        return Icons.screenshot_outlined;
      case EvidenceType.chatLog:
        return Icons.chat_outlined;
      case EvidenceType.image:
        return Icons.image_outlined;
    }
  }

  String _evidenceTypeLabel(EvidenceType type) {
    switch (type) {
      case EvidenceType.text:
        return 'Văn bản';
      case EvidenceType.file:
        return 'Tệp tin';
      case EvidenceType.link:
        return 'Liên kết';
      case EvidenceType.screenshot:
        return 'Ảnh chụp màn hình';
      case EvidenceType.chatLog:
        return 'Lịch sử chat';
      case EvidenceType.image:
        return 'Hình ảnh';
    }
  }

  String _reviewStatusLabel(EvidenceReviewStatus s) {
    switch (s) {
      case EvidenceReviewStatus.pending:
        return 'Chờ duyệt';
      case EvidenceReviewStatus.underReview:
        return 'Đang xem xét';
      case EvidenceReviewStatus.accepted:
        return 'Chấp nhận';
      case EvidenceReviewStatus.rejected:
        return 'Từ chối';
    }
  }

  Color _reviewStatusColor(EvidenceReviewStatus s) {
    switch (s) {
      case EvidenceReviewStatus.pending:
        return AppTheme.warningColor;
      case EvidenceReviewStatus.underReview:
        return AppTheme.primaryBlueDark;
      case EvidenceReviewStatus.accepted:
        return AppTheme.successColor;
      case EvidenceReviewStatus.rejected:
        return AppTheme.errorColor;
    }
  }
}
