import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/services/wallet_service.dart';

/// Bottom sheet for creating a withdrawal request
class WithdrawSheet extends StatefulWidget {
  final double currentCashBalance;
  final bool hasBankAccount;
  final VoidCallback onSuccess;

  const WithdrawSheet({
    super.key,
    required this.currentCashBalance,
    required this.hasBankAccount,
    required this.onSuccess,
  });

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _walletService = WalletService();

  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _pinController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePin = true;

  static const List<String> _banks = [
    'Vietcombank',
    'BIDV',
    'Agribank',
    'VietinBank',
    'Techcombank',
    'MB Bank',
    'ACB',
    'VPBank',
    'SHB',
    'TPBank',
    'Sacombank',
    'HDBank',
    'OCB',
    'SeABank',
    'LienVietPostBank',
    'MSB',
    'VIB',
    'Eximbank',
    'Khác',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _branchController.dispose();
    _pinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(
    _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
  ) ?? 0;

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _amount;
    if (amount < 100000) {
      setState(() => _error = 'Số tiền rút tối thiểu là 100.000 đ');
      return;
    }
    if (amount > widget.currentCashBalance) {
      setState(() => _error = 'Số dư không đủ');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _walletService.createWithdrawalRequest(
        amount: amount.toDouble(),
        bankName: _bankNameController.text,
        bankAccountNumber: _accountNumberController.text,
        bankAccountName: _accountNameController.text.toUpperCase(),
        bankBranch: _branchController.text.isNotEmpty ? _branchController.text : null,
        transactionPin: _pinController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      widget.onSuccess();
      Navigator.pop(context);
      ErrorHandler.showSuccessSnackBar(context, '✅ Yêu cầu rút tiền đã gửi! Chờ Admin duyệt.');
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
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.account_balance, color: AppTheme.accentCyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rút Tiền',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Số dư: ${NumberFormatter.formatCurrency(widget.currentCashBalance, currency: 'đ')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Amount
                  _buildLabel('Số tiền rút (VNĐ)', isDark),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập số tiền';
                      final amount = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                      if (amount < 100000) return 'Tối thiểu 100.000 đ';
                      if (amount > 100000000) return 'Tối đa 100.000.000 đ';
                      if (amount > widget.currentCashBalance) return 'Vượt quá số dư';
                      return null;
                    },
                    decoration: _inputDecoration(isDark, hint: '100.000', suffix: 'VNĐ'),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 Tối thiểu: 100.000 đ | Tối đa: 100.000.000 đ',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Bank name dropdown
                  _buildLabel('Ngân hàng', isDark),
                  DropdownButtonFormField<String>(
                    initialValue: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
                    items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) => _bankNameController.text = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Chọn ngân hàng' : null,
                    decoration: _inputDecoration(isDark, hint: 'Chọn ngân hàng'),
                    dropdownColor: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Account number
                  _buildLabel('Số tài khoản', isDark),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập số tài khoản';
                      if (v.length < 5 || v.length > 19) return '5-19 ký tự';
                      return null;
                    },
                    decoration: _inputDecoration(isDark, hint: '1234567890'),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Account name
                  _buildLabel('Tên chủ tài khoản', isDark),
                  TextFormField(
                    controller: _accountNameController,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v == null || v.isEmpty ? 'Nhập tên chủ TK' : null,
                    decoration: _inputDecoration(isDark, hint: 'NGUYEN VAN A'),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Branch (optional)
                  _buildLabel('Chi nhánh (tùy chọn)', isDark),
                  TextFormField(
                    controller: _branchController,
                    decoration: _inputDecoration(isDark, hint: 'Chi nhánh Hà Nội'),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // PIN
                  _buildLabel('Mã PIN giao dịch (6 số)', isDark),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: _obscurePin,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Nhập mã PIN';
                      if (v.length != 6) return 'PIN phải có 6 số';
                      return null;
                    },
                    decoration: _inputDecoration(isDark, hint: '••••••').copyWith(
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePin ? Icons.visibility_off : Icons.visibility,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePin = !_obscurePin),
                      ),
                    ),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Notes (optional)
                  _buildLabel('Ghi chú (tùy chọn)', isDark),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: _inputDecoration(isDark, hint: 'Ghi chú cho yêu cầu rút tiền'),
                    style: _inputTextStyle(isDark),
                  ),
                  const SizedBox(height: 16),

                  // Error
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
                          Expanded(
                            child: Text(_error!, style: TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Yêu cầu rút tiền cần Admin duyệt. Thời gian xử lý 1-3 ngày làm việc.',
                            style: TextStyle(fontSize: 12, color: AppTheme.accentCyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary,
              border: Border(
                top: BorderSide(color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
              ),
            ),
            child: Row(
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
                    onPressed: _isLoading ? null : _handleWithdraw,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? CommonLoading.small()
                        : const Text('💸 Gửi Yêu Cầu Rút Tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hint, String? suffix}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      suffixStyle: TextStyle(fontSize: 14, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.accentCyan),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  TextStyle _inputTextStyle(bool isDark) {
    return TextStyle(
      fontSize: 15,
      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
    );
  }
}
