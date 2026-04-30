import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/job_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/animated_success_overlay.dart';

import '../../widgets/common_loading.dart';
import 'my_applications_page.dart';

class JobApplySheet extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  final bool isShortTerm;

  const JobApplySheet({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.isShortTerm,
  });

  @override
  State<JobApplySheet> createState() => _JobApplySheetState();
}

class _JobApplySheetState extends State<JobApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _portfolioController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _isSuccess ? _buildSuccessState() : _buildFormState(),
        ),
      ),
    );
  }

  // ==================== SUCCESS STATE ====================

  Widget _buildSuccessState() {
    return AnimatedSuccessOverlay(
      title: 'Ứng tuyển thành công! 🎉',
      subtitle: widget.jobTitle,
      primaryButtonText: 'Xem đơn',
      onPrimaryAction: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MyApplicationsPage()));
      },
      onClose: () => Navigator.of(context).pop(),
    );
  }

  // ==================== FORM STATE ====================

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Ứng Tuyển',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.jobTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Cover letter with counter
            TextFormField(
              controller: _coverLetterController,
              maxLines: 5,
              maxLength: widget.isShortTerm ? 5000 : 1000,
              decoration: InputDecoration(
                labelText: 'Thư giới thiệu',
                hintText: 'Giới thiệu bản thân và lý do muốn ứng tuyển...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
            ),

            // Short-term specific fields
            if (widget.isShortTerm) ...[
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giá đề xuất (VND)',
                  hintText: 'Nhập số tiền...',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final price = double.tryParse(v);
                    if (price == null || price <= 0) {
                      return 'Giá phải lớn hơn 0';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Thời gian hoàn thành',
                  hintText: 'VD: 3 ngày, 1 tuần...',
                  prefixIcon: const Icon(Icons.schedule_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _portfolioController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Link sản phẩm phụ (không bắt buộc)',
                  hintText:
                      'VD: link Github, Behance, Drive (cách nhau bởi dấu phẩy)',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themeBlueStart,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? CommonLoading.small(color: Colors.white)
                    : const Text(
                        'Gửi Đơn Ứng Tuyển',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<JobProvider>();
    final navigator = Navigator.of(context);
    bool success;

    if (widget.isShortTerm) {
      success = await provider.applyToShortTermJob(
        widget.jobId,
        coverLetter: _coverLetterController.text.isNotEmpty
            ? _coverLetterController.text
            : null,
        proposedPrice: _priceController.text.isNotEmpty
            ? double.tryParse(_priceController.text)
            : null,
        proposedDuration: _durationController.text.isNotEmpty
            ? _durationController.text
            : null,
        portfolio: _portfolioController.text.trim().isNotEmpty
            ? _portfolioController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : null,
      );
    } else {
      success = await provider.applyToJob(
        widget.jobId,
        coverLetter: _coverLetterController.text.isNotEmpty
            ? _coverLetterController.text
            : null,
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      navigator.pop();
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Ứng tuyển thất bại',
      );
    }
  }
}
