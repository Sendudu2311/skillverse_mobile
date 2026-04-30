import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import 'cancel_refund_sheet.dart';

/// BottomSheet for managing active premium subscription
class SubscriptionManagementSheet extends StatefulWidget {
  final VoidCallback onRefresh;

  const SubscriptionManagementSheet({super.key, required this.onRefresh});

  @override
  State<SubscriptionManagementSheet> createState() =>
      _SubscriptionManagementSheetState();
}

class _SubscriptionManagementSheetState
    extends State<SubscriptionManagementSheet> {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  Future<void> _toggleAutoRenewal(PremiumProvider provider) async {
    final sub = provider.currentSubscription;
    if (sub == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? result;
      if (sub.autoRenew == true) {
        result = await provider.cancelAutoRenewal();
      } else {
        result = await provider.enableAutoRenewal();
      }

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        setState(() => _successMessage = result!['message'] as String?);
        widget.onRefresh();
      } else {
        setState(
          () => _error = result?['message'] as String? ?? 'Có lỗi xảy ra',
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCancelRefundSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelRefundSheet(
        onSuccess: () {
          widget.onRefresh();
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PremiumProvider>(
      builder: (context, provider, child) {
        final sub = provider.currentSubscription;
        if (sub == null) return const SizedBox.shrink();

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCardBackground
                : AppTheme.lightCardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBorderColor
                            : AppTheme.lightBorderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.manage_accounts,
                        color: AppTheme.accentGold,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Quản lý Subscription',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subscription details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBackgroundSecondary
                          : AppTheme.lightBackgroundSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _detailRow('Gói:', sub.plan.displayName, isDark),
                        _detailRow(
                          'Bắt đầu:',
                          _formatDate(sub.startDate),
                          isDark,
                        ),
                        _detailRow(
                          'Kết thúc:',
                          _formatDate(sub.endDate),
                          isDark,
                        ),
                        _detailRow(
                          'Còn lại:',
                          '${sub.daysRemaining ?? 0} ngày',
                          isDark,
                        ),
                        _detailRow(
                          'Tự động gia hạn:',
                          sub.autoRenew == true ? '✅ Có' : '❌ Không',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Error message
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Actions
                  // Auto-renewal toggle
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _toggleAutoRenewal(provider),
                      icon: Icon(
                        sub.autoRenew == true
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        size: 22,
                      ),
                      label: Text(
                        sub.autoRenew == true
                            ? 'Tắt tự động gia hạn'
                            : 'Bật tự động gia hạn',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentCyan,
                        side: BorderSide(
                          color: AppTheme.accentCyan.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _openCancelRefundSheet,
                      icon: const Icon(Icons.cancel, size: 20),
                      label: const Text('Hủy gói & Hoàn tiền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: CommonLoading.center(),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
