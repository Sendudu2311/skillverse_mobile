import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_handler.dart';
import '../../providers/job_provider.dart';

/// Bottom sheet for learner to open a dispute on a short-term job application.
/// Maps to prototype: JobLabPage.tsx:3219–3439 (showDisputeModal)
class DisputeSheet extends StatefulWidget {
  final int jobId;
  final int applicationId;
  final String? jobTitle;

  const DisputeSheet({
    super.key,
    required this.jobId,
    required this.applicationId,
    this.jobTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int jobId,
    required int applicationId,
    String? jobTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DisputeSheet(
        jobId: jobId,
        applicationId: applicationId,
        jobTitle: jobTitle,
      ),
    );
  }

  @override
  State<DisputeSheet> createState() => _DisputeSheetState();
}

class _DisputeSheetState extends State<DisputeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  String _selectedType = 'WORKER_PROTECTION';
  bool _submitting = false;

  static const _typeLabels = {
    'WORKER_PROTECTION': 'Bảo vệ quyền lợi',
    'POOR_QUALITY': 'Chất lượng không đạt',
    'SCOPE_CHANGE': 'Thay đổi phạm vi công việc',
    'OTHER': 'Lý do khác',
  };

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final provider = context.read<JobProvider>();
    final success = await provider.openDispute(
      jobId: widget.jobId,
      applicationId: widget.applicationId,
      disputeType: _selectedType,
      reason: _reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      ErrorHandler.showSuccessSnackBar(context, 'Đã gửi khiếu nại thành công');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Gửi khiếu nại thất bại. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: colorScheme.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'Mở khiếu nại',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.jobTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.jobTitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),

          // Warning banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: colorScheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Khiếu nại sẽ được Admin xem xét. Vui lòng cung cấp lý do rõ ràng.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dispute type dropdown
                Text(
                  'Loại khiếu nại *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  items: _typeLabels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),

                // Reason textarea
                Text(
                  'Lý do khiếu nại *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonCtrl,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập lý do khiếu nại';
                    }
                    if (v.trim().length < 20) {
                      return 'Lý do phải có ít nhất 20 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onError,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Đang gửi...' : 'Gửi khiếu nại',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
