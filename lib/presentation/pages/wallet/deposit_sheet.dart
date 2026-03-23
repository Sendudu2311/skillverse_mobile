import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/services/wallet_service.dart';
import '../payment/payment_webview_page.dart';

/// Bottom sheet for depositing cash into wallet via PayOS
class DepositSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const DepositSheet({super.key, required this.onSuccess});

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
  final _customAmountController = TextEditingController();
  final _walletService = WalletService();

  int? _selectedAmount;
  bool _isLoading = false;
  String? _error;

  static const List<int> _quickAmounts = [
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
  ];

  int get _amount => _selectedAmount ?? int.tryParse(
    _customAmountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
  ) ?? 0;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _onQuickAmountTap(int amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.text = NumberFormatter.formatNumber(amount);
      _error = null;
    });
  }

  void _onCustomAmountChanged(String value) {
    setState(() {
      _selectedAmount = null;
      _error = null;
    });
  }

  Future<void> _handleDeposit() async {
    final amount = _amount;

    if (amount < 10000) {
      setState(() => _error = 'Số tiền tối thiểu là 10.000 đ');
      return;
    }
    if (amount > 50000000) {
      setState(() => _error = 'Số tiền tối đa là 50.000.000 đ');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      const baseUrl = 'https://skillverse.vn';
      const successUrl = '$baseUrl/my-wallet?status=success';
      const cancelUrl = '$baseUrl/my-wallet?status=cancel';
      final response = await _walletService.createDeposit(
        amount: amount.toDouble(),
        returnUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final checkoutUrl = response['checkoutUrl'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Không nhận được URL thanh toán');
      }

      if (!mounted) return;

      // Navigate to PaymentWebViewPage
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewPage(
            checkoutUrl: checkoutUrl,
            successUrl: successUrl,
            cancelUrl: cancelUrl,
          ),
        ),
      );

      if (!mounted) return;

      // Luôn refresh wallet sau khi quay về từ WebView
      // vì backend PayOS callback xử lý việc cộng tiền tự động
      widget.onSuccess();
      Navigator.pop(context);

      final isSuccess = result != null && result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuccess
              ? '🎉 Nạp tiền thành công!'
              : '⏳ Đang xử lý thanh toán...'),
          backgroundColor: isSuccess ? AppTheme.successColor : AppTheme.accentCyan,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
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
                Icon(Icons.account_balance_wallet, color: AppTheme.themeGreenStart, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Nạp Tiền Vào Ví',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick amounts
            Text(
              'Chọn nhanh:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amt) => _buildQuickAmountChip(amt, isDark)).toList(),
            ),
            const SizedBox(height: 20),

            // Custom input
            Text(
              'Hoặc nhập số tiền:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onCustomAmountChanged,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'VNĐ',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.themeGreenStart),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 Tối thiểu: 10.000 đ | Tối đa: 50.000.000 đ',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Summary
            if (_amount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.themeGreenStart.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.themeGreenStart.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Phương thức:', '💳 PayOS (QR Code)', isDark),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Số tiền nạp:',
                      NumberFormatter.formatCurrency(_amount.toDouble(), currency: 'đ'),
                      isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading || _amount <= 0 ? null : _handleDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.themeGreenStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('🚀 Tiến Hành Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(int amount, bool isDark) {
    final isSelected = _selectedAmount == amount;
    return GestureDetector(
      onTap: () => _onQuickAmountTap(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.themeGreenStart.withValues(alpha: 0.2)
              : (isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.themeGreenStart
                : (isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          NumberFormatter.formatCurrency(amount.toDouble(), currency: 'đ'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
            color: isSelected
                ? AppTheme.themeGreenStart
                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
            color: isBold ? AppTheme.themeGreenStart : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
