import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/common_loading.dart';

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
  late bool isDark;
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
  final _behanceController = TextEditingController();
  final _dribbbleController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _yearsExpController = TextEditingController();

  List<String> _expertiseAreas = [];
  List<PortfolioWorkExperienceDto> _workExperiences = [];
  List<PortfolioEducationDto> _educationHistory = [];
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
      _behanceController.text = profile.behanceUrl ?? '';
      _dribbbleController.text = profile.dribbbleUrl ?? '';
      _expertiseAreas = profile.expertiseAreas ?? [];
      _isPublic = profile.isPublic ?? true;
      _yearsExpController.text =
          profile.yearsOfExperience?.toString() ?? '';
      _workExperiences = List.of(profile.workExperiences ?? []);
      _educationHistory = List.of(profile.educationHistory ?? []);
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
    _behanceController.dispose();
    _dribbbleController.dispose();
    _expertiseController.dispose();
    _yearsExpController.dispose();
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
      final request = CreateExtendedProfileRequest.fromOldFields(
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
        behanceUrl: _behanceController.text.trim().isEmpty
            ? null
            : _behanceController.text.trim(),
        dribbbleUrl: _dribbbleController.text.trim().isEmpty
            ? null
            : _dribbbleController.text.trim(),
        expertiseAreas: _expertiseAreas.isEmpty ? null : _expertiseAreas,
        isPublic: _isPublic,
        yearsOfExperience: int.tryParse(_yearsExpController.text.trim()),
        workExperiences: _workExperiences.isEmpty ? null : _workExperiences,
        educationHistory: _educationHistory.isEmpty ? null : _educationHistory,
      );

      final portfolioProvider = context.read<PortfolioProvider>();
      final success = widget.isCreate
          ? await portfolioProvider.createExtendedProfile(request)
          : await portfolioProvider.updateExtendedProfile(request);

      if (!mounted) return;

      if (success) {
        ErrorHandler.showSuccessSnackBar(
          context,
          widget.isCreate
              ? 'Tạo profile thành công!'
              : 'Cập nhật profile thành công!',
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
    isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(title: '', onBack: () => Navigator.pop(context)),
      body: SafeArea(
        top: false,
        bottom: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Galaxy Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppTheme.galaxyDarkest, AppTheme.galaxyDark]
                        : [Colors.grey.shade50, Colors.white],
                  ),
                ),
              ),
  
              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      SectionHeader.gradient(
                        icon: Icons.person,
                        title: widget.isCreate
                            ? 'Tạo Extended Profile'
                            : 'Chỉnh sửa Profile',
                        gradientColors: const [
                          AppTheme.themePurpleStart,
                          AppTheme.themePurpleEnd,
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
  
                      // Experience & Education Section
                      _buildExperienceAndEducationSection(),
                      const SizedBox(height: 24),
  
                      // Privacy Section
                      _buildPrivacySection(),
                      const SizedBox(height: 32),
  
                      // Save Button
                      _buildSaveButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
  
              // Loading Overlay
              if (_isLoading)
                Container(color: Colors.black54, child: CommonLoading.center()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cơ bản',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
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
            validator: (value) =>
                ValidationHelper.slug(value, isRequired: false),
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
              Text(
                'Liên kết mạng xã hội',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
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
            validator: (value) =>
                ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // GitHub
          _buildTextField(
            controller: _githubController,
            label: 'GitHub',
            hint: 'https://github.com/username',
            prefixIcon: Icons.code,
            keyboardType: TextInputType.url,
            validator: (value) =>
                ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // LinkedIn
          _buildTextField(
            controller: _linkedinController,
            label: 'LinkedIn',
            hint: 'https://linkedin.com/in/username',
            prefixIcon: Icons.business,
            keyboardType: TextInputType.url,
            validator: (value) =>
                ValidationHelper.linkedInUrl(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // Behance
          _buildTextField(
            controller: _behanceController,
            label: 'Behance',
            hint: 'https://behance.net/username',
            prefixIcon: Icons.palette,
            keyboardType: TextInputType.url,
            validator: (value) =>
                ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // Dribbble
          _buildTextField(
            controller: _dribbbleController,
            label: 'Dribbble',
            hint: 'https://dribbble.com/username',
            prefixIcon: Icons.sports_basketball,
            keyboardType: TextInputType.url,
            validator: (value) =>
                ValidationHelper.url(value, isRequired: false),
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
              const Icon(
                Icons.stars,
                color: AppTheme.themeOrangeStart,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Chuyên môn',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.themeOrangeStart,
                        AppTheme.themeOrangeEnd,
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
            Text(
              'Chưa có kỹ năng nào',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
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
                Text(
                  'Hiển thị công khai',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPublic
                      ? 'Profile của bạn có thể được mọi người xem'
                      : 'Chỉ bạn có thể xem profile này',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
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

  // ==================== EXPERIENCE & EDUCATION ====================

  Widget _buildExperienceAndEducationSection() {
    return Column(
      children: [
        // Years of experience
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.work_history,
                    color: AppTheme.themeBlueStart,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kinh nghiệm',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _yearsExpController,
                label: 'Số năm kinh nghiệm',
                hint: 'vd: 3',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kinh nghiệm làm việc',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddWorkExperienceDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.themeBlueStart,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (_workExperiences.isEmpty)
                Text(
                  'Chưa có kinh nghiệm làm việc',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._workExperiences.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final exp = entry.value;
                  return _buildWorkExpTile(exp, idx);
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Education
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.school,
                    color: AppTheme.themeOrangeStart,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Học vấn',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quá trình học tập',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddEducationDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.themeOrangeStart,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (_educationHistory.isEmpty)
                Text(
                  'Chưa có thông tin học vấn',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._educationHistory.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final edu = entry.value;
                  return _buildEducationTile(edu, idx);
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkExpTile(PortfolioWorkExperienceDto exp, int idx) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.themeBlueStart.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.themeBlueStart.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.business, size: 16, color: AppTheme.themeBlueStart),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.position ?? 'Vị trí',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  exp.companyName ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                if (exp.startDate != null)
                  Text(
                    '${exp.startDate} → ${exp.currentJob == true ? "Hiện tại" : (exp.endDate ?? "")}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _workExperiences.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTile(PortfolioEducationDto edu, int idx) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.themeOrangeStart.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school,
            size: 16,
            color: AppTheme.themeOrangeStart,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.degree ?? 'Bằng cấp',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  edu.institution ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                if (edu.fieldOfStudy != null)
                  Text(
                    edu.fieldOfStudy!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _educationHistory.removeAt(idx)),
          ),
        ],
      ),
    );
  }

  void _showAddWorkExperienceDialog() {
    final companyCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isCurrent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Thêm kinh nghiệm làm việc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty *',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: positionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vị trí *',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa điểm',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ngày bắt đầu (YYYY-MM)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                if (!isCurrent)
                  TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ngày kết thúc (YYYY-MM)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                Row(
                  children: [
                    Checkbox(
                      value: isCurrent,
                      onChanged: (v) =>
                          setDialogState(() => isCurrent = v ?? false),
                      activeColor: AppTheme.themeBlueStart,
                    ),
                    const Text('Đang làm việc tại đây', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (companyCtrl.text.trim().isEmpty ||
                    positionCtrl.text.trim().isEmpty) { return; }
                final exp = PortfolioWorkExperienceDto(
                  companyName: companyCtrl.text.trim(),
                  position: positionCtrl.text.trim(),
                  location: locationCtrl.text.trim().isEmpty
                      ? null
                      : locationCtrl.text.trim(),
                  startDate: startCtrl.text.trim().isEmpty
                      ? null
                      : startCtrl.text.trim(),
                  endDate: isCurrent || endCtrl.text.trim().isEmpty
                      ? null
                      : endCtrl.text.trim(),
                  currentJob: isCurrent,
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                );
                setState(() => _workExperiences.add(exp));
                Navigator.pop(ctx);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEducationDialog() {
    final institutionCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final fieldCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final statusCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm học vấn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: institutionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Trường học *',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: degreeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bằng cấp',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fieldCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ngành học',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: startCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ngày bắt đầu (YYYY-MM)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: endCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ngày kết thúc (YYYY-MM)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: statusCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tình trạng (vd: Đã tốt nghiệp)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (institutionCtrl.text.trim().isEmpty) return;
              final edu = PortfolioEducationDto(
                institution: institutionCtrl.text.trim(),
                degree: degreeCtrl.text.trim().isEmpty
                    ? null
                    : degreeCtrl.text.trim(),
                fieldOfStudy: fieldCtrl.text.trim().isEmpty
                    ? null
                    : fieldCtrl.text.trim(),
                location: locationCtrl.text.trim().isEmpty
                    ? null
                    : locationCtrl.text.trim(),
                startDate: startCtrl.text.trim().isEmpty
                    ? null
                    : startCtrl.text.trim(),
                endDate: endCtrl.text.trim().isEmpty
                    ? null
                    : endCtrl.text.trim(),
                status: statusCtrl.text.trim().isEmpty
                    ? null
                    : statusCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              );
              setState(() => _educationHistory.add(edu));
              Navigator.pop(ctx);
            },
            child: const Text('Thêm'),
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
        prefixIcon: Icon(
          prefixIcon,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        counterText: maxLength != null ? null : '',
        labelStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
      ),
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
                ? CommonLoading.small()
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
