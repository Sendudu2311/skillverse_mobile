import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/error_handler.dart';

class SetupWalletSheet extends StatefulWidget {
  final bool needsPin;
  final bool needsBank;
  final VoidCallback? onSuccess;

  const SetupWalletSheet({
    super.key,
    required this.needsPin,
    required this.needsBank,
    this.onSuccess,
  });

  @override
  State<SetupWalletSheet> createState() => _SetupWalletSheetState();
}

class _SetupWalletSheetState extends State<SetupWalletSheet> {
  final _formKey = GlobalKey<FormState>();

  // Steps: 'bank' or 'pin'
  late String _step;

  // Controllers
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

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
  void initState() {
    super.initState();
    _step = widget.needsBank ? 'bank' : 'pin';
    
    // Auto-fill bank account name if provider has user details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WalletProvider>();
      if (provider.bankName != null && provider.bankName!.isNotEmpty) {
        _bankNameController.text = provider.bankName!;
      }
      if (provider.bankAccountName != null && provider.bankAccountName!.isNotEmpty) {
        _accountNameController.text = provider.bankAccountName!;
      }
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSetupBank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<WalletProvider>();
      await provider.updateBankAccount(
        bankName: _bankNameController.text,
        bankAccountNumber: _accountNumberController.text,
        bankAccountName: _accountNameController.text.toUpperCase(),
      );

      if (!mounted) return;

      if (widget.needsPin) {
        setState(() {
          _step = 'pin';
          _isLoading = false;
        });
      } else {
        widget.onSuccess?.call();
        Navigator.pop(context);
        ErrorHandler.showSuccessSnackBar(
          context,
          '🏦 Thiết lập tài khoản ngân hàng thành công!',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSetupPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<WalletProvider>();
      await provider.setTransactionPin(_pinController.text);

      if (!mounted) return;

      widget.onSuccess?.call();
      Navigator.pop(context);
      ErrorHandler.showSuccessSnackBar(
        context,
        '🔐 Thiết lập mã PIN giao dịch thành công!',
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
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar & Header
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
                      Icon(
                        _step == 'bank' ? Icons.account_balance : Icons.lock_outline,
                        color: AppTheme.accentCyan,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _step == 'bank'
                              ? 'Cấu Hình Tài Khoản Ngân Hàng'
                              : 'Thiết Lập Mã PIN Giao Dịch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Progress steps indicator
            if (widget.needsBank && widget.needsPin) _buildProgressIndicator(isDark),

            // Main Content Area
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),
                    if (_step == 'bank') ...[
                      // Bank Account Form
                      _buildInfoBox(
                        'Vui lòng thiết lập thông tin tài khoản ngân hàng chính xác để phục vụ cho các giao dịch rút tiền từ ví.',
                        isDark,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Tên ngân hàng *', isDark),
                      DropdownButtonFormField<String>(
                        value: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
                        items: _banks
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (v) => _bankNameController.text = v ?? '',
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn ngân hàng' : null,
                        decoration: _inputDecoration(isDark, hint: 'Chọn ngân hàng'),
                        dropdownColor: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
                        style: _inputTextStyle(isDark),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Số tài khoản *', isDark),
                      TextFormField(
                        controller: _accountNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập số tài khoản';
                          if (v.length < 5 || v.length > 19) return 'Số tài khoản phải từ 5-19 ký tự';
                          return null;
                        },
                        decoration: _inputDecoration(isDark, hint: 'Nhập số tài khoản ngân hàng'),
                        style: _inputTextStyle(isDark),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Tên chủ tài khoản *', isDark),
                      TextFormField(
                        controller: _accountNameController,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên chủ tài khoản' : null,
                        decoration: _inputDecoration(isDark, hint: 'VD: NGUYEN VAN A'),
                        style: _inputTextStyle(isDark),
                      ),
                    ] else ...[
                      // PIN Form
                      _buildInfoBox(
                        'Mã PIN gồm đúng 6 chữ số dùng để xác minh bảo mật nâng cao cho các lệnh rút tiền.',
                        isDark,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Mã PIN mới (6 chữ số) *', isDark),
                      TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: _obscurePin,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mã PIN';
                          if (v.length != 6) return 'Mã PIN phải có đúng 6 chữ số';
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

                      _buildLabel('Xác nhận mã PIN *', isDark),
                      TextFormField(
                        controller: _confirmPinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        obscureText: _obscureConfirmPin,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng xác nhận mã PIN';
                          if (v != _pinController.text) return 'Mã PIN xác nhận không trùng khớp';
                          return null;
                        },
                        decoration: _inputDecoration(isDark, hint: '••••••').copyWith(
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                          ),
                        ),
                        style: _inputTextStyle(isDark),
                      ),
                    ],

                    const SizedBox(height: 20),
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
                              child: Text(
                                _error!,
                                style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                  ),
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
                      onPressed: _isLoading
                          ? null
                          : (_step == 'bank' ? _handleSetupBank : _handleSetupPin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? CommonLoading.small()
                          : Text(
                              _step == 'bank'
                                  ? (widget.needsPin ? 'Tiếp theo →' : '✓ Hoàn tất')
                                  : '✓ Hoàn tất',
                              style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildProgressIndicator(bool isDark) {
    final activeColor = AppTheme.accentCyan;
    final inactiveColor = isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          _buildStepNode(1, 'Tài khoản NH', _step == 'bank', _step == 'pin', activeColor, inactiveColor, isDark),
          Expanded(child: Container(height: 2, color: _step == 'pin' ? activeColor : inactiveColor)),
          _buildStepNode(2, 'Mã PIN giao dịch', _step == 'pin', false, activeColor, inactiveColor, isDark),
        ],
      ),
    );
  }

  Widget _buildStepNode(
    int number,
    String title,
    bool isActive,
    bool isCompleted,
    Color activeColor,
    Color inactiveColor,
    bool isDark,
  ) {
    final nodeColor = isCompleted || isActive ? activeColor : inactiveColor;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted ? activeColor : (isActive ? Colors.transparent : inactiveColor.withValues(alpha: 0.1)),
            border: Border.all(color: nodeColor, width: 2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : (isActive ? activeColor : nodeColor.withValues(alpha: 0.6)),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted
                ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.accentCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
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

  InputDecoration _inputDecoration(bool isDark, {String? hint}) {
    return InputDecoration(
      hintText: hint,
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
}
