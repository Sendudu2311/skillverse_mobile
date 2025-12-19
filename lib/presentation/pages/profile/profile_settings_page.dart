import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _socialLinksController = TextEditingController();

  // Focus nodes for better UX
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _addressFocus = FocusNode();

  String? _selectedGender;
  DateTime? _selectedBirthday;
  String? _selectedProvinceCode;
  String? _selectedDistrictCode;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Track changes
    _fullNameController.addListener(_markAsChanged);
    _phoneController.addListener(_markAsChanged);
    _bioController.addListener(_markAsChanged);
    _addressController.addListener(_markAsChanged);
    _socialLinksController.addListener(_markAsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadUserProfile() async {
    final userProvider = context.read<UserProvider>();

    setState(() => _isLoading = true);
    await userProvider.loadUserProfile();

    if (!mounted) return;

    final profile = userProvider.userProfile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phone ?? '';
      _bioController.text = profile.bio ?? '';
      _addressController.text = profile.address ?? '';
      _socialLinksController.text = profile.socialLinks ?? '';
      _selectedGender = profile.gender;

      if (profile.birthday != null) {
        try {
          _selectedBirthday = DateTime.parse(profile.birthday!);
        } catch (e) {
          // Invalid date format
        }
      }

      // Load provinces for dropdown
      if (userProvider.provinces.isEmpty) {
        await userProvider.loadProvinces();
      }

      // Set selected province and load districts if available
      if (profile.province != null && userProvider.provinces.isNotEmpty) {
        try {
          final province = userProvider.provinces.firstWhere(
            (p) => p.name == profile.province,
          );
          _selectedProvinceCode = province.code;
          await userProvider.loadDistrictsByProvince(province.code);

          // Set selected district
          if (profile.district != null && userProvider.districts.isNotEmpty) {
            try {
              final district = userProvider.districts.firstWhere(
                (d) => d.name == profile.district,
              );
              _selectedDistrictCode = district.code;
            } catch (e) {
              // District not found
            }
          }
        } catch (e) {
          // Province not found
        }
      }
    }

    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _socialLinksController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _bioFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    // Unfocus all fields
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = context.read<UserProvider>();

    final updateData = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
    };

    if (_phoneController.text.trim().isNotEmpty) {
      updateData['phone'] = _phoneController.text.trim();
    }
    if (_bioController.text.trim().isNotEmpty) {
      updateData['bio'] = _bioController.text.trim();
    }
    if (_addressController.text.trim().isNotEmpty) {
      updateData['address'] = _addressController.text.trim();
    }
    if (_socialLinksController.text.trim().isNotEmpty) {
      updateData['socialLinks'] = _socialLinksController.text.trim();
    }
    if (_selectedGender != null) {
      updateData['gender'] = _selectedGender;
    }
    if (_selectedBirthday != null) {
      updateData['birthday'] = _selectedBirthday!.toIso8601String().split('T')[0];
    }
    if (_selectedProvinceCode != null) {
      updateData['provinceCode'] = _selectedProvinceCode;
    }
    if (_selectedDistrictCode != null) {
      updateData['districtCode'] = _selectedDistrictCode;
    }

    setState(() => _isSaving = true);

    try {
      final success = await userProvider.updateUserProfile(updateData);

      if (!mounted) return;

      if (success) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Cập nhật thông tin thành công!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Delay before popping to show success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.pop();
        }
      } else {
        setState(() => _isSaving = false);
        _showErrorSnackBar(userProvider.errorMessage ?? 'Đã có lỗi xảy ra');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Đã có lỗi xảy ra');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (_hasChanges && !_isSaving) {
          final shouldPop = await _showDiscardDialog();
          if (shouldPop == true && context.mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chỉnh sửa hồ sơ'),
          actions: [
            if (_isSaving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              AnimatedOpacity(
                opacity: _hasChanges ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: TextButton.icon(
                  onPressed: _hasChanges ? _saveProfile : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Lưu'),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar section
                            _buildAvatarSection(),

                            const SizedBox(height: 24),

                            // Personal Information
                            _buildSectionHeader('Thông tin cá nhân', Icons.person_outline),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _fullNameController,
                              focusNode: _fullNameFocus,
                              label: 'Họ và tên',
                              icon: Icons.badge_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập họ tên';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                            ),

                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _phoneController,
                              focusNode: _phoneFocus,
                              label: 'Số điện thoại',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                                    return 'Số điện thoại không hợp lệ';
                                  }
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _bioFocus.requestFocus(),
                            ),

                            const SizedBox(height: 12),

                            _buildDropdown(
                              value: _selectedGender,
                              label: 'Giới tính',
                              icon: Icons.wc_outlined,
                              items: const [
                                DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                                DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                                DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                  _hasChanges = true;
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            _buildDatePicker(),

                            const SizedBox(height: 24),

                            // Bio Section
                            _buildSectionHeader('Giới thiệu', Icons.info_outline),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _bioController,
                              focusNode: _bioFocus,
                              label: 'Giới thiệu bản thân',
                              icon: Icons.notes,
                              maxLines: 4,
                              maxLength: 500,
                              textInputAction: TextInputAction.newline,
                              hint: 'Viết vài dòng về bản thân...',
                            ),

                            const SizedBox(height: 24),

                            // Location Section
                            _buildSectionHeader('Địa chỉ', Icons.location_on_outlined),
                            const SizedBox(height: 16),

                            if (userProvider.provinces.isNotEmpty)
                              _buildDropdown(
                                value: _selectedProvinceCode,
                                label: 'Tỉnh/Thành phố',
                                icon: Icons.location_city_outlined,
                                items: userProvider.provinces.map((province) {
                                  return DropdownMenuItem(
                                    value: province.code,
                                    child: Text(province.name),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  setState(() {
                                    _selectedProvinceCode = value;
                                    _selectedDistrictCode = null;
                                    _hasChanges = true;
                                  });
                                  if (value != null) {
                                    await userProvider.loadDistrictsByProvince(value);
                                  }
                                },
                              ),

                            const SizedBox(height: 12),

                            if (userProvider.districts.isNotEmpty && _selectedProvinceCode != null)
                              _buildDropdown(
                                value: _selectedDistrictCode,
                                label: 'Quận/Huyện',
                                icon: Icons.my_location_outlined,
                                items: userProvider.districts.map((district) {
                                  return DropdownMenuItem(
                                    value: district.code,
                                    child: Text(district.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDistrictCode = value;
                                    _hasChanges = true;
                                  });
                                },
                              ),

                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _addressController,
                              focusNode: _addressFocus,
                              label: 'Địa chỉ chi tiết',
                              icon: Icons.home_outlined,
                              maxLines: 2,
                              hint: 'Số nhà, tên đường...',
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải thông tin...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GlassCard(
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tải ảnh đại diện',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tính năng sẽ được cập nhật sau',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          counterText: maxLength != null ? null : '',
        ),
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Theme.of(context).cardColor,
      ),
    );
  }

  Widget _buildDatePicker() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectBirthday,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày sinh',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedBirthday != null
                            ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                            : 'Chưa chọn',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _selectedBirthday != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 12),
              const Text('Hủy thay đổi?'),
            ],
          ),
          content: const Text('Bạn có những thay đổi chưa được lưu. Bạn có muốn hủy bỏ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Tiếp tục chỉnh sửa'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Hủy bỏ'),
            ),
          ],
        );
      },
    );
  }
}
