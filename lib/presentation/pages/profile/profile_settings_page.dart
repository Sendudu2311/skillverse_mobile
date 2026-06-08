import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../core/utils/error_handler.dart';
import 'change_password_sheet.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();
  final _socialLinksController = TextEditingController();

  // Focus nodes for better UX
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _birthdayFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _addressFocus = FocusNode();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isEditing = false;
  bool _isUploadingAvatar = false;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Track changes
    _fullNameController.addListener(_markAsChanged);
    _phoneController.addListener(_markAsChanged);
    _birthdayController.addListener(_markAsChanged);
    _bioController.addListener(_markAsChanged);
    _addressController.addListener(_markAsChanged);
    _socialLinksController.addListener(_markAsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _toggleEditMode() {
    if (_isEditing && _hasChanges) {
      _showDiscardDialog().then((shouldDiscard) {
        if (shouldDiscard == true) {
          setState(() {
            _isEditing = false;
            _hasChanges = false;
            _loadUserProfile(); // Reload to reset changes
          });
        }
      });
    } else {
      setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing) {
          // Reset changes if cancelling edit without changes
          _hasChanges = false;
          _loadUserProfile();
        }
      });
    }
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadUserProfile() async {
    final userProvider = context.read<UserProvider>();

    setState(() => _isLoading = true);
    // Use user ID if available, otherwise try default (which might fail if /me is broken)
    // Always load "me" profile for settings page
    await userProvider.loadUserProfile();

    if (!mounted) return;

    final profile = userProvider.userProfile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phone ?? '';
      _birthdayController.text = profile.birthday ?? '';
      _bioController.text = profile.bio ?? '';
      _addressController.text = profile.address ?? '';
      _socialLinksController.text = profile.socialLinks ?? '';
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
    _birthdayController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _socialLinksController.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _birthdayFocus.dispose();
    _bioFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!_isEditing || _isUploadingAvatar) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    final userProvider = context.read<UserProvider>();
    final success = await userProvider.uploadAvatar(pickedFile.path);

    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (success) {
      ErrorHandler.showSuccessSnackBar(context, 'Cập nhật ảnh đại diện thành công!');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        userProvider.errorMessage ?? 'Không thể tải ảnh lên, thử lại sau.',
      );
    }
  }

  Future<void> _selectBirthday() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_birthdayController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_birthdayController.text);
      } catch (_) {}
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.accentCyan,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthdayController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
    if (_birthdayController.text.trim().isNotEmpty) {
      updateData['birthday'] = _birthdayController.text.trim();
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

    setState(() => _isSaving = true);

    try {
      final success = await userProvider.updateUserProfile(updateData);

      if (!mounted) return;

      if (success) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });

        ErrorHandler.showSuccessSnackBar(
          context,
          'Cập nhật thông tin thành công!',
        );

        // Delay before popping to show success message
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // context.pop(); // Don't pop, just switch back to view mode
          setState(() {
            _isEditing = false;
          });
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
    ErrorHandler.showErrorSnackBar(context, message);
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
        appBar: SkillVerseAppBar(
          title: _isEditing ? 'Chỉnh sửa hồ sơ' : 'Hồ sơ cá nhân',
          actions: [
            if (_isSaving)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CommonLoading.small(),
              )
            else if (_isEditing)
              TextButton.icon(
                onPressed: _hasChanges ? _saveProfile : null,
                icon: const Icon(Icons.check),
                label: const Text('Lưu'),
                style: TextButton.styleFrom(
                  foregroundColor: _hasChanges
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
              )
            else
              IconButton(
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Chỉnh sửa',
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: _isLoading
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
                              SectionHeader(
                                title: 'Thông tin cá nhân',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _fullNameController,
                                focusNode: _fullNameFocus,
                                label: 'Họ và tên',
                                icon: Icons.badge_outlined,
                                enabled: _isEditing,
                                validator: (value) => ValidationHelper.required(
                                  value,
                                  fieldName: 'Họ và tên',
                                ),
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    _phoneFocus.requestFocus(),
                              ),

                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _phoneController,
                                focusNode: _phoneFocus,
                                label: 'Số điện thoại',
                                icon: Icons.phone_outlined,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                validator: (value) =>
                                    ValidationHelper.phoneNumber(
                                      value,
                                      isRequired: true,
                                    ),
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    _bioFocus.requestFocus(),
                              ),

                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _birthdayController,
                                focusNode: _birthdayFocus,
                                label: 'Ngày sinh',
                                icon: Icons.calendar_today_outlined,
                                enabled: _isEditing,
                                readOnly: true,
                                onTap: _isEditing ? _selectBirthday : null,
                                hint: 'Chọn ngày sinh của bạn',
                              ),

                              const SizedBox(height: 12),

                              // Bio Section
                              SectionHeader(
                                title: 'Giới thiệu',
                                icon: Icons.info_outline,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _bioController,
                                focusNode: _bioFocus,
                                label: 'Giới thiệu bản thân',
                                icon: Icons.notes,
                                enabled: _isEditing,
                                maxLines: 4,
                                maxLength: 500,
                                textInputAction: TextInputAction.newline,
                                hint: 'Viết vài dòng về bản thân...',
                              ),

                              const SizedBox(height: 24),

                              const SizedBox(height: 12),

                              _buildTextField(
                                controller: _addressController,
                                focusNode: _addressFocus,
                                label: 'Địa chỉ chi tiết',
                                icon: Icons.home_outlined,
                                enabled: _isEditing,
                                maxLines: 2,
                                hint: 'Số nhà, tên đường...',
                              ),

                              const SizedBox(height: 24),

                              if (!_isEditing) ...[
                                SectionHeader(
                                  title: 'Bảo mật tài khoản',
                                  icon: Icons.shield_outlined,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => ChangePasswordSheet.show(context),
                                    icon: const Icon(Icons.lock_outline),
                                    label: const Text('Đổi mật khẩu'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
          CommonLoading.center(),
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
    final userProvider = context.read<UserProvider>();
    final avatarUrl = userProvider.userProfile?.avatarMediaUrl;

    return Center(
      child: GlassCard(
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _pickAndUploadAvatar : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    onBackgroundImageError:
                        (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? (_, __) {}
                            : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _isUploadingAvatar
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).disabledColor,
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
            ),
            const SizedBox(height: 12),
            Text(
              _isEditing ? 'Chạm để đổi ảnh đại diện' : 'Ảnh đại diện',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (!_isEditing) ...
              [
                const SizedBox(height: 4),
                Text(
                  'Chuyển sang chế độ chỉnh sửa để thay ảnh',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
          ],
        ),
      ),
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
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
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

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor),
              const SizedBox(width: 12),
              const Text('Hủy thay đổi?'),
            ],
          ),
          content: const Text(
            'Bạn có những thay đổi chưa được lưu. Bạn có muốn hủy bỏ?',
          ),
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
