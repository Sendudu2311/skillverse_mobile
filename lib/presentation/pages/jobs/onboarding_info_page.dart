import 'package:flutter/material.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/contract_models.dart';
import '../../../data/services/contract_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/animated_success_overlay.dart';
import 'package:intl/intl.dart';

class OnboardingInfoPage extends StatefulWidget {
  final int applicationId;

  const OnboardingInfoPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<OnboardingInfoPage> createState() => _OnboardingInfoPageState();
}

class _OnboardingInfoPageState extends State<OnboardingInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _contractService = ContractService();

  bool _isLoading = false;
  bool _isFetchingInitial = true;

  // CCCD
  final _idCardNumberController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _idCardDateController = TextEditingController();
  final _idCardPlaceController = TextEditingController();
  final _addressController = TextEditingController();

  // Bank
  final _bankAccountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();

  DateTime? _dob;
  DateTime? _idCardDate;

  @override
  void initState() {
    super.initState();
    _fetchLatestOnboardingInfo();
  }

  Future<void> _fetchLatestOnboardingInfo() async {
    try {
      final info = await _contractService.getLatestOnboardingInfo();
      if (info != null && mounted) {
        _idCardNumberController.text = info.idCardNumber;
        _fullNameController.text = info.fullName;
        _idCardPlaceController.text = info.idCardPlace;
        _addressController.text = info.address ?? '';
        _bankAccountNumberController.text = info.bankAccountNumber;
        _bankNameController.text = info.bankName;
        _bankAccountHolderController.text = info.bankAccountHolder;

        if (info.dateOfBirth != null) {
          _dob = DateTime.tryParse(info.dateOfBirth!);
          if (_dob != null) {
            _dateOfBirthController.text =
                DateFormat('dd/MM/yyyy').format(_dob!);
          }
        }
        if (info.idCardDate != null) {
          _idCardDate = DateTime.tryParse(info.idCardDate!);
          if (_idCardDate != null) {
            _idCardDateController.text =
                DateFormat('dd/MM/yyyy').format(_idCardDate!);
          }
        }
      }
    } catch (e) {
      // Ignore errors when fetching pre-fill data
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingInitial = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final initialDate = isDob ? (_dob ?? DateTime(2000)) : (_idCardDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isDob) {
          _dob = picked;
          _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _idCardDate = picked;
          _idCardDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardDate == null) {
      ErrorHandler.showErrorSnackBar(context, 'Vui lòng chọn ngày cấp CCCD');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = OnboardingInfoRequest(
        idCardNumber: _idCardNumberController.text.trim(),
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
        idCardDate: DateFormat('yyyy-MM-dd').format(_idCardDate!),
        idCardPlace: _idCardPlaceController.text.trim(),
        address: _addressController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        bankAccountHolder: _bankAccountHolderController.text.trim(),
      );

      await _contractService.submitOnboardingInfo(
        widget.applicationId,
        request,
      );

      if (mounted) {
        // Show success overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AnimatedSuccessOverlay(
            title: 'Gửi thông tin thành công',
            subtitle: 'Nhà tuyển dụng sẽ sớm liên hệ với bạn',
          ),
        );

        // Pop dialog and page after delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop(); // pop dialog
          Navigator.of(context).pop(true); // pop page with success
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cung cấp thông tin'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.lightTextPrimary,
        elevation: 0.5,
      ),
      body: _isFetchingInitial
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Thông tin Định danh (CCCD/CMND)'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Họ và tên',
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _idCardNumberController,
                        label: 'Số CCCD/CMND',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập số CCCD' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerField(
                              controller: _dateOfBirthController,
                              label: 'Ngày sinh (Tùy chọn)',
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDatePickerField(
                              controller: _idCardDateController,
                              label: 'Ngày cấp',
                              onTap: () => _selectDate(context, false),
                              validator: (v) => v!.isEmpty ? 'Chọn ngày cấp' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _idCardPlaceController,
                        label: 'Nơi cấp',
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập nơi cấp' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Địa chỉ hiện tại (Tùy chọn)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Thông tin Ngân hàng (Nhận lương)'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _bankNameController,
                        label: 'Tên Ngân hàng (VD: Vietcombank, Techcombank...)',
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập ngân hàng' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bankAccountHolderController,
                        label: 'Tên Chủ tài khoản',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên chủ TK' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bankAccountNumberController,
                        label: 'Số Tài khoản',
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Gửi thông tin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _idCardNumberController.dispose();
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _idCardDateController.dispose();
    _idCardPlaceController.dispose();
    _addressController.dispose();
    _bankAccountNumberController.dispose();
    _bankNameController.dispose();
    _bankAccountHolderController.dispose();
    super.dispose();
  }
}
