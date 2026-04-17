import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_generate_provider.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/ai_generation_loading_view.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/selectable_chip_row.dart';
import '../../../data/models/roadmap_models.dart';
import 'package:go_router/go_router.dart';

class RoadmapGeneratePage extends StatefulWidget {
  const RoadmapGeneratePage({super.key});

  @override
  State<RoadmapGeneratePage> createState() => _RoadmapGeneratePageState();
}

class _RoadmapGeneratePageState extends State<RoadmapGeneratePage> {
  int _selectedModeIndex = 0;
  final _formKey = GlobalKey<FormState>();
  RoadmapGenerateProvider? _providerRef;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _providerRef = context.read<RoadmapGenerateProvider>();
      _providerRef!.addListener(_onProviderChanged);
      // Handle case where generation completed while user was away
      _onProviderChanged();
    });
  }

  @override
  void dispose() {
    _providerRef?.removeListener(_onProviderChanged);
    _goalController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final result = _providerRef?.lastResult;
    if (result != null) {
      _providerRef?.clearLastResult();
      context.go('/roadmap/${result.sessionId}');
    }
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
        child: Consumer<RoadmapGenerateProvider>(
          builder: (context, provider, child) {
            if (provider.isBusy) {
              return _buildLoadingState(context, provider.phase, isDark);
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
    return SelectableChipRow(
      labels: const ['Skill-Based', 'Career-Based'],
      icons: const [Icons.gps_fixed, Icons.work_outline],
      selectedIndex: _selectedModeIndex,
      onSelected: (i) => setState(() => _selectedModeIndex = i),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildGoalInput(BuildContext context, bool isDark) {
    final isSkillBased = _selectedModeIndex == 0;

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

  Widget _buildLoadingState(
    BuildContext context,
    GenerationPhase phase,
    bool isDark,
  ) {
    if (phase == GenerationPhase.validating) {
      return const AiGenerationLoadingView(
        speech: 'Meowl đang kiểm tra mục tiêu của bạn... 🔍',
        title: 'Đang kiểm tra yêu cầu',
        description: 'Xác thực mục tiêu học tập trước khi AI bắt đầu tạo lộ trình.',
        etaText: 'Chỉ mất vài giây',
        steps: [
          ('Phân tích mục tiêu', Icons.flag_outlined),
          ('Kiểm tra tính khả thi', Icons.verified_outlined),
        ],
      );
    }
    return const AiGenerationLoadingView(
      speech: 'Meowl đang vẽ lộ trình học tập cho bạn nè! 🗺️',
      title: 'Đang tạo lộ trình học tập',
      description:
          'Gemini AI đang phân tích mục tiêu và ghép các mốc học phù hợp với bạn.',
      etaText: 'Quá trình này có thể mất 30-60 giây',
      steps: [
        ('Đọc mục tiêu', Icons.flag_outlined),
        ('Phân tích AI', Icons.psychology_outlined),
        ('Xây lộ trình', Icons.route_outlined),
        ('Hoàn thiện', Icons.auto_awesome),
      ],
    );
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Vui lòng đăng nhập để tạo lộ trình',
      );
      context.push('/login');
      return;
    }

    final provider = context.read<RoadmapGenerateProvider>();

    final request = GenerateRoadmapRequest(
      goal: _goalController.text.trim(),
      duration: _selectedDuration,
      experience: _selectedExperience,
      style: _selectedStyle,
      roadmapMode: _selectedModeIndex == 0 ? 'SKILL_BASED' : 'CAREER_BASED',
      dailyTime: _dailyTime,
      background: _background,
      targetEnvironment: _targetEnvironment,
      skillName: _selectedModeIndex == 0 ? _goalController.text.trim() : null,
      targetRole: _selectedModeIndex == 1 ? _goalController.text.trim() : null,
    );

    // Single pipeline: validate → generate, loading screen appears immediately.
    // Navigation on success is handled by _onProviderChanged listener,
    // so Back + re-enter works correctly.
    provider.startFullGeneration(request);
  }
}
