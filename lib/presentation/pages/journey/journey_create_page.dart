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
import '../../../data/services/question_bank_service.dart';

class JourneyCompatibilityWarning {
  final String title;
  final List<String> lines;
  final String? ctaLabel;
  final String? ctaGoal;

  JourneyCompatibilityWarning({
    required this.title,
    required this.lines,
    this.ctaLabel,
    this.ctaGoal,
  });
}

JourneyCompatibilityWarning? _getJourneyCompatibilityWarning(String? goal, String? level) {
  if (goal == null || level == null) return null;

  if (goal == "REVIEW" && level == "BEGINNER") {
    return JourneyCompatibilityWarning(
      title: "Có vẻ bạn chưa có nền tảng với kỹ năng này",
      lines: [
        "Bạn có thể bắt đầu với lộ trình học từ đầu để đạt hiệu quả tốt hơn.",
        "Bạn vẫn có thể tiếp tục."
      ],
      ctaLabel: 'Chuyển sang "Học từ đầu"',
      ctaGoal: "FROM_SCRATCH",
    );
  }

  if (goal == "INTERNSHIP" && level == "BEGINNER") {
    return JourneyCompatibilityWarning(
      title: "Mục tiêu này thường cần thêm nền tảng",
      lines: [
        "Bạn có thể bắt đầu từ cơ bản và dần hướng tới internship.",
        "Bạn vẫn có thể tiếp tục."
      ],
    );
  }

  if (goal == "FROM_SCRATCH" && level == "INTERMEDIATE") {
    return JourneyCompatibilityWarning(
      title: "Bạn đã làm được dự án thực tế",
      lines: [
        "Lộ trình 'Học từ đầu' lúc này có thể dài hơn mức cần thiết.",
        "Bạn có thể tiết kiệm thời gian nếu chuyển sang lộ trình phù hợp hơn.",
        "Bạn vẫn có thể tiếp tục."
      ],
      ctaLabel: 'Chuyển sang "Tăng tốc lên cấp độ tiếp theo"',
      ctaGoal: "LEVEL_UP",
    );
  }

  if (goal == "FROM_SCRATCH" && level == "ADVANCED") {
    return JourneyCompatibilityWarning(
      title: "Bạn đã có thể xử lý công việc phức tạp",
      lines: [
        "Lộ trình 'Học từ đầu' lúc này có thể không còn tối ưu về thời gian.",
        "Bạn có thể tiết kiệm thời gian nếu chọn một lộ trình phù hợp hơn.",
        "Bạn vẫn có thể tiếp tục."
      ],
      ctaLabel: 'Chuyển sang "Tăng tốc lên cấp độ tiếp theo"',
      ctaGoal: "LEVEL_UP",
    );
  }

  if (goal == "CAREER_CHANGE" && (level == "INTERMEDIATE" || level == "ADVANCED")) {
    return JourneyCompatibilityWarning(
      title: "Bạn đã có nền tảng thực tế với kỹ năng này",
      lines: [
        "Bạn có thể phù hợp hơn với mục tiêu nâng cao hoặc phát triển chuyên sâu.",
        "Bạn vẫn có thể tiếp tục."
      ],
      ctaLabel: 'Chuyển sang "Tăng tốc lên cấp độ tiếp theo"',
      ctaGoal: "LEVEL_UP",
    );
  }

  return null;
}

class JourneyCreatePage extends StatefulWidget {
  const JourneyCreatePage({super.key});

  @override
  State<JourneyCreatePage> createState() => _JourneyCreatePageState();
}

class _JourneyCreatePageState extends State<JourneyCreatePage> {
  late final JourneyProvider _journeyProvider;

  // ── Step navigation ────────────────────────────────────────────────────────
  // Main step: 0 = SkillForm (domain→industry→role→skills), 1 = Config
  int _currentStep = 0;
  // Sub-step within step 0 (SkillForm)
  int _skillStep = 1; // 1: Domain, 2: Industry, 3: Role, 4: Skills

