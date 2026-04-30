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
  // ── Step navigation ────────────────────────────────────────────────────────
  // Main step: 0 = JourneyType, 1 = SkillForm (domain→industry→role→skills), 2 = Config
  int _currentStep = 0;
  // Sub-step within step 1
  int _skillStep = 1; // 1: Domain, 2: Industry, 3: Role, 4: Skills

  // ── Step 0: Journey type ─────────────────────────────────────────────────
  JourneyType _selectedType = JourneyType.skill;

  // ── Step 1: SkillForm state ───────────────────────────────────────────────
  String _selectedDomain = '';
  String _selectedIndustry = '';
  String _selectedJobRole = '';
  final List<String> _selectedSkills = [];
  final _customSkillCtrl = TextEditingController();

  // ── Step 2: Config state ──────────────────────────────────────────────────
  String _selectedGoal = '';
  String _selectedLevel = 'BEGINNER';
  String _selectedLanguage = 'VI';
  String _selectedDuration = 'STANDARD';
  final List<String> _existingSkills = [];
  final _existingSkillCtrl = TextEditingController();

  // ── Expert fields ─────────────────────────────────────────────────────────
  bool _isLoadingExpertFields = false;
  List<ExpertFieldResponse> _expertFields = [];
  String? _fieldsError;

  // ── Options ───────────────────────────────────────────────────────────────
  static const Map<String, String> _domainLabels = {
    'IT': 'Công nghệ thông tin',
    'BUSINESS': 'Kinh doanh',
    'DESIGN': 'Thiết kế',
  };

  static IconData _domainIcon(String enumVal) {
    switch (enumVal) {
      case 'IT': return Icons.computer;
      case 'BUSINESS': return Icons.business;
      case 'DESIGN': return Icons.palette;
      default: return Icons.school;
    }
  }

  /// Convert display domain name from API → backend enum (IT / BUSINESS / DESIGN).
  static String _mapDomainToEnum(String domain) {
    final u = domain.toUpperCase();
    if (u == 'IT' || u.contains('INFORMATION') || u.contains('CÔNG NGHỆ')) return 'IT';
    if (u == 'BUSINESS' || u.contains('KINH DOANH') || u.contains('MARKETING')) return 'BUSINESS';
    if (u == 'DESIGN' || u.contains('THIẾT KẾ') || u.contains('SÁNG TẠO')) return 'DESIGN';
    return u;
  }

  /// Aggregate all industries from API entries that map to [domainEnum].
  List<IndustryInfo> _industriesForDomain(String domainEnum) {
    final seen = <String>{};
    return _expertFields
        .where((f) => _mapDomainToEnum(f.domain) == domainEnum)
        .expand((f) => f.industries)
        .where((i) => seen.add(i.industry))
        .toList();
  }

  /// Aggregate roles for [industry] across all entries matching [domainEnum].
  List<RoleInfo> _rolesForIndustry(String domainEnum, String industry) {
    final seen = <String>{};
    return _expertFields
        .where((f) => _mapDomainToEnum(f.domain) == domainEnum)
        .expand((f) => f.industries)
        .where((i) => i.industry == industry)
        .expand((i) => i.roles)
        .where((r) => seen.add(r.jobRole))
        .toList();
  }

  static const List<Map<String, String>> _goalOptions = [
    {'value': 'EXPLORE', 'label': 'Khám phá ngành', 'desc': 'Tìm hiểu tổng quan về lĩnh vực'},
    {'value': 'INTERNSHIP', 'label': 'Chuẩn bị thực tập', 'desc': 'Sẵn sàng cho cơ hội thực tập'},
    {'value': 'CAREER_CHANGE', 'label': 'Chuyển ngành', 'desc': 'Chuyển sang lĩnh vực mới'},
    {'value': 'UPSKILL', 'label': 'Nâng cao kỹ năng', 'desc': 'Phát triển kỹ năng hiện tại'},
    {'value': 'FROM_SCRATCH', 'label': 'Bắt đầu từ đầu', 'desc': 'Học từ kiến thức cơ bản'},
  ];

  static const List<Map<String, String>> _levelOptions = [
    {'value': 'BEGINNER', 'label': 'Mới bắt đầu', 'desc': 'Chưa có kinh nghiệm'},
    {'value': 'ELEMENTARY', 'label': 'Sơ cấp', 'desc': 'Biết cơ bản'},
    {'value': 'INTERMEDIATE', 'label': 'Trung cấp', 'desc': '1-2 năm kinh nghiệm'},
    {'value': 'ADVANCED', 'label': 'Nâng cao', 'desc': '3+ năm kinh nghiệm'},
    {'value': 'EXPERT', 'label': 'Chuyên gia', 'desc': '5+ năm kinh nghiệm'},
  ];

  static const List<Map<String, String>> _durationOptions = [
    {'value': 'QUICK', 'label': 'Nhanh', 'desc': '~10 câu'},
    {'value': 'STANDARD', 'label': 'Tiêu chuẩn', 'desc': '~20 câu'},
    {'value': 'DEEP', 'label': 'Chuyên sâu', 'desc': '~30 câu'},
  ];

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Keywords from selected role to suggest as skills.
  List<String> get _roleKeywordSuggestions {
    if (_selectedDomain.isEmpty || _selectedIndustry.isEmpty || _selectedJobRole.isEmpty) {
      return [];
    }
    try {
      final domainData =
          _expertFields.firstWhere((e) => e.domain == _selectedDomain);
      final industryData =
          domainData.industries.firstWhere((e) => e.industry == _selectedIndustry);
      final role =
          industryData.roles.firstWhere((r) => r.jobRole == _selectedJobRole);
      if (role.keywords != null && role.keywords!.isNotEmpty) {
        return role.keywords!
            .split(',')
            .map((k) => k.trim())
            .where((k) => k.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  bool get _canProceed {
    if (_currentStep == 0) return true; // type always has a default
    if (_currentStep == 1) {
      return switch (_skillStep) {
        1 => _selectedDomain.isNotEmpty,
        2 => _selectedIndustry.isNotEmpty,
        3 => _selectedJobRole.isNotEmpty,
        4 => _selectedSkills.isNotEmpty,
        _ => false,
      };
    }
    // Step 2: goal required
    return _selectedGoal.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadExpertFields();
  }

  @override
  void dispose() {
    _customSkillCtrl.dispose();
    _existingSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExpertFields() async {
    setState(() => _isLoadingExpertFields = true);
    try {
      _expertFields = await ExpertChatService().getExpertFields();
      _fieldsError = null;
    } catch (_) {
      _fieldsError = 'Không thể tải danh sách ngành nghề';
    } finally {
      if (mounted) setState(() => _isLoadingExpertFields = false);
    }
  }

  void _handleNext() {
    if (!_canProceed) return;
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_skillStep < 4) {
        setState(() => _skillStep++);
      } else {
        setState(() => _currentStep = 2);
      }
    }
    // Step 2 next = submit (handled by button directly)
  }

  void _handleBack() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _skillStep = 4;
      });
    } else if (_currentStep == 1 && _skillStep > 1) {
      setState(() => _skillStep--);
    } else if (_currentStep == 1 && _skillStep == 1) {
      setState(() => _currentStep = 0);
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    final provider = context.read<JourneyProvider>();

    final request = StartJourneyRequest(
      type: _selectedType,
      domain: _mapDomainToEnum(_selectedDomain),
      industry: _selectedIndustry.isNotEmpty ? _selectedIndustry : null,
      subCategory: _selectedIndustry.isNotEmpty ? _selectedIndustry : null,
      jobRole: _selectedJobRole.isNotEmpty ? _selectedJobRole : null,
      skills: _selectedSkills.isNotEmpty ? _selectedSkills : null,
      existingSkills: _existingSkills.isNotEmpty ? _existingSkills : null,
      goal: _selectedGoal,
      level: _selectedLevel,
      language: _selectedLanguage,
      duration: _selectedDuration,
    );

    final journey = await provider.startJourney(request);

    if (journey != null && mounted) {
      context.push('/journey/${journey.id}');
    } else if (provider.hasError && mounted) {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Tạo hành trình thất bại',
      );
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
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
              _buildStepIndicator(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCurrentStepContent(isDark),
                ),
              ),
              _buildBottomNav(isDark),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // Step Indicator (2 steps)
  // ============================================================================

  Widget _buildStepIndicator(bool isDark) {
    const labels = ['Loại', 'Kỹ năng', 'Cấu hình'];
    final connectorColor =
        isDark ? AppTheme.darkBorderColor : Colors.grey.shade300;

    final items = <Widget>[];
    for (int i = 0; i < 3; i++) {
      final step = i;
      final isActive = _currentStep >= step;
      final isCompleted = _currentStep > step;

      items.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  isActive ? AppTheme.primaryBlueDark : connectorColor,
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary)
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      );

      if (i < 2) {
        items.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              color: _currentStep > step
                  ? AppTheme.primaryBlueDark
                  : connectorColor,
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
        // Sub-step breadcrumb for step 1
        if (_currentStep == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _subStepDot(1, 'Lĩnh vực'),
                _subStepConnector(),
                _subStepDot(2, 'Ngành'),
                _subStepConnector(),
                _subStepDot(3, 'Vị trí'),
                _subStepConnector(),
                _subStepDot(4, 'Kỹ năng'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _subStepDot(int step, String label) {
    final isActive = _skillStep >= step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryBlueDark : Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? AppTheme.primaryBlueDark : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _subStepConnector() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: 24,
          height: 1,
          color: Colors.grey.shade300,
        ),
      );

  // ============================================================================
  // Step Content Router
  // ============================================================================

  Widget _buildStep0JourneyType(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn loại hành trình',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn muốn phát triển theo hướng nào?',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildTypeCard(
          isDark: isDark,
          icon: Icons.auto_awesome,
          title: 'Học kỹ năng mới',
          description: 'Tập trung phát triển một kỹ năng cụ thể với lộ trình được cá nhân hóa.',
          isSelected: _selectedType == JourneyType.skill,
          onTap: () => setState(() => _selectedType = JourneyType.skill),
        ),
        const SizedBox(height: 12),
        _buildTypeCard(
          isDark: isDark,
          icon: Icons.trending_up,
          title: 'Phát triển sự nghiệp',
          description: 'Xây dựng lộ trình sự nghiệp toàn diện với nhiều kỹ năng phối hợp.',
          isSelected: _selectedType == JourneyType.career,
          onTap: () => setState(() => _selectedType = JourneyType.career),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected
        ? AppTheme.primaryBlueDark
        : (isDark ? AppTheme.darkBorderColor : Colors.grey.shade300);
    final bgColor = isSelected
        ? AppTheme.primaryBlueDark.withValues(alpha: 0.08)
        : (isDark ? AppTheme.darkCardBackground : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlueDark.withValues(alpha: 0.15)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryBlueDark : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
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
              const Icon(Icons.check_circle, color: AppTheme.primaryBlueDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    if (_currentStep == 0) return _buildStep0JourneyType(isDark);
    if (_currentStep == 2) return _buildStep2Config(isDark);

    // Step 1 sub-steps
    if (_isLoadingExpertFields && _skillStep > 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CommonLoading.center(),
        ),
      );
    }
    if (_fieldsError != null && _skillStep > 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(_fieldsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadExpertFields,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return switch (_skillStep) {
      1 => _buildDomainSelection(isDark),
      2 => _buildIndustrySelection(isDark),
      3 => _buildRoleSelection(isDark),
      4 => _buildSkillsSelection(isDark),
      _ => const SizedBox(),
    };
  }

  // ============================================================================
  // Step 1 — Sub-step 1: Domain
  // ============================================================================

  Widget _buildDomainSelection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn lĩnh vực',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Lĩnh vực bạn muốn học kỹ năng',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (_isLoadingExpertFields)
          const Center(child: CircularProgressIndicator())
        else if (_fieldsError != null)
          Text(_fieldsError!, style: const TextStyle(color: Colors.red))
        else if (_expertFields.isEmpty)
          const Text('Không có lĩnh vực nào.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.95,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _domainLabels.length,
            itemBuilder: (context, index) {
              final domain = _domainLabels.keys.elementAt(index);
              final isSelected = _selectedDomain == domain;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _selectedDomain = domain;
                  _selectedIndustry = '';
                  _selectedJobRole = '';
                  _selectedSkills.clear();
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
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _domainIcon(domain),
                          size: 28,
                          color: isSelected
                              ? AppTheme.primaryBlueDark
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _domainLabels[domain] ?? domain,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
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

  // ============================================================================
  // Step 1 — Sub-step 2: Industry
  // ============================================================================

  Widget _buildIndustrySelection(bool isDark) {
    final industries = _industriesForDomain(_selectedDomain);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ngành chi tiết',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Ngành bạn muốn học trong lĩnh vực ${_domainLabels[_selectedDomain] ?? _selectedDomain}',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (industries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không có ngành nào. Vui lòng chọn lĩnh vực khác.'),
            ),
          )
        else
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
                  _selectedSkills.clear();
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
                        Icon(Icons.check_circle,
                            color: AppTheme.primaryBlueDark, size: 20),
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
  // Step 1 — Sub-step 3: Job Role
  // ============================================================================

  Widget _buildRoleSelection(bool isDark) {
    final roles = _rolesForIndustry(_selectedDomain, _selectedIndustry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn vị trí công việc',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Vị trí bạn hướng đến trong ngành $_selectedIndustry',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (roles.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không có vị trí nào. Vui lòng chọn ngành khác.'),
            ),
          )
        else
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
                  _selectedSkills.clear();
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
                              role.jobRole,
                              style: const TextStyle(
                                fontSize: 15,
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                        Icon(Icons.check_circle,
                            color: AppTheme.primaryBlueDark, size: 24),
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
  // Step 1 — Sub-step 4: Skills
  // ============================================================================

  Widget _buildSkillsSelection(bool isDark) {
    final suggestions = _roleKeywordSuggestions
        .where((k) => !_selectedSkills.contains(k))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kỹ năng mục tiêu',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn ít nhất 1 kỹ năng bạn muốn phát triển',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        // Selected skills chips
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSkills
                .map(
                  (skill) => Chip(
                    label: Text(skill),
                    backgroundColor:
                        AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                        color: AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w600),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    deleteIconColor: AppTheme.primaryBlueDark,
                    onDeleted: () =>
                        setState(() => _selectedSkills.remove(skill)),
                  ),
                )
                .toList(),
          ),
        ],
        // Suggestions from role keywords
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Gợi ý từ vị trí ${_selectedJobRole.isNotEmpty ? _selectedJobRole : "đã chọn"}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (k) => ActionChip(
                    label: Text('+ $k'),
                    onPressed: () =>
                        setState(() => _selectedSkills.add(k)),
                    backgroundColor: isDark
                        ? AppTheme.darkCardBackground
                        : Colors.grey.shade100,
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        // Custom skill input
        Text(
          'Thêm kỹ năng khác',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSkillCtrl,
                decoration: InputDecoration(
                  hintText: 'Nhập tên kỹ năng...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _addCustomSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addCustomSkill,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
        if (_selectedSkills.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '* Chọn ít nhất 1 kỹ năng để tiếp tục',
            style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
          ),
        ],
      ],
    );
  }

  void _addCustomSkill() {
    final trimmed = _customSkillCtrl.text.trim();
    if (trimmed.isEmpty || _selectedSkills.contains(trimmed)) return;
    setState(() {
      _selectedSkills.add(trimmed);
      _customSkillCtrl.clear();
    });
  }

  // ============================================================================
  // Step 2: Config (Goal + Level + Language + Duration + Existing Skills)
  // ============================================================================

  Widget _buildStep2Config(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cấu hình bài đánh giá',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Hoàn thiện để AI tạo bài test phù hợp với bạn',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // ── Goal ────────────────────────────────────────────────────────────
        _sectionLabel('Mục tiêu chính'),
        const SizedBox(height: 10),
        ..._goalOptions.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedGoal = goal['value']!),
              child: Container(
                padding: const EdgeInsets.all(14),
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
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
                      Icon(Icons.check_circle,
                          color: AppTheme.primaryBlueDark, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Level ────────────────────────────────────────────────────────────
        _sectionLabel('Trình độ hiện tại'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _levelOptions.map((level) {
            final isSelected = _selectedLevel == level['value'];
            return ChoiceChip(
              label: Text(
                level['label']!,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : null,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryBlueDark,
              backgroundColor:
                  isDark ? AppTheme.darkCardBackground : Colors.grey.shade100,
              onSelected: (_) =>
                  setState(() => _selectedLevel = level['value']!),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // ── Duration ─────────────────────────────────────────────────────────
        _sectionLabel('Thời lượng bài test'),
        const SizedBox(height: 10),
        Row(
          children: _durationOptions.map((d) {
            final isSelected = _selectedDuration == d['value'];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _selectedDuration = d['value']!),
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
                            color: isSelected
                                ? AppTheme.primaryBlueDark
                                : null,
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

        // ── Language ─────────────────────────────────────────────────────────
        _sectionLabel('Ngôn ngữ bài test'),
        const SizedBox(height: 10),
        Row(
          children: [
            _langChip('VI', 'Tiếng Việt', isDark),
            const SizedBox(width: 8),
            _langChip('EN', 'English', isDark),
          ],
        ),

        const SizedBox(height: 20),

        // ── Target skills (read-only display) ────────────────────────────────
        _sectionLabel('Kỹ năng mục tiêu đang học'),
        const SizedBox(height: 8),
        Text(
          'Đây là kỹ năng bạn đã chọn ở bước trước.',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedSkills
              .map(
                (s) => Chip(
                  label: Text(s),
                  backgroundColor:
                      AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),

        // ── Existing skills ───────────────────────────────────────────────────
        _sectionLabel('Kỹ năng bạn đã có (tuỳ chọn)'),
        const SizedBox(height: 8),
        Text(
          'Thêm kỹ năng bạn đã nắm vững để AI đánh giá chính xác hơn.',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        if (_existingSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _existingSkills
                .map(
                  (s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        setState(() => _existingSkills.remove(s)),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _existingSkillCtrl,
                decoration: InputDecoration(
                  hintText: 'Nhập kỹ năng bạn đã biết...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _addExistingSkill(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addExistingSkill,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Summary ──────────────────────────────────────────────────────────
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _summaryRow('Lĩnh vực', _selectedDomain),
              if (_selectedIndustry.isNotEmpty)
                _summaryRow('Ngành', _selectedIndustry),
              if (_selectedJobRole.isNotEmpty)
                _summaryRow('Vị trí', _selectedJobRole),
              _summaryRow(
                'Kỹ năng',
                _selectedSkills.isEmpty
                    ? 'Chưa chọn'
                    : _selectedSkills.join(', '),
              ),
              if (_selectedGoal.isNotEmpty)
                _summaryRow(
                  'Mục tiêu',
                  _goalOptions.firstWhere(
                    (g) => g['value'] == _selectedGoal,
                    orElse: () => {'label': _selectedGoal},
                  )['label']!,
                ),
              _summaryRow(
                'Trình độ',
                _levelOptions
                    .firstWhere((l) => l['value'] == _selectedLevel)['label']!,
              ),
              _summaryRow(
                'Thời lượng',
                _durationOptions
                    .firstWhere((d) => d['value'] == _selectedDuration)['label']!,
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

  void _addExistingSkill() {
    final trimmed = _existingSkillCtrl.text.trim();
    if (trimmed.isEmpty ||
        _existingSkills.contains(trimmed) ||
        _selectedSkills.contains(trimmed)) return;
    setState(() {
      _existingSkills.add(trimmed);
      _existingSkillCtrl.clear();
    });
  }

  // ============================================================================
  // Reusable helpers
  // ============================================================================

  Widget _sectionLabel(String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      );

  Widget _langChip(String value, String label, bool isDark) {
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
    final isLastStep = _currentStep == 2;
    final showBack = _currentStep > 0 || _skillStep > 1;

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
            if (showBack)
              OutlinedButton.icon(
                onPressed: _handleBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Quay lại'),
              ),
            const Spacer(),
            if (!isLastStep)
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
