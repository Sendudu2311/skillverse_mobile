import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/career_taxonomy_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/journey_models.dart';
import '../../../data/models/career_taxonomy_models.dart';

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
  late final CareerTaxonomyProvider _taxonomyProvider;

  // ── Step navigation ────────────────────────────────────────────────────────
  // Main step: 0 = SkillForm (domain→jobPosition→track), 1 = Config
  int _currentStep = 0;
  // Sub-step within step 0 (Taxonomy SkillForm)
  int _skillStep = 1; // 1: Domain, 2: JobPosition, 3: Track + Skills

  // ── Step 0: Journey type ─────────────────────────────────────────────────
  final JourneyType _selectedType = JourneyType.career;

  // ── Step 2: Config state ──────────────────────────────────────────────────
  String _selectedGoal = '';
  String _selectedLevel = 'BEGINNER';
  String _selectedLanguage = 'VI';
  String _selectedDuration = 'STANDARD';
  final List<String> _existingSkills = [];
  final _existingSkillCtrl = TextEditingController();

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

  bool get _canProceed {
    if (_currentStep == 0) {
      return switch (_skillStep) {
        1 => _taxonomyProvider.selectedDomainId != null,
        2 => _taxonomyProvider.selectedJobPositionId != null,
        3 => _taxonomyProvider.canProceed,
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
    _taxonomyProvider = context.read<CareerTaxonomyProvider>();
    _taxonomyProvider.loadDomains();
  }

  @override
  void dispose() {
    _journeyProvider.clearPendingJourneyForTestGeneration();
    _existingSkillCtrl.dispose();
    super.dispose();
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
    final tp = _taxonomyProvider;
    final selectedDomain = tp.selectedDomain;
    final selectedJobPosition = tp.selectedJobPosition;
    final selectedTrack = tp.selectedTrack;
    final skillNames = tp.selectedSkillNames;

    final request = StartJourneyRequest(
      type: _selectedType,
      domain: selectedDomain?.code ?? '',
      subCategory: selectedTrack?.name,
      jobRole: selectedJobPosition?.name,
      jobPositionId: selectedJobPosition?.id,
      jobPositionTrackId: selectedTrack?.id,
      skills: skillNames.isNotEmpty ? skillNames : null,
      existingSkills: _existingSkills.isNotEmpty ? _existingSkills : null,
      goal: _selectedGoal,
      level: _selectedLevel,
      language: _selectedLanguage,
      duration: _selectedDuration,
      questionCount: 50,
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
          body: Consumer<CareerTaxonomyProvider>(
            builder: (context, tp, child) {
              return Column(
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
              );
            },
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
                _subStepDot(2, 'Vị trí'),
                _subStepConnector(),
                _subStepDot(3, 'Track & Kỹ năng'),
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

    // Step 0 sub-steps (Taxonomy SkillForm)
    return Consumer<CareerTaxonomyProvider>(
      builder: (context, tp, _) {
        if (tp.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(tp.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => tp.loadDomains(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return switch (_skillStep) {
          1 => _buildDomainSelection(isDark, tp),
          2 => _buildJobPositionSelection(isDark, tp),
          3 => _buildTrackAndSkillsSelection(isDark, tp),
          _ => const SizedBox(),
        };
      },
    );
  }

  // ============================================================================
  // Step 1 — Sub-step 1: Domain (from Taxonomy API)
  // ============================================================================

  Widget _buildDomainSelection(bool isDark, CareerTaxonomyProvider tp) {
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
          'Danh sách được lấy từ taxonomy do admin quản lý.',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (tp.loadingDomains)
          const Center(child: CircularProgressIndicator())
        else if (tp.domains.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có lĩnh vực đang hoạt động.'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tp.domains.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final domain = tp.domains[index];
              final isSelected = tp.selectedDomainId == domain.id;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  tp.selectDomain(domain.id);
                  setState(() => _skillStep = 2);
                },
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
                      Icon(
                        Icons.layers,
                        size: 24,
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : (isDark
                                ? AppTheme.darkTextSecondary
                                : Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              domain.displayLabel,
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
                            if (domain.description != null &&
                                domain.description!.isNotEmpty)
                              Text(
                                domain.description!,
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
                      Icon(
                        Icons.chevron_right,
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : Colors.grey,
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
  // Step 1 — Sub-step 2: Job Position (from Taxonomy API)
  // ============================================================================

  Widget _buildJobPositionSelection(bool isDark, CareerTaxonomyProvider tp) {
    final selectedDomain = tp.selectedDomain;
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
          'Lĩnh vực đã chọn: ${selectedDomain?.displayLabel ?? ''}',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (tp.loadingJobs)
          const Center(child: CircularProgressIndicator())
        else if (tp.jobPositions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                  'Lĩnh vực này chưa có vị trí công việc đang hoạt động.'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tp.jobPositions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final job = tp.jobPositions[index];
              final isSelected = tp.selectedJobPositionId == job.id;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  tp.selectJobPosition(job.id);
                  setState(() => _skillStep = 3);
                },
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
                      Icon(
                        Icons.work_outline,
                        size: 24,
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : (isDark
                                ? AppTheme.darkTextSecondary
                                : Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.displayLabel,
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
                            if (job.description != null &&
                                job.description!.isNotEmpty)
                              Text(
                                job.description!,
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
                      Icon(
                        Icons.chevron_right,
                        color: isSelected
                            ? AppTheme.primaryBlueDark
                            : Colors.grey,
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
  // Step 1 — Sub-step 3: Track + Auto-loaded Skills
  // ============================================================================

  Widget _buildTrackAndSkillsSelection(bool isDark, CareerTaxonomyProvider tp) {
    final selectedJobPosition = tp.selectedJobPosition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn track mục tiêu',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Vị trí đã chọn: ${selectedJobPosition?.displayLabel ?? ''}',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        if (tp.loadingTracks)
          const Center(child: CircularProgressIndicator())
        else if (tp.tracks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                  'Vị trí này chưa có track mục tiêu đang hoạt động.'),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tp.tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final track = tp.tracks[index];
              final isSelected = tp.selectedTrackId == track.id;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => tp.selectTrack(track.id),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.displayLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppTheme.primaryBlueDark
                                    : (isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary),
                              ),
                            ),
                            if (track.description != null &&
                                track.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                track.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
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

        // ── Auto-loaded skills from selected track ──────────────────────────
        if (tp.selectedTrack != null) ...[
          const SizedBox(height: 24),
          Divider(
            color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'Kỹ năng tự động từ track',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Kỹ năng được lấy tự động từ taxonomy, không cần chỉnh sửa.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (tp.loadingSkills)
            const Center(child: CircularProgressIndicator())
          else if (tp.selectedSkillNames.isEmpty)
            Text(
              'Track này chưa có kỹ năng.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tp.trackSkills.map((skill) {
                final reqType = skill.requirementType;
                final IconData icon;
                final Color chipBg;
                final Color textColor;
                final String badge;
                switch (reqType) {
                  case RequirementType.required:
                    icon = Icons.check_circle;
                    chipBg = const Color(0xFF32d6ff).withValues(alpha: 0.12);
                    textColor = const Color(0xFF32d6ff);
                    badge = 'Bắt buộc';
                  case RequirementType.important:
                    icon = Icons.star;
                    chipBg = const Color(0xFFffb454).withValues(alpha: 0.12);
                    textColor = const Color(0xFFffb454);
                    badge = 'Quan trọng';
                  case RequirementType.niceToHave:
                    icon = Icons.lightbulb_outline;
                    chipBg = Colors.grey.withValues(alpha: 0.12);
                    textColor = Colors.grey.shade400;
                    badge = 'Khuyến khích';
                  case null:
                    icon = Icons.check;
                    chipBg = AppTheme.primaryBlueDark.withValues(alpha: 0.1);
                    textColor = AppTheme.primaryBlueDark;
                    badge = '';
                }
                return Chip(
                  avatar: Icon(icon, size: 14, color: textColor),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(skill.displayName),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  backgroundColor: chipBg,
                  labelStyle: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
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
          children: _taxonomyProvider.trackSkills.map((skill) {
            final reqType = skill.requirementType;
            final IconData icon;
            final Color chipBg;
            final Color textColor;
            final String badge;
            switch (reqType) {
              case RequirementType.required:
                icon = Icons.check_circle;
                chipBg = const Color(0xFF32d6ff).withValues(alpha: 0.12);
                textColor = const Color(0xFF32d6ff);
                badge = 'Bắt buộc';
              case RequirementType.important:
                icon = Icons.star;
                chipBg = const Color(0xFFffb454).withValues(alpha: 0.12);
                textColor = const Color(0xFFffb454);
                badge = 'Quan trọng';
              case RequirementType.niceToHave:
                icon = Icons.lightbulb_outline;
                chipBg = Colors.grey.withValues(alpha: 0.12);
                textColor = Colors.grey.shade400;
                badge = 'Khuyến khích';
              case null:
                icon = Icons.check;
                chipBg = AppTheme.primaryBlueDark.withValues(alpha: 0.1);
                textColor = AppTheme.primaryBlueDark;
                badge = '';
            }
            return Chip(
              avatar: Icon(icon, size: 14, color: textColor),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(skill.displayName),
                  if (badge.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: chipBg,
              labelStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            );
          }).toList(),
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
              _summaryRow('Lĩnh vực', _taxonomyProvider.selectedDomain?.displayLabel ?? ''),
              if (_taxonomyProvider.selectedJobPosition != null)
                _summaryRow('Vị trí', _taxonomyProvider.selectedJobPosition!.displayLabel),
              if (_taxonomyProvider.selectedTrack != null)
                _summaryRow('Track', _taxonomyProvider.selectedTrack!.displayLabel),
              _summaryRow(
                'Kỹ năng',
                _taxonomyProvider.selectedSkillNames.isEmpty
                    ? 'Chưa chọn'
                    : _taxonomyProvider.selectedSkillNames.join(', '),
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
        _taxonomyProvider.selectedSkillNames.contains(trimmed)) {
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