  // ── Step 0: Journey type ─────────────────────────────────────────────────
  final JourneyType _selectedType = JourneyType.skill;

  // ── Step 1: SkillForm state ───────────────────────────────────────────────
  String _selectedDomain = '';
  String _selectedIndustry = '';
  String _selectedJobRole = '';
  final List<String> _selectedSkills = [];
  final _customSkillCtrl = TextEditingController();
  bool _isResolvingSkill = false;

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
      case 'IT':
        return Icons.computer;
      case 'BUSINESS':
        return Icons.business;
      case 'DESIGN':
        return Icons.palette;
      default:
        return Icons.school;
    }
  }

  /// Convert display domain name from API → backend enum (IT / BUSINESS / DESIGN).
  static String _mapDomainToEnum(String domain) {
    final u = domain.toUpperCase();
    if (u == 'IT' || u.contains('INFORMATION') || u.contains('CÔNG NGHỆ')) {
      return 'IT';
    }
    if (u == 'BUSINESS' ||
        u.contains('KINH DOANH') ||
        u.contains('MARKETING')) {
      return 'BUSINESS';
    }
    if (u == 'DESIGN' || u.contains('THIẾT KẾ') || u.contains('SÁNG TẠO')) {
      return 'DESIGN';
    }
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
    {
      'value': 'EXPLORE',
      'label': 'Khám phá trình độ hiện tại',
      'desc': 'Đánh giá nhanh điểm mạnh, điểm yếu và xuất phát điểm',
    },
    {
      'value': 'INTERNSHIP',
      'label': 'Chuẩn bị cho internship / fresher job',
      'desc': 'Sẵn sàng ứng tuyển vị trí đầu sự nghiệp',
    },
    {
      'value': 'CAREER_CHANGE',
      'label': 'Chuyển ngành',
      'desc': 'Xác định khoảng cách năng lực và lộ trình chuyển đổi',
    },
    {
      'value': 'FROM_SCRATCH',
      'label': 'Xây lộ trình học từ đầu',
      'desc': 'Bắt đầu từ nền tảng với roadmap có thứ tự ưu tiên rõ ràng',
    },
    {
      'value': 'LEVEL_UP',
      'label': 'Tăng tốc lên cấp độ tiếp theo',
      'desc': 'Nâng tầm năng lực hiện tại để xử lý bài toán khó hơn',
    },
    {
      'value': 'REVIEW',
      'label': 'Ôn lại kiến thức',
      'desc': 'Rà soát kiến thức quan trọng trước kỳ thi hoặc phỏng vấn',
    },
  ];

  static const List<Map<String, String>> _levelOptions = [
    {
      'value': 'BEGINNER',
      'label': 'Beginner',
      'desc': 'Mới bắt đầu, chưa có kinh nghiệm',
    },
    {'value': 'ELEMENTARY', 'label': 'Elementary', 'desc': 'Có kiến thức cơ bản'},
    {
      'value': 'INTERMEDIATE',
      'label': 'Intermediate',
      'desc': 'Làm được dự án thực tế',
    },
    {'value': 'ADVANCED', 'label': 'Advanced', 'desc': 'Xử lý được công việc phức tạp'},
  ];



  // ── Computed ──────────────────────────────────────────────────────────────

  /// Keywords from selected role to suggest as skills.
  List<String> get _roleKeywordSuggestions {
    if (_selectedDomain.isEmpty ||
        _selectedIndustry.isEmpty ||
        _selectedJobRole.isEmpty) {
      return [];
    }
    try {
      final domainData = _expertFields.firstWhere(
        (e) => e.domain == _selectedDomain,
      );
      final industryData = domainData.industries.firstWhere(
        (e) => e.industry == _selectedIndustry,
      );
      final role = industryData.roles.firstWhere(
        (r) => r.jobRole == _selectedJobRole,
      );
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

  /// All unique skills across all domains/industries/roles
  List<String> get _allSystemSkills {
    final Set<String> allSkills = {};
    for (final domain in _expertFields) {
      for (final ind in domain.industries) {
        for (final role in ind.roles) {
          if (role.keywords != null && role.keywords!.isNotEmpty) {
            allSkills.addAll(
              role.keywords!
                  .split(',')
                  .map((k) => k.trim())
                  .where((k) => k.isNotEmpty),
            );
          }
        }
      }
    }
    return allSkills.toList()..sort();
  }

  bool get _canProceed {
    if (_currentStep == 0) {
      return switch (_skillStep) {
        1 => _selectedDomain.isNotEmpty,
        2 => _selectedIndustry.isNotEmpty,
        3 => _selectedJobRole.isNotEmpty && _selectedSkills.isNotEmpty,
        _ => false,
      };
    }
    // Step 1: goal required
    return _selectedGoal.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _journeyProvider = context.read<JourneyProvider>();
    _loadExpertFields();
  }

  @override
  void dispose() {
    _journeyProvider.clearPendingJourneyForTestGeneration();
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
      if (_skillStep < 3) {
        setState(() => _skillStep++);
      } else {
        setState(() => _currentStep = 1);
      }
    }
    // Step 1 next = submit (handled by button directly)
  }

  void _handleBack() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _skillStep = 3;
      });
    } else if (_currentStep == 0 && _skillStep > 1) {
      setState(() => _skillStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
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

    final journey = await _journeyProvider.startJourneyAndGenerateTest(request);

    if (journey != null && mounted) {
      context.push('/journey/${journey.id}');
    } else if (_journeyProvider.hasError && mounted) {
      ErrorHandler.showErrorSnackBar(
        context,
        _journeyProvider.errorMessage ?? 'Không thể tạo bài test lúc này',
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
                      'AI đang tạo hành trình và bài test',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng chờ trong giây lát.\nHệ thống đang khởi tạo Journey và chuẩn bị bài đánh giá đầu vào cho bạn.',
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
    const labels = ['Chọn Kỹ năng', 'Cấu hình test'];
    final connectorColor = isDark
        ? AppTheme.darkBorderColor
        : Colors.grey.shade300;

    final items = <Widget>[];
    for (int i = 0; i < 2; i++) {
      final step = i;
      final isActive = _currentStep >= step;
      final isCompleted = _currentStep > step;

      items.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isActive
                  ? AppTheme.primaryBlueDark
                  : connectorColor,
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

      if (i < 1) {
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
        // Sub-step breadcrumb for step 0 (SkillForm)
        if (_currentStep == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _subStepDot(1, 'Lĩnh vực'),
                _subStepConnector(),
                _subStepDot(2, 'Ngành'),
                _subStepConnector(),
                _subStepDot(3, 'Vị trí & Kỹ năng'),
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
    child: Container(width: 24, height: 1, color: Colors.grey.shade300),
  );

  // ============================================================================
  // Step Content Router
  // ============================================================================


  Widget _buildCurrentStepContent(bool isDark) {
    if (_currentStep == 1) return _buildStep2Config(isDark);

    // Step 1 sub-steps
    // Step 0 sub-steps (SkillForm)
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
      3 => _buildRoleAndSkillsSelection(isDark),
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

  // ============================================================================
  // Step 1 — Sub-step 3: Job Role + Skills (merged)
  // ============================================================================

  Widget _buildRoleAndSkillsSelection(bool isDark) {
    final roles = _rolesForIndustry(_selectedDomain, _selectedIndustry);
    final suggestions = _roleKeywordSuggestions
        .where((k) => !_selectedSkills.contains(k))
        .toList();

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
                onTap: () {
                  // Auto-fill skills from role keywords on selection
                  final keywords = role.keywords
                          ?.split(',')
                          .map((k) => k.trim())
                          .where((k) => k.isNotEmpty)
                          .toList() ??
                      [];
                  setState(() {
                    _selectedJobRole = role.jobRole;
                    _selectedSkills
                      ..clear()
                      ..addAll(keywords.take(3));
                  });
                },
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
                        : (isDark
                            ? AppTheme.darkCardBackground
                            : Colors.white),
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
                                          style:
                                              const TextStyle(fontSize: 10),
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

        // ── Inline skill section (shown after a role is selected) ────────────
        if (_selectedJobRole.isNotEmpty) ...[
          const SizedBox(height: 28),
          Divider(
            color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'Kỹ năng mục tiêu',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn hoặc chỉnh sửa kỹ năng bạn muốn phát triển',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          // Selected chips
          if (_selectedSkills.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                        fontWeight: FontWeight.w600,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      deleteIconColor: AppTheme.primaryBlueDark,
                      onDeleted: () =>
                          setState(() => _selectedSkills.remove(skill)),
                    ),
                  )
                  .toList(),
            ),
          ],
          // Suggestion chips (remaining keywords not yet selected)
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Thêm từ gợi ý:',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
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
          // Custom input
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillCtrl,
                  enabled: !_isResolvingSkill,
                  decoration: InputDecoration(
                    hintText: 'Thêm kỹ năng khác (VD: Java)...',
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
                onPressed: _isResolvingSkill ? null : _addCustomSkill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isResolvingSkill
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Thêm'),
              ),
            ],
          ),
          if (_selectedSkills.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '* Chọn ít nhất 1 kỹ năng để tiếp tục',
              style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _addCustomSkill() async {
    final trimmed = _customSkillCtrl.text.trim();
    if (trimmed.isEmpty || _selectedSkills.contains(trimmed)) return;
    
    // Check locally first if it matches exactly any system skill to avoid API call
    if (_allSystemSkills.any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      setState(() {
        _selectedSkills.add(trimmed);
        _customSkillCtrl.clear();
      });
      return;
    }

    setState(() => _isResolvingSkill = true);
    try {
      final res = await QuestionBankService().resolveSkill(trimmed);
      
      if (res.confidence >= 0.3 && res.skillName.isNotEmpty) {
        setState(() {
          _selectedSkills.add(res.skillName);
          _customSkillCtrl.clear();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kỹ năng không hợp lệ hoặc không nhận diện được.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('AI Resolve failed, falling back to manual add: $e');
      // If the API fails (e.g., 403 Forbidden or 404), fallback to allowing the user
      // to add the skill anyway, to prevent blocking the Journey creation flow.
      if (mounted) {
        setState(() {
          _selectedSkills.add(trimmed);
          _customSkillCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm kỹ năng (Bỏ qua AI kiểm duyệt do lỗi hệ thống).'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResolvingSkill = false);
      }
    }
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
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

        const SizedBox(height: 20),

        // ── Level ────────────────────────────────────────────────────────────
        _sectionLabel('Trình độ hiện tại'),
        const SizedBox(height: 10),
        ..._levelOptions.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selectedLevel = level['value']!),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedLevel == level['value']
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade300),
                    width: _selectedLevel == level['value'] ? 2 : 1,
                  ),
                  color: _selectedLevel == level['value']
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
                            level['label']!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            level['desc']!,
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
                    if (_selectedLevel == level['value'])
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

        // Cảnh báo tương thích
        Builder(builder: (context) {
          final warning = _getJourneyCompatibilityWarning(_selectedGoal, _selectedLevel);
          if (warning == null) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...warning.lines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 6),
                        child: Icon(
                          Icons.circle,
                          size: 4,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (warning.ctaLabel != null && warning.ctaGoal != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedGoal = warning.ctaGoal!;
                        });
                      },
                      child: Text(
                        warning.ctaLabel!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          );
        }),



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
                  backgroundColor: AppTheme.primaryBlueDark.withValues(
                    alpha: 0.1,
                  ),
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
                    onDeleted: () => setState(() => _existingSkills.remove(s)),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                _levelOptions.firstWhere(
                  (l) => l['value'] == _selectedLevel,
                )['label']!,
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
        _selectedSkills.contains(trimmed)) {
      return;
    }
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
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );



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
    final isLastStep = _currentStep == 1;
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
