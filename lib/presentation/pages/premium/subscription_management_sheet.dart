import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/number_formatter.dart';

/// BottomSheet for managing active premium subscription
class SubscriptionManagementSheet extends StatefulWidget {
  final VoidCallback onRefresh;

  const SubscriptionManagementSheet({super.key, required this.onRefresh});

  @override
  State<SubscriptionManagementSheet> createState() => _SubscriptionManagementSheetState();
}

class _SubscriptionManagementSheetState extends State<SubscriptionManagementSheet> {
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
        setState(() => _error = result?['message'] as String? ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancelWithRefund(PremiumProvider provider) async {
    // First check refund eligibility
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final eligibility = await provider.checkRefundEligibility();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (eligibility == null) {
      setState(() => _error = provider.errorMessage ?? 'Không thể kiểm tra hoàn tiền');
      return;
    }

    final refundPercent = (eligibility['refundPercentage'] as num?)?.toDouble() ?? 0;
    final refundAmount = (eligibility['refundAmount'] as num?)?.toDouble() ?? 0;
    final daysUsed = (eligibility['daysUsed'] as num?)?.toInt() ?? 0;
    final eligible = eligibility['eligible'] as bool? ?? false;

    if (!mounted) return;

    // Show confirm dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final reasonController = TextEditingController();

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: AppTheme.themeOrangeStart),
              const SizedBox(width: 8),
              const Expanded(child: Text('Hủy gói Premium', style: TextStyle(fontSize: 17))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Refund info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: eligible
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _eligibilityRow('Đã dùng:', '$daysUsed ngày', isDark),
                      _eligibilityRow('% hoàn:', '${refundPercent.toStringAsFixed(0)}%', isDark),
                      _eligibilityRow(
                        'Số tiền hoàn:',
                        NumberFormatter.formatCurrency(refundAmount, currency: 'đ'),
                        isDark,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eligible
                      ? '• ≤24h: hoàn 100%\n• 1-3 ngày: hoàn 50%\n• >3 ngày: chỉ hủy tự động gia hạn'
                      : 'Đã quá thời hạn hoàn tiền. Gói sẽ tiếp tục đến ngày hết hạn.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Lý do hủy (tùy chọn)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Giữ lại'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        );
      },
    );

    if (reason == null || !mounted) return;

    setState(() => _isLoading = true);
    final result = await provider.cancelSubscriptionWithRefund(
      reason: reason.isNotEmpty ? reason : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      final refunded = (result['refundAmount'] as num?)?.toDouble() ?? 0;
      setState(() => _successMessage = refunded > 0
          ? 'Đã hoàn ${NumberFormatter.formatCurrency(refunded, currency: 'đ')} vào ví!'
          : 'Đã hủy tự động gia hạn.');
      widget.onRefresh();
    } else {
      setState(() => _error = result?['message'] as String? ?? provider.errorMessage ?? 'Có lỗi');
    }
  }

  Widget _eligibilityRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'monospace',
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
        ],
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Icon(Icons.manage_accounts, color: AppTheme.accentGold, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Quản lý Subscription',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subscription details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Gói:', sub.plan.displayName, isDark),
                      _detailRow('Bắt đầu:', _formatDate(sub.startDate), isDark),
                      _detailRow('Kết thúc:', _formatDate(sub.endDate), isDark),
                      _detailRow('Còn lại:', '${sub.daysRemaining ?? 0} ngày', isDark),
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
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_successMessage!, style: TextStyle(color: AppTheme.successColor, fontSize: 13))),
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
                        Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                      ],
                    ),
                  ),

                // Actions
                // Auto-renewal toggle
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _toggleAutoRenewal(provider),
                    icon: Icon(
                      sub.autoRenew == true ? Icons.toggle_on : Icons.toggle_off,
                      size: 22,
                    ),
                    label: Text(sub.autoRenew == true ? 'Tắt tự động gia hạn' : 'Bật tự động gia hạn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentCyan,
                      side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Cancel with refund
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _handleCancelWithRefund(provider),
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text('Hủy gói & Hoàn tiền'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
