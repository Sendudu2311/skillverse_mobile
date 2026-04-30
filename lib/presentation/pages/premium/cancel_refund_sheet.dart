import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/premium_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/number_formatter.dart';

/// Dedicated BottomSheet for cancel/refund flow.
/// Matches web prototype CancelSubscriptionModal with 3-tier refund visualization.
class CancelRefundSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const CancelRefundSheet({super.key, required this.onSuccess});

  @override
  State<CancelRefundSheet> createState() => _CancelRefundSheetState();
}

class _CancelRefundSheetState extends State<CancelRefundSheet> {
  bool _checking = true;
  bool _processing = false;
  String? _error;
  int _refundPercentage = 0;
  double _refundAmount = 0;
  int _daysUsed = 0;
  String _eligibilityMessage = '';

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEligibility());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _isCancellationLimitMessage(String? message) =>
      message != null &&
      (message.contains('1 lần/tháng') ||
          message.contains('hủy gói Premium trong tháng này'));

  Future<void> _checkEligibility() async {
    final provider = context.read<PremiumProvider>();

    setState(() {
      _checking = true;
      _error = null;
    });

    final result = await provider.checkRefundEligibility();
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _checking = false;
        _error =
            provider.errorMessage ?? 'Không thể kiểm tra điều kiện hoàn tiền';
      });
      return;
    }

    final message = result['message'] as String?;
    if (_isCancellationLimitMessage(message)) {
      setState(() {
        _checking = false;
        _error = message;
      });
      return;
    }

    setState(() {
      _checking = false;
      _refundPercentage = (result['refundPercentage'] as num?)?.toInt() ?? 0;
      _refundAmount = (result['refundAmount'] as num?)?.toDouble() ?? 0;
      _daysUsed = (result['daysUsed'] as num?)?.toInt() ?? 0;
      _eligibilityMessage = message ?? '';
    });
  }

  Future<void> _handleCancelWithRefund() async {
    final provider = context.read<PremiumProvider>();
    setState(() {
      _processing = true;
      _error = null;
    });

    final reason = _reasonController.text.trim();
    final result = await provider.cancelSubscriptionWithRefund(
      reason: reason.isNotEmpty ? reason : null,
    );

    if (!mounted) return;
    setState(() => _processing = false);

    if (result != null && result['success'] == true) {
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } else {
      final msg =
          result?['message'] as String? ??
          provider.errorMessage ??
          'Có lỗi xảy ra';
      if (_isCancellationLimitMessage(msg)) {
        setState(() => _error = msg);
      } else {
        setState(() => _error = msg);
      }
    }
  }

  Future<void> _handleCancelAutoRenewal() async {
    final provider = context.read<PremiumProvider>();
    setState(() {
      _processing = true;
      _error = null;
    });

    final result = await provider.cancelAutoRenewal();
    if (!mounted) return;
    setState(() => _processing = false);

    if (result != null && result['success'] == true) {
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(
        () => _error =
            result?['message'] as String? ?? 'Không thể hủy gia hạn tự động',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBorderColor
                      : AppTheme.lightBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.themeOrangeStart,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Hủy Gói Premium',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bạn có chắc chắn muốn hủy gói đăng ký?',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Content - Loading or Result
              if (_checking)
                _buildLoading(isDark)
              else ...[
                // Error banner (e.g. cancellation limit)
                if (_error != null) _buildErrorBanner(isDark),

                // Subscription info
                _buildSubscriptionInfo(isDark),
                const SizedBox(height: 16),

                // 3-tier refund card
                _buildRefundCard(isDark),
                const SizedBox(height: 16),

                // Reason input (only if refund-eligible)
                if (_refundPercentage > 0 && _error == null) ...[
                  _buildReasonInput(isDark),
                  const SizedBox(height: 16),
                ],

                // Contextual warnings
                if (_error == null) ...[
                  _buildWarnings(isDark),
                  const SizedBox(height: 20),
                ],

                // Action buttons
                if (_error == null || !_isCancellationLimitMessage(_error))
                  _buildActions(isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CommonLoading.center(),
          const SizedBox(height: 12),
          Text(
            'Đang kiểm tra điều kiện hoàn tiền...',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(bool isDark) {
    final sub = context.read<PremiumProvider>().currentSubscription;
    if (sub == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkBackgroundSecondary
            : AppTheme.lightBackgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow('Gói hiện tại', sub.plan.displayName, isDark),
          _infoRow('Ngày đăng ký', _formatDate(sub.startDate), isDark),
          _infoRow('Số ngày đã sử dụng', '$_daysUsed ngày', isDark),
        ],
      ),
    );
  }

  Widget _buildRefundCard(bool isDark) {
    if (_refundPercentage == 100) {
      return _refundTierCard(
        isDark: isDark,
        icon: Icons.check_circle,
        iconColor: AppTheme.successColor,
        bgColor: AppTheme.successColor.withValues(alpha: 0.08),
        borderColor: AppTheme.successColor.withValues(alpha: 0.3),
        title: '✅ Hoàn tiền 100%',
        subtitle: 'Trong vòng 24 giờ — Hoàn tiền đầy đủ',
        amount: _refundAmount,
      );
    } else if (_refundPercentage == 50) {
      return _refundTierCard(
        isDark: isDark,
        icon: Icons.bolt,
        iconColor: AppTheme.themeOrangeStart,
        bgColor: AppTheme.themeOrangeStart.withValues(alpha: 0.08),
        borderColor: AppTheme.themeOrangeStart.withValues(alpha: 0.3),
        title: '⚡ Hoàn tiền 50%',
        subtitle: 'Từ 1–3 ngày — Hoàn một nửa số tiền',
        amount: _refundAmount,
      );
    } else {
      return _refundTierCard(
        isDark: isDark,
        icon: Icons.access_time,
        iconColor: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        bgColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.1,
        ),
        title: '❌ Không hoàn tiền',
        subtitle: 'Quá 3 ngày — Chỉ có thể hủy gia hạn tự động',
        amount: null,
        extraText: _eligibilityMessage,
      );
    }
  }

  Widget _refundTierCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    double? amount,
    String? extraText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
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
          if (amount != null && amount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Số tiền hoàn lại: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency(amount, currency: 'đ'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (extraText != null && extraText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              extraText,
              style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lý do hủy (tùy chọn):',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Vui lòng cho chúng tôi biết lý do bạn muốn hủy gói...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildWarnings(bool isDark) {
    final items = _refundPercentage > 0
        ? [
            'Gói Premium sẽ bị hủy ngay lập tức',
            'Bạn sẽ quay về gói Free Tier',
            'Hoàn $_refundPercentage% số tiền vào ví trong vài phút',
            'Bạn có thể đăng ký lại bất cứ lúc nào',
          ]
        : [
            'Gói Premium tiếp tục hoạt động đến hết kỳ',
            'Không bị tính phí ở kỳ tiếp theo',
            'Không hoàn tiền (quá 3 ngày)',
            'Có thể bật lại gia hạn tự động bất cứ lúc nào',
          ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.themeOrangeStart.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 18,
                color: AppTheme.themeOrangeStart,
              ),
              const SizedBox(width: 8),
              Text(
                _refundPercentage > 0
                    ? 'Lưu ý khi hủy & hoàn tiền:'
                    : 'Lưu ý khi hủy gia hạn:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12,
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
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _processing
                ? null
                : _refundPercentage > 0
                ? _handleCancelWithRefund
                : _handleCancelAutoRenewal,
            icon: _processing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CommonLoading.button(color: Colors.white),
                  )
                : Icon(
                    _refundPercentage > 0 ? Icons.cancel : Icons.toggle_off,
                    size: 20,
                  ),
            label: Text(
              _processing
                  ? 'Đang xử lý...'
                  : _refundPercentage > 0
                  ? 'Hủy gói & hoàn $_refundPercentage%'
                  : 'Hủy gia hạn tự động',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _refundPercentage > 0
                  ? AppTheme.errorColor
                  : AppTheme.themeOrangeStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Keep subscription
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _processing ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.shield, size: 18),
            label: const Text('Giữ gói Premium'),
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
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
              fontSize: 13,
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
