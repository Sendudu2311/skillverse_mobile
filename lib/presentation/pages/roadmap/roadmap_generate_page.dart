import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../../data/models/roadmap_models.dart';
import 'package:go_router/go_router.dart';

class RoadmapGeneratePage extends StatefulWidget {
  const RoadmapGeneratePage({super.key});

  @override
  State<RoadmapGeneratePage> createState() => _RoadmapGeneratePageState();
}

class _RoadmapGeneratePageState extends State<RoadmapGeneratePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _goalController = TextEditingController();
  String _selectedDuration = '3 tháng';
  String _selectedExperience = 'Mới bắt đầu';
  String _selectedStyle = 'Video - Học qua hình ảnh';
  bool _showAdvancedOptions = false;
  String? _background;
  String? _dailyTime;
  String? _targetEnvironment;

  final List<String> _durationOptions = [
    '1 tháng',
    '3 tháng',
    '6 tháng',
    '1 năm',
  ];

  final List<String> _experienceOptions = [
    'Mới bắt đầu',
    'Trung cấp',
    'Nâng cao',
  ];

  final List<String> _styleOptions = [
    'Video - Học qua hình ảnh',
    'Thực hành - Học qua làm',
    'Đọc tài liệu - Tự nghiên cứu',
    'Kết hợp - Đa phương pháp',
  ];

  final List<String> _dailyTimeOptions = [
    '30 phút',
    '1 giờ',
    '2 giờ',
    '3+ giờ',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const SkillVerseAppBar(
        title: 'Tạo lộ trình học tập',
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<RoadmapProvider>(
          builder: (context, provider, child) {
            if (provider.isGenerating) {
              return _buildGeneratingState(context, isDark);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, isDark),
                    const SizedBox(height: 24),

                    // Mode tabs
                    _buildModeTabs(context, isDark),
                    const SizedBox(height: 24),

                    // Goal input
                    _buildGoalInput(context, isDark),
                    const SizedBox(height: 20),

                    // Duration selection
                    _buildDropdownField(
                      context,
                      label: 'Thời gian cam kết',
                      value: _selectedDuration,
                      items: _durationOptions,
                      onChanged: (v) => setState(() => _selectedDuration = v!),
                      icon: Icons.schedule_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Experience level
                    _buildDropdownField(
                      context,
                      label: 'Trình độ hiện tại',
                      value: _selectedExperience,
                      items: _experienceOptions,
                      onChanged: (v) =>
                          setState(() => _selectedExperience = v!),
                      icon: Icons.trending_up_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Learning style
                    _buildDropdownField(
                      context,
                      label: 'Phong cách học tập',
                      value: _selectedStyle,
                      items: _styleOptions,
                      onChanged: (v) => setState(() => _selectedStyle = v!),
                      icon: Icons.style_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Advanced options toggle
                    _buildAdvancedOptionsToggle(context, isDark),

                    // Advanced options
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 16),
                      _buildAdvancedOptions(context, isDark),
                    ],

                    // Validation results
                    if (provider.validationResults.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildValidationResults(
                        context,
                        provider.validationResults,
                        isDark,
                      ),
                    ],

                    // Error message
                    if (provider.generationError != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorMessage(
                        context,
                        provider.generationError!,
                        isDark,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Generate button
                    _buildGenerateButton(context, isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.2),
                    AppTheme.secondaryPurple.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Roadmap Generator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gemini AI sẽ tạo lộ trình học tập cá nhân hóa cho bạn',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildModeTabs(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '🎯 Skill-Based'),
          Tab(text: '💼 Career-Based'),
        ],
      ),
    );
  }

  Widget _buildGoalInput(BuildContext context, bool isDark) {
    final isSkillBased = _tabController.index == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSkillBased ? 'Kỹ năng muốn học' : 'Mục tiêu nghề nghiệp',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _goalController,
          maxLines: 3,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: isSkillBased
                ? 'Ví dụ: Python, ReactJS, IELTS, Graphic Design...'
                : 'Ví dụ: Data Scientist, Frontend Developer, Product Manager...',
            hintStyle: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
              ),
            ),
            prefixIcon: const Icon(Icons.flag_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mục tiêu học tập';
            }
            if (value.trim().length < 2) {
              return 'Mục tiêu quá ngắn, vui lòng mô tả chi tiết hơn';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    items: items
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: onChanged,
                    isExpanded: true,
                    dropdownColor: isDark ? AppTheme.galaxyMid : Colors.white,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsToggle(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
              color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'Tùy chọn nâng cao',
              style: TextStyle(
                color: isDark ? AppTheme.primaryBlueDark : AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily time
          _buildDropdownField(
            context,
            label: 'Thời gian học mỗi ngày',
            value: _dailyTime ?? '1 giờ',
            items: _dailyTimeOptions,
            onChanged: (v) => setState(() => _dailyTime = v),
            icon: Icons.timer_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Background
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kiến thức nền tảng (tùy chọn)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _background,
                onChanged: (v) => _background = v,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Ví dụ: Đã học cơ bản về lập trình, biết HTML/CSS...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationResults(
    BuildContext context,
    List<ValidationResult> results,
    bool isDark,
  ) {
    final warnings = results.where((r) => r.isWarning).toList();
    final errors = results.where((r) => r.isError).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lỗi',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 4),
                    child: Text(
                      '• ${e.message}',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (warnings.isNotEmpty) ...[
          if (errors.isNotEmpty) const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cảnh báo',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 4),
                    child: Text(
                      '• ${w.message}',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _onGenerate,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'Tạo lộ trình với Gemini AI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildGeneratingState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                  AppTheme.secondaryPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const CommonLoading(),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tạo lộ trình...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gemini AI đang phân tích và tạo lộ trình cá nhân hóa cho bạn',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quá trình này có thể mất 30-60 giây',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                  : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    // Check authentication
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ErrorHandler.showErrorSnackBar(context, 'Vui lòng đăng nhập để tạo lộ trình');
      context.push('/login');
      return;
    }

    final provider = context.read<RoadmapProvider>();

    // Clear previous results
    provider.clearValidationResults();
    provider.clearGenerationError();

    // Create request
    final request = GenerateRoadmapRequest(
      goal: _goalController.text.trim(),
      duration: _selectedDuration,
      experience: _selectedExperience,
      style: _selectedStyle,
      roadmapMode: _tabController.index == 0 ? 'SKILL_BASED' : 'CAREER_BASED',
      dailyTime: _dailyTime,
      background: _background,
      targetEnvironment: _targetEnvironment,
      // Map goal to specific fields based on mode
      skillName: _tabController.index == 0 ? _goalController.text.trim() : null,
      targetRole: _tabController.index == 1
          ? _goalController.text.trim()
          : null,
    );

    // Pre-validate
    final validationResults = await provider.preValidate(request);

    // Check for blocking errors
    final hasErrors = validationResults.any((r) => r.isError);
    if (hasErrors) {
      return; // Don't proceed if there are errors
    }

    // Generate roadmap
    final roadmap = await provider.generateRoadmap(request);

    if (roadmap != null && mounted) {
      // Navigate to the new roadmap detail
      context.go('/roadmap/${roadmap.sessionId}');
    }
  }
}
