import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/services/wallet_service.dart';
import '../../providers/wallet_provider.dart';
import 'setup_wallet_sheet.dart';

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

  static const int _minWithdraw = 100000;
  static const int _maxWithdraw = 10000000;
  static const double _withdrawFeePercent = 0.02;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hasBankAccount) {
        final walletProvider = context.read<WalletProvider>();
        setState(() {
          _bankNameController.text = walletProvider.bankName ?? '';
          _accountNameController.text = walletProvider.bankAccountName ?? '';
        });
      }
    });
  }

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

  int get _amount =>
      int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
      0;

  int get _withdrawFee => (_amount * _withdrawFeePercent).round();
  int get _netAmount => (_amount - _withdrawFee).clamp(0, _amount).toInt();

  Future<void> _handleWithdraw() async {
    final walletProvider = context.read<WalletProvider>();
    if (!walletProvider.hasBankAccount || !walletProvider.hasTransactionPin) {
      setState(() {
        _error =
            'Vui lòng thiết lập tài khoản ngân hàng và mã PIN giao dịch trước khi rút tiền.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = _amount;
    if (amount < _minWithdraw) {
      setState(() => _error = 'Số tiền rút tối thiểu là 100.000 đ');
      return;
    }
    if (amount > _maxWithdraw) {
      setState(() => _error = 'Số tiền rút tối đa là 10.000.000 đ');
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
        bankBranch: _branchController.text.isNotEmpty
            ? _branchController.text
            : null,
        transactionPin: _pinController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      widget.onSuccess();
      Navigator.pop(context);
      ErrorHandler.showSuccessSnackBar(
        context,
        '✅ Yêu cầu rút tiền đã gửi! Chờ Admin duyệt.',
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
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
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
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: AppTheme.accentCyan,
                        size: 28,
                      ),
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
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'Số dư: ${NumberFormatter.formatCurrency(widget.currentCashBalance, currency: 'đ')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
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
                    // Warning Box if no PIN or Bank Account
                    _buildWarningBox(context, isDark),

                    // Amount
                    _buildLabel('Số tiền rút (VNĐ)', isDark),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập số tiền';
                        final amount =
                            int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ??
                            0;
                        if (amount < _minWithdraw) return 'Tối thiểu 100.000 đ';
                        if (amount > _maxWithdraw) return 'Tối đa 10.000.000 đ';
                        if (amount > widget.currentCashBalance) {
                          return 'Vượt quá số dư';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        isDark,
                        hint: '100.000',
                        suffix: 'VNĐ',
                      ),
                      style: _inputTextStyle(isDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '💡 Tối thiểu: 100.000 đ | Tối đa: 10.000.000 đ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_amount >= _minWithdraw) ...[
                      _buildWithdrawalSummary(isDark),
                      const SizedBox(height: 16),
                    ],

                    // Bank name dropdown
                    _buildLabel('Ngân hàng', isDark),
                    DropdownButtonFormField<String>(
                      initialValue: _bankNameController.text.isNotEmpty
                          ? _bankNameController.text
                          : null,
                      items: _banks
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) => _bankNameController.text = v ?? '',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Chọn ngân hàng' : null,
                      decoration: _inputDecoration(
                        isDark,
                        hint: 'Chọn ngân hàng',
                      ),
                      dropdownColor: isDark
                          ? AppTheme.darkCardBackground
                          : AppTheme.lightCardBackground,
                      style: _inputTextStyle(isDark),
                    ),
                    const SizedBox(height: 16),

                    // Account number
                    _buildLabel('Số tài khoản', isDark),
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập số tài khoản';
                        if (!RegExp(r'^[A-Za-z0-9]{5,19}$').hasMatch(v)) {
                          return 'Số tài khoản phải từ 5-19 ký tự chữ hoặc số';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        isDark,
                        hint: widget.hasBankAccount
                            ? _getBankMaskHint(context.read<WalletProvider>())
                            : '1234567890',
                      ),
                      style: _inputTextStyle(isDark),
                    ),
                    const SizedBox(height: 16),

                    // Account name
                    _buildLabel('Tên chủ tài khoản', isDark),
                    TextFormField(
                      controller: _accountNameController,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nhập tên chủ TK' : null,
                      decoration: _inputDecoration(
                        isDark,
                        hint: 'NGUYEN VAN A',
                      ),
                      style: _inputTextStyle(isDark),
                    ),
                    const SizedBox(height: 16),

                    // Branch (optional)
                    _buildLabel('Chi nhánh (tùy chọn)', isDark),
                    TextFormField(
                      controller: _branchController,
                      decoration: _inputDecoration(
                        isDark,
                        hint: 'Chi nhánh Hà Nội',
                      ),
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
                      decoration: _inputDecoration(isDark, hint: '••••••')
                          .copyWith(
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePin = !_obscurePin),
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
                      decoration: _inputDecoration(
                        isDark,
                        hint: 'Ghi chú cho yêu cầu rút tiền',
                      ),
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
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.accentCyan,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Yêu cầu rút tiền cần Admin duyệt. Thời gian xử lý 1-3 ngày làm việc.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.accentCyan,
                              ),
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
                color: isDark
                    ? AppTheme.darkBackgroundSecondary
                    : AppTheme.lightBackgroundSecondary,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBorderColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CommonLoading.small()
                          : const Text(
                              '💸 Gửi Yêu Cầu Rút Tiền',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    bool isDark, {
    String? hint,
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      suffixStyle: TextStyle(
        fontSize: 14,
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
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

  Widget _buildWithdrawalSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Số tiền rút',
            NumberFormatter.formatCurrency(_amount.toDouble(), currency: 'đ'),
            isDark,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Phí xử lý (2%)',
            '-${NumberFormatter.formatCurrency(_withdrawFee.toDouble(), currency: 'đ')}',
            isDark,
          ),
          const Divider(height: 18),
          _buildSummaryRow(
            'Thực nhận',
            NumberFormatter.formatCurrency(_netAmount.toDouble(), currency: 'đ'),
            isDark,
            isBold: true,
            valueColor: AppTheme.themeGreenStart,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.schedule, size: 16, color: AppTheme.accentCyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Yêu cầu được xử lý trong 1-3 ngày làm việc sau khi Admin duyệt.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
            color: valueColor ??
                (isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBox(BuildContext context, bool isDark) {
    final walletProvider = context.watch<WalletProvider>();
    final hasPin = walletProvider.hasTransactionPin;
    final hasBank = walletProvider.hasBankAccount;

    if (hasPin && hasBank) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.themeOrangeStart.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.themeOrangeStart, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  !hasBank && !hasPin
                      ? 'Bạn chưa thiết lập tài khoản ngân hàng và mã PIN'
                      : (!hasBank
                          ? 'Bạn chưa thiết lập tài khoản ngân hàng'
                          : 'Bạn chưa thiết lập mã PIN giao dịch'),
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SetupWalletSheet(
                    needsPin: !hasPin,
                    needsBank: !hasBank,
                    onSuccess: () => walletProvider.refresh(),
                  ),
                );
              },
              icon: const Icon(Icons.settings, size: 14),
              label: const Text('Thiết lập ngay'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.themeOrangeStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBankMaskHint(WalletProvider provider) {
    final number = provider.bankAccountNumber;
    if (number != null && number.length >= 4) {
      return 'Nhập lại số TK (***${number.substring(number.length - 4)})';
    }
    return '1234567890';
  }
}
