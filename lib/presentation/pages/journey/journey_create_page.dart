import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/journey_models.dart';
import '../../../data/models/expert_chat_models.dart';
import '../../../data/services/expert_chat_service.dart';

class JourneyCreatePage extends StatefulWidget {
  const JourneyCreatePage({super.key});

  @override
  State<JourneyCreatePage> createState() => _JourneyCreatePageState();
}

class _JourneyCreatePageState extends State<JourneyCreatePage> {
  // Form state
  JourneyType? _selectedType;
  String _selectedDomain = '';
  String _selectedIndustry = '';
  final String _selectedSubCategory = '';
  String _selectedJobRole = '';
  String _selectedRoleKeywords = '';
  String _selectedGoal = '';
  String _selectedLevel = 'BEGINNER';
  String _selectedLanguage = 'VI';
  String _selectedDuration = 'STANDARD';
  final List<String> _selectedSkills = [];

  int _currentStep = 1;
  int _careerStep = 1; // 1: Domain, 2: Industry, 3: Role
  bool _isLoadingExpertFields = false;
  List<ExpertFieldResponse> _expertFields = [];
  String? _fieldsError;

  @override
  void initState() {
    super.initState();
    _loadExpertFields();
  }

  Future<void> _loadExpertFields() async {
    setState(() => _isLoadingExpertFields = true);
    try {
      final service = ExpertChatService();
      _expertFields = await service.getExpertFields();
      _fieldsError = null;
    } catch (e) {
      _fieldsError = 'Không thể tải danh sách ngành nghề';
    } finally {
      if (mounted) setState(() => _isLoadingExpertFields = false);
    }
  }

  // Domain options (matching web)
  static const List<Map<String, dynamic>> _domainOptions = [
    {'value': 'IT', 'label': 'Công nghệ thông tin', 'icon': Icons.computer},
    {'value': 'DESIGN', 'label': 'Thiết kế', 'icon': Icons.palette},
    {'value': 'BUSINESS', 'label': 'Kinh doanh', 'icon': Icons.business},
    {'value': 'ENGINEERING', 'label': 'Kỹ thuật', 'icon': Icons.engineering},
    {'value': 'HEALTHCARE', 'label': 'Y tế', 'icon': Icons.health_and_safety},
    {'value': 'EDUCATION', 'label': 'Giáo dục', 'icon': Icons.school},
    {'value': 'FINANCE', 'label': 'Tài chính', 'icon': Icons.account_balance},
    {'value': 'MARKETING', 'label': 'Marketing', 'icon': Icons.campaign},
    {'value': 'SCIENCE', 'label': 'Khoa học', 'icon': Icons.science},
    {'value': 'ARTS', 'label': 'Nghệ thuật', 'icon': Icons.brush},
    {'value': 'LAW', 'label': 'Luật', 'icon': Icons.gavel},
    {'value': 'OTHER', 'label': 'Khác', 'icon': Icons.category},
  ];

  static const List<Map<String, String>> _goalOptions = [
    {
      'value': 'EXPLORE',
      'label': 'Khám phá ngành',
      'desc': 'Tìm hiểu tổng quan về lĩnh vực',
    },
    {
      'value': 'INTERNSHIP',
      'label': 'Chuẩn bị thực tập',
      'desc': 'Sẵn sàng cho cơ hội thực tập',
    },
    {
      'value': 'CAREER_CHANGE',
      'label': 'Chuyển ngành',
      'desc': 'Chuyển sang lĩnh vực mới',
    },
    {
      'value': 'UPSKILL',
      'label': 'Nâng cao kỹ năng',
      'desc': 'Phát triển kỹ năng hiện tại',
    },
    {
      'value': 'FROM_SCRATCH',
      'label': 'Bắt đầu từ đầu',
      'desc': 'Học từ kiến thức cơ bản',
    },
  ];

  static const List<Map<String, String>> _levelOptions = [
    {
      'value': 'BEGINNER',
      'label': 'Mới bắt đầu',
      'desc': 'Chưa có kinh nghiệm',
    },
    {'value': 'ELEMENTARY', 'label': 'Sơ cấp', 'desc': 'Biết cơ bản'},
    {
      'value': 'INTERMEDIATE',
      'label': 'Trung cấp',
      'desc': '1-2 năm kinh nghiệm',
    },
    {'value': 'ADVANCED', 'label': 'Nâng cao', 'desc': '3+ năm kinh nghiệm'},
    {'value': 'EXPERT', 'label': 'Chuyên gia', 'desc': '5+ năm kinh nghiệm'},
  ];

