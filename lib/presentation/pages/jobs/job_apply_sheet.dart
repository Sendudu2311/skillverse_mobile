import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
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

class _JobApplySheetState extends State<JobApplySheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSuccess = false;

  late AnimationController _successAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _successAnimController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _successAnimController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _successAnimController.dispose();
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: _isSuccess ? _buildSuccessState() : _buildFormState(),
      ),
    );
  }

  // ==================== SUCCESS STATE ====================

  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _successAnimController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 40),

            // Animated checkmark
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.themeGreenStart,
                      AppTheme.themeGreenEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.themeGreenStart.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
            ),

            const SizedBox(height: 20),

            Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  Text(
                    'Ứng tuyển thành công! 🎉',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.jobTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),

                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Đóng'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const MyApplicationsPage(),
                            ));
                          },
                          icon: const Icon(Icons.assignment_outlined, size: 18),
                          label: const Text('Xem đơn'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.themeBlueStart,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                            fontWeight: FontWeight.bold, fontSize: 16),
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
      _successAnimController.forward();
    } else {
      ErrorHandler.showErrorSnackBar(context, provider.errorMessage ?? 'Ứng tuyển thất bại');
    }
  }
}
