import 'package:flutter/material.dart';

import '../../../data/models/booking_dispute_models.dart';
import '../../../data/services/booking_dispute_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';

/// Bottom sheet that lets a Learner open a new dispute for a booking.
class OpenDisputeSheet extends StatefulWidget {
  final int bookingId;
  final void Function(BookingDisputeDto dispute) onSuccess;

  const OpenDisputeSheet({
    super.key,
    required this.bookingId,
    required this.onSuccess,
  });

  @override
  State<OpenDisputeSheet> createState() => _OpenDisputeSheetState();
}

class _OpenDisputeSheetState extends State<OpenDisputeSheet> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _service = BookingDisputeService();

  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      final dispute = await _service.openDispute(
        bookingId: widget.bookingId,
        reason: _reasonController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess(dispute);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBackgroundSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                const Icon(Icons.gavel, color: AppTheme.warningColor),
                const SizedBox(width: 10),
                Text(
                  'Mở khiếu nại',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mô tả rõ lý do khiếu nại để Admin có thể xem xét.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _reasonController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Lý do khiếu nại *',
                hintText: 'Mô tả vấn đề của bạn...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập lý do khiếu nại.';
                }
                if (v.trim().length < 10) {
                  return 'Lý do phải có ít nhất 10 ký tự.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? CommonLoading.button()
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Đang gửi...' : 'Gửi khiếu nại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