  static const List<Map<String, String>> _durationOptions = [
    {'value': 'QUICK', 'label': 'Nhanh', 'desc': '~10 câu'},
    {'value': 'STANDARD', 'label': 'Tiêu chuẩn', 'desc': '~20 câu'},
    {'value': 'DEEP', 'label': 'Chuyên sâu', 'desc': '~30 câu'},
  ];

  bool get _canProceed {
    switch (_currentStep) {
      case 1:
        return _selectedType != null;
      case 2:
        if (_selectedType == JourneyType.career) {
          if (_careerStep == 1) return _selectedDomain.isNotEmpty;
          if (_careerStep == 2) return _selectedIndustry.isNotEmpty;
          if (_careerStep == 3) return _selectedJobRole.isNotEmpty;
        }
        return _selectedDomain.isNotEmpty;
      case 3:
        return _selectedGoal.isNotEmpty;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_canProceed) {
      if (_currentStep == 2 &&
          _selectedType == JourneyType.career &&
          _careerStep < 3) {
        setState(() => _careerStep++);
      } else if (_currentStep < 4) {
        setState(() => _currentStep++);
      }
    }
  }

  void _handleBack() {
    if (_currentStep == 2 &&
        _selectedType == JourneyType.career &&
        _careerStep > 1) {
      setState(() => _careerStep--);
    } else if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        if (_currentStep == 1) _selectedType = null;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<JourneyProvider>();

    final request = StartJourneyRequest(
      type: _selectedType,
      domain: _selectedDomain,
      industry: _selectedIndustry.isNotEmpty ? _selectedIndustry : null,
      goal: _selectedGoal,
      level: _selectedLevel,
      subCategory: _selectedSubCategory.isNotEmpty
          ? _selectedSubCategory
          : null,
      jobRole: _selectedJobRole.isNotEmpty ? _selectedJobRole : null,
      skills: _selectedSkills.isNotEmpty ? _selectedSkills : null,
      language: _selectedLanguage,
      duration: _selectedDuration,
    );

    final journey = await provider.startJourney(request);

    if (journey != null && mounted) {
      context.go('/journey/${journey.id}');
    } else if (provider.hasError && mounted) {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Tạo hành trình thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        // Loading screen while creating journey + generating test
        if (provider.isCreating) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CommonLoading(size: 64, color: AppTheme.primaryBlueDark),
                    const SizedBox(height: 24),
                    Text(
                      'AI đang tạo bài test...',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng chờ trong giây lát.\nAI đang phân tích và tạo bài đánh giá phù hợp với bạn.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: SkillVerseAppBar(
            title: 'Tạo hành trình mới',
            onBack: _handleBack,
          ),
          body: Column(
            children: [
              // Step Indicator
              _buildStepIndicator(isDark),

              // Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStep(isDark),
                ),
              ),

              // Bottom Navigation
              _buildBottomNav(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final step = index + 1;
              final isActive = _currentStep >= step;
              final isCompleted = _currentStep > step;
              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isActive
                          ? AppTheme.primaryBlueDark
                          : (isDark
                                ? AppTheme.darkBorderColor
                                : Colors.grey.shade300),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '$step',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : Colors.grey,
                              ),
                            ),
                    ),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: _currentStep > step
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkBorderColor
                                    : Colors.grey.shade300),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Loại',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: Text(
                  'Lĩnh vực',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Mục tiêu',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Cấu hình',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 1:
        return _buildStep1TypeSelection(isDark);
      case 2:
        if (_selectedType == JourneyType.career) {
          if (_careerStep == 1) return _buildStep2DomainSelection(isDark);
          if (_careerStep == 2) return _buildStep2IndustrySelection(isDark);
          if (_careerStep == 3) return _buildStep2RoleSelection(isDark);
        }
        return _buildStep2DomainSelection(isDark);
      case 3:
        return _buildStep3GoalLevel(isDark);
      case 4:
        return _buildStep4Config(isDark);
      default:
        return const SizedBox();
    }
  }

  // ============================================================================
  // Step 1: Type Selection
  // ============================================================================

  Widget _buildStep1TypeSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn muốn làm gì?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn loại đánh giá phù hợp với bạn',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _buildTypeCard(
          type: JourneyType.career,
          icon: Icons.work_outline,
          title: 'Định hướng nghề nghiệp',
          desc:
              'Chọn ngành và vị trí công việc để đánh giá kỹ năng và nhận lộ trình phát triển sự nghiệp',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTypeCard(
          type: JourneyType.skill,
          icon: Icons.lightbulb_outline,
          title: 'Học kỹ năng mới',
          desc:
              'Nhập kỹ năng cụ thể bạn muốn học để nhận bài đánh giá và lộ trình học tập',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required JourneyType type,
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() {
        _selectedType = type;
        _currentStep = 2;
      }),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlueDark
                : (isDark ? AppTheme.darkBorderColor : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkCardBackground : Colors.white),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: AppTheme.primaryBlueDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlueDark,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForDomain(String domain) {
    final lower = domain.toLowerCase();
    if (lower.contains('information technology') ||
        lower.contains('công nghệ thông tin')) {
      return Icons.computer;
    }
    if (lower.contains('thiết kế') ||
        lower.contains('sáng tạo') ||
        lower.contains('design')) {
      return Icons.palette;
    }
    if (lower.contains('kinh doanh') ||
        lower.contains('marketing') ||
        lower.contains('quản trị') ||
        lower.contains('business')) {
      return Icons.business;
    }
    if (lower.contains('kỹ thuật') ||
        lower.contains('công nghiệp') ||
        lower.contains('sản xuất') ||
        lower.contains('engineering')) {
      return Icons.engineering;
    }
    if (lower.contains('healthcare') ||
        lower.contains('y tế') ||
        lower.contains('sức khỏe')) {
      return Icons.health_and_safety;
    }
    if (lower.contains('education') ||
        lower.contains('giáo dục') ||
        lower.contains('đào tạo') ||
        lower.contains('edtech')) {
      return Icons.school;
    }
    if (lower.contains('logistics')) return Icons.local_shipping;
    if (lower.contains('legal') ||
        lower.contains('pháp luật') ||
        lower.contains('law')) {
      return Icons.gavel;
    }
    if (lower.contains('arts') ||
        lower.contains('nghệ thuật') ||
        lower.contains('entertainment')) {
      return Icons.brush;
    }
    if (lower.contains('service') ||
        lower.contains('hospitality') ||
        lower.contains('dịch vụ')) {
      return Icons.room_service;
    }
    if (lower.contains('cộng đồng') || lower.contains('social')) {
      return Icons.public;
    }
    if (lower.contains('agriculture') ||
        lower.contains('nông nghiệp') ||
        lower.contains('môi trường') ||
        lower.contains('environment')) {
      return Icons.eco;
    }
    return Icons.explore;
  }

  // ============================================================================
  // Step 2: Domain / Industry / Role
  // ============================================================================

  Widget _buildStep2DomainSelection(bool isDark) {
    if (_isLoadingExpertFields) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CommonLoading.center(),
        ),
      );
    }

    if (_fieldsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(_fieldsError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final isCareer = _selectedType == JourneyType.career;
    final domains = isCareer
        ? _expertFields.map((e) => e.domain).toList()
        : _domainOptions.map((e) => e['value'] as String).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn lĩnh vực',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Lĩnh vực bạn muốn ${isCareer ? "theo đuổi nghề nghiệp" : "học kỹ năng"}',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.95,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: domains.length,
          itemBuilder: (context, index) {
            final domain = domains[index];
            final isSelected = _selectedDomain == domain;
            final label = isCareer
                ? domain
                : _domainOptions.firstWhere(
                        (e) => e['value'] == domain,
                      )['label']
                      as String;
            final icon = isCareer
                ? _getIconForDomain(domain)
                : _domainOptions.firstWhere((e) => e['value'] == domain)['icon']
                      as IconData;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _selectedDomain = domain;
                _selectedIndustry = '';
                _selectedJobRole = '';
                _selectedRoleKeywords = '';
              }),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                      : (isDark ? AppTheme.darkCardBackground : Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 28,
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:
                              11, // Giảm font size một chút vì label từ API có thể dài
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2IndustrySelection(bool isDark) {
    ExpertFieldResponse? domainData;
    try {
      domainData = _expertFields.firstWhere((e) => e.domain == _selectedDomain);
    } catch (_) {}

    final industries = domainData?.industries ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngành chi tiết',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn muốn học về ngành nào trong lĩnh vực $_selectedDomain?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: industries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final industry = industries[index].industry;
            final isSelected = _selectedIndustry == industry;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() {
                _selectedIndustry = industry;
                _selectedJobRole = '';
                _selectedRoleKeywords = '';
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                      : (isDark ? AppTheme.darkCardBackground : Colors.white),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        industry,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryBlueDark,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2RoleSelection(bool isDark) {
    ExpertFieldResponse? domainData;
    IndustryInfo? industryData;
    try {
      domainData = _expertFields.firstWhere((e) => e.domain == _selectedDomain);
      industryData = domainData.industries.firstWhere(
        (e) => e.industry == _selectedIndustry,
      );
    } catch (_) {}

    final roles = industryData?.roles ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn vị trí công việc',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn hướng đến vị trí nào trong ngành $_selectedIndustry?',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (roles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Không có vị trí nào. Vui lòng chọn ngành khác.',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final role = roles[index];
            final isSelected = _selectedJobRole == role.jobRole;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() {
                _selectedJobRole = role.jobRole;
                _selectedRoleKeywords = role.keywords ?? '';
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                      : (isDark ? AppTheme.darkCardBackground : Colors.white),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vị trí mục tiêu',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role.jobRole,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (role.keywords != null &&
                              role.keywords!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: role.keywords!
                                  .split(',')
                                  .take(3)
                                  .map(
                                    (k) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppTheme.darkBorderColor
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        k.trim(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryBlueDark,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================================
  // Step 3: Goal + Level
  // ============================================================================

  Widget _buildStep3GoalLevel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mục tiêu của bạn',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Goal Selection
        ..._goalOptions.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedGoal = goal['value']!),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedGoal == goal['value']
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade300),
                    width: _selectedGoal == goal['value'] ? 2 : 1,
                  ),
                  color: _selectedGoal == goal['value']
                      ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                      : (isDark ? AppTheme.darkCardBackground : Colors.white),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['label']!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal['desc']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedGoal == goal['value'])
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryBlueDark,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'Trình độ hiện tại',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Level Selection
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _levelOptions.map((level) {
            final isSelected = _selectedLevel == level['value'];
            return ChoiceChip(
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    level['label']!,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? Colors.white : null,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryBlueDark,
              backgroundColor: isDark
                  ? AppTheme.darkCardBackground
                  : Colors.grey.shade100,
              onSelected: (_) =>
                  setState(() => _selectedLevel = level['value']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================================
  // Step 4: Config + Summary
  // ============================================================================

  Widget _buildStep4Config(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cấu hình bài test',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Duration
        Text(
          'Độ sâu bài test',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: _durationOptions.map((d) {
            final isSelected = _selectedDuration == d['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedDuration = d['value']!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : (isDark
                                  ? AppTheme.darkBorderColor
                                  : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          d['label']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryBlueDark : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d['desc']!,
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
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Language
        Text(
          'Ngôn ngữ',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLangChip('VI', 'Tiếng Việt', isDark),
            const SizedBox(width: 8),
            _buildLangChip('EN', 'English', isDark),
          ],
        ),

        const SizedBox(height: 28),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark ? AppTheme.darkCardBackground : Colors.grey.shade50,
            border: Border.all(
              color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tóm tắt',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _summaryRow(
                'Loại',
                _selectedType == JourneyType.career ? 'Nghề nghiệp' : 'Kỹ năng',
              ),
              _summaryRow(
                'Lĩnh vực',
                _domainOptions.firstWhere(
                  (d) => d['value'] == _selectedDomain,
                  orElse: () => {'label': _selectedDomain},
                )['label'],
              ),
              _summaryRow(
                'Mục tiêu',
                _goalOptions.firstWhere(
                  (g) => g['value'] == _selectedGoal,
                  orElse: () => {'label': _selectedGoal},
                )['label']!,
              ),
              _summaryRow(
                'Trình độ',
                _levelOptions.firstWhere(
                  (l) => l['value'] == _selectedLevel,
                )['label']!,
              ),
              _summaryRow(
                'Thời lượng',
                _durationOptions.firstWhere(
                  (d) => d['value'] == _selectedDuration,
                )['label']!,
              ),
              _summaryRow(
                'Ngôn ngữ',
                _selectedLanguage == 'VI' ? 'Tiếng Việt' : 'English',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String value, String label, bool isDark) {
    final isSelected = _selectedLanguage == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedLanguage = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlueDark
                  : (isDark ? AppTheme.darkBorderColor : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primaryBlueDark : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Bottom Navigation
  // ============================================================================

  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 1)
              OutlinedButton.icon(
                onPressed: _handleBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Quay lại'),
              ),
            const Spacer(),
            if (_currentStep < 4)
              ElevatedButton.icon(
                onPressed: _canProceed ? _handleNext : null,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Tiếp theo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _canProceed ? _handleSubmit : null,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Tạo bài test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
