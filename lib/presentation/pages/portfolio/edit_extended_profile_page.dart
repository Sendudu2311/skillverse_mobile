import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../core/utils/error_handler.dart';

class EditExtendedProfilePage extends StatefulWidget {
  final ExtendedProfileDto? existingProfile;
  final bool isCreate;

  const EditExtendedProfilePage({
    super.key,
    this.existingProfile,
    this.isCreate = true,
  });

  @override
  State<EditExtendedProfilePage> createState() =>
      _EditExtendedProfilePageState();
}

class _EditExtendedProfilePageState extends State<EditExtendedProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _slugController = TextEditingController();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _expertiseController = TextEditingController();

  List<String> _expertiseAreas = [];
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Populate existing data
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _slugController.text = profile.slug ?? '';
      _headlineController.text = profile.headline ?? '';
      _bioController.text = profile.bio ?? '';
      _locationController.text = profile.location ?? '';
      _websiteController.text = profile.website ?? '';
      _githubController.text = profile.githubUrl ?? '';
      _linkedinController.text = profile.linkedinUrl ?? '';
      _twitterController.text = profile.twitterUrl ?? '';
      _expertiseAreas = profile.expertiseAreas ?? [];
      _isPublic = profile.isPublic ?? true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slugController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  void _addExpertiseArea() {
    final expertise = _expertiseController.text.trim();
    if (expertise.isNotEmpty && !_expertiseAreas.contains(expertise)) {
      setState(() {
        _expertiseAreas.add(expertise);
        _expertiseController.clear();
      });
    }
  }

  void _removeExpertiseArea(String area) {
    setState(() {
      _expertiseAreas.remove(area);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng kiểm tra lại thông tin đã nhập',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateExtendedProfileRequest(
        slug: _slugController.text.trim().isEmpty
            ? null
            : _slugController.text.trim(),
        headline: _headlineController.text.trim().isEmpty
            ? null
            : _headlineController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        githubUrl: _githubController.text.trim().isEmpty
            ? null
            : _githubController.text.trim(),
        linkedinUrl: _linkedinController.text.trim().isEmpty
            ? null
            : _linkedinController.text.trim(),
        twitterUrl: _twitterController.text.trim().isEmpty
            ? null
            : _twitterController.text.trim(),
        expertiseAreas: _expertiseAreas.isEmpty ? null : _expertiseAreas,
        isPublic: _isPublic,
      );

      final portfolioProvider = context.read<PortfolioProvider>();
      final success = widget.isCreate
          ? await portfolioProvider.createExtendedProfile(request)
          : await portfolioProvider.updateExtendedProfile(request);

      if (!mounted) return;

      if (success) {
        ErrorHandler.showSuccessSnackBar(
          context,
          widget.isCreate ? 'Tạo profile thành công!' : 'Cập nhật profile thành công!',
        );
        Navigator.pop(context, true);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          portfolioProvider.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Galaxy Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  _buildCustomAppBar(),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildSectionHeader(
                              icon: Icons.person,
                              title: widget.isCreate
                                  ? 'Tạo Extended Profile'
                                  : 'Chỉnh sửa Profile',
                              gradientColors: const [
                                AppTheme.themePurpleStart,
                                AppTheme.themePurpleEnd
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Basic Info Section
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),

                            // Social Links Section
                            _buildSocialLinksSection(),
                            const SizedBox(height: 24),

                            // Expertise Section
                            _buildExpertiseSection(),
                            const SizedBox(height: 24),

                            // Privacy Section
                            _buildPrivacySection(),
                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveButton(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.isCreate ? 'Tạo Profile' : 'Chỉnh sửa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Slug
          _buildTextField(
            controller: _slugController,
            label: 'Slug (URL cá nhân)',
            hint: 'vd: john-doe',
            prefixIcon: Icons.link,
            validator: (value) => ValidationHelper.slug(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // Headline
          _buildTextField(
            controller: _headlineController,
            label: 'Tiêu đề',
            hint: 'vd: Full-stack Developer | AI Enthusiast',
            prefixIcon: Icons.title,
            maxLength: 100,
          ),
          const SizedBox(height: 16),

          // Bio
          _buildTextField(
            controller: _bioController,
            label: 'Giới thiệu',
            hint: 'Kể về bản thân bạn...',
            prefixIcon: Icons.description,
            maxLines: 5,
            maxLength: 500,
          ),
          const SizedBox(height: 16),

          // Location
          _buildTextField(
            controller: _locationController,
            label: 'Địa điểm',
            hint: 'vd: Hồ Chí Minh, Việt Nam',
            prefixIcon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppTheme.themeBlueStart, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Liên kết mạng xã hội',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Website
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            hint: 'https://yourwebsite.com',
            prefixIcon: Icons.language,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // GitHub
          _buildTextField(
            controller: _githubController,
            label: 'GitHub',
            hint: 'https://github.com/username',
            prefixIcon: Icons.code,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // LinkedIn
          _buildTextField(
            controller: _linkedinController,
            label: 'LinkedIn',
            hint: 'https://linkedin.com/in/username',
            prefixIcon: Icons.business,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.linkedInUrl(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // Twitter
          _buildTextField(
            controller: _twitterController,
            label: 'Twitter/X',
            hint: '@username hoặc https://twitter.com/username',
            prefixIcon: Icons.chat,
            keyboardType: TextInputType.url,
            validator: (value) {
              // Allow both URL and @username format
              if (value == null || value.trim().isEmpty) return null;
              final trimmed = value.trim();
              if (trimmed.startsWith('@') || !trimmed.startsWith('http')) {
                return ValidationHelper.twitterUsername(trimmed, isRequired: false);
              }
              return ValidationHelper.url(trimmed, isRequired: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: AppTheme.themeOrangeStart, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Chuyên môn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add expertise field
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expertiseController,
                  label: 'Thêm kỹ năng',
                  hint: 'vd: Flutter, React, AI',
                  prefixIcon: Icons.add,
                  onSubmitted: (_) => _addExpertiseArea(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _addExpertiseArea,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expertise chips
          if (_expertiseAreas.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _expertiseAreas.map((area) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.themeOrangeStart,
                        AppTheme.themeOrangeEnd
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        area,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeExpertiseArea(area),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            const Text(
              'Chưa có kỹ năng nào',
              style: TextStyle(
                color: AppTheme.darkTextSecondary,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? AppTheme.themeGreenStart : AppTheme.errorColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hiển thị công khai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic
                      ? 'Profile của bạn có thể được mọi người xem'
                      : 'Chỉ bạn có thể xem profile này',
                  style: const TextStyle(
                    color: AppTheme.darkTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
            activeTrackColor: AppTheme.themeGreenStart,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppTheme.darkTextSecondary),
        counterText: maxLength != null ? null : '',
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        hintStyle: const TextStyle(color: AppTheme.darkTextSecondary),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.purpleGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.themePurpleStart.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProfile,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.isCreate ? 'Tạo Profile' : 'Lưu thay đổi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
