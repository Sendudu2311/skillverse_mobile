import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/task_board_provider.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/journey_models.dart';
import '../../../data/services/journey_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/ai_generation_loading_view.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/skillverse_app_bar.dart';
import 'widgets/evaluation_result_dialog.dart';

class JourneyDetailPage extends StatefulWidget {
  final String journeyId;

  const JourneyDetailPage({super.key, required this.journeyId});

  @override
  State<JourneyDetailPage> createState() => _JourneyDetailPageState();
}

class _JourneyDetailPageState extends State<JourneyDetailPage> {
  // Test-taking state
  final Map<String, String> _answers = {};
  List<dynamic>? _loadedQuestions;
  bool _isLoadingQuestions = false;
  String? _loadQuestionsError;
  int _currentQuestionIndex = 0;
  final Set<int> _bookmarkedQuestions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJourneyAndQuestions();
    });
  }

  Future<void> _loadJourneyAndQuestions() async {
    final id = int.tryParse(widget.journeyId);
    if (id == null) return;

    final provider = context.read<JourneyProvider>();
    await provider.loadJourneyById(id);

    final journey = provider.currentJourney;
    if (journey == null) return;

    if (_loadedQuestions == null && journey.assessmentTestId != null) {
      await _loadQuestions(journey.id, journey.assessmentTestId!);
    }
  }

  Future<void> _loadQuestions(int journeyId, int testId) async {
    if (_isLoadingQuestions) return;
    setState(() {
      _isLoadingQuestions = true;
      _loadQuestionsError = null;
    });
    try {
      final test = await context.read<JourneyProvider>().getAssessmentTest(
        journeyId: journeyId,
        testId: testId,
      );
      if (test?.questionsJson != null && mounted) {
        setState(() {
          try {
            _loadedQuestions = jsonDecode(test!.questionsJson!);
          } catch (_) {}
          // Restore saved answers from backend (resume in-progress test)
          if (test!.userAnswersJson != null && _answers.isEmpty) {
            try {
              final parsed =
                  jsonDecode(test.userAnswersJson!) as Map<String, dynamic>;
              parsed.forEach((key, value) {
                if (value is String) {
                  _answers[key] = value;
                }
              });
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadQuestionsError = ErrorHandler.getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  void _loadJourney() {
    final id = int.tryParse(widget.journeyId);
    if (id != null) {
      context.read<JourneyProvider>().loadJourneyById(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<JourneyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentJourney == null) {
          return Scaffold(
            appBar: SkillVerseAppBar(
              title: 'Hành trình',
              onBack: () => context.go('/journey'),
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                CardSkeleton(imageHeight: null),
                SizedBox(height: 8),
                CardSkeleton(imageHeight: null, hasFooter: false),
                SizedBox(height: 8),
                CardSkeleton(imageHeight: null, hasSubtitle: false),
              ],
            ),
          );
        }

        if (provider.hasError && provider.currentJourney == null) {
          return Scaffold(
            appBar: SkillVerseAppBar(
              title: 'Hành trình',
              onBack: () => context.go('/journey'),
            ),
            body: ErrorStateWidget(
              message: provider.errorMessage ?? 'Đã xảy ra lỗi',
              onRetry: _loadJourney,
            ),
          );
        }

        final journey = provider.currentJourney;
        if (journey == null) {
          return Scaffold(
            appBar: SkillVerseAppBar(
              title: 'Hành trình',
              onBack: () => context.go('/journey'),
            ),
            body: const Center(child: Text('Không tìm thấy hành trình')),
          );
        }

        // ── Intercept back navigation when test is in progress ──
        final isTestInProgress = journey.status == JourneyStatus.testInProgress;
        return PopScope(
          canPop: !isTestInProgress || _answers.isEmpty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            // Only fires when canPop == false (test in progress with answers)
            if (!context.mounted) return;
            final leave = await showDialog<bool>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Thoát bài test?'),
                content: const Text(
                  'Tiến trình đã được lưu tự động.\nBạn có thể quay lại làm tiếp sau.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: const Text('Ở lại làm bài'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Thoát'),
                  ),
                ],
              ),
            );
            if (leave == true && context.mounted) {
              context.go('/journey');
            }
          },
          child: Scaffold(
            appBar: SkillVerseAppBar(
              title: journey.domain,
              onBack: () async {
                if (!isTestInProgress || _answers.isEmpty) {
                  context.go('/journey');
                  return;
                }
                final leave = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Thoát bài test?'),
                    content: const Text(
                      'Tiến trình đã được lưu tự động.\nBạn có thể quay lại làm tiếp sau.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(false),
                        child: const Text('Ở lại làm bài'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Thoát'),
                      ),
                    ],
                  ),
                );
                if (leave == true && context.mounted) {
                  context.go('/journey');
                }
              },
              actions: _buildActions(context, journey),
            ),
            body: RefreshIndicator(
              onRefresh: () async => _loadJourney(),
              child: SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      _buildStatusHeader(context, journey, isDark),
                      const SizedBox(height: 20),

                      // Main Content based on status
                      _buildContentByStatus(context, journey, provider, isDark),

                      // Milestones
                      if (journey.milestones != null &&
                          journey.milestones!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildMilestones(context, journey.milestones!, isDark),
                      ],

                      // Final Verification CTA
                      if (journey.finalVerificationRequired == true &&
                          (journey.status ==
                                  JourneyStatus.awaitingVerification ||
                              journey.status ==
                                  JourneyStatus.completedUnverified)) ...[
                        const SizedBox(height: 20),
                        _buildVerificationCta(context, journey),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ), // end Scaffold
        ); // end PopScope
      }, // end Consumer builder
    ); // end Consumer
  }

  List<Widget> _buildActions(BuildContext context, JourneySummaryDto journey) {
    final List<PopupMenuEntry<String>> menuItems = [];

    if (journey.status == JourneyStatus.active) {
      menuItems.addAll([
        const PopupMenuItem<String>(
          value: 'pause',
          child: ListTile(
            leading: Icon(Icons.pause_circle_outline),
            title: Text('Tạm dừng'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'complete',
          child: ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Hoàn thành'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'cancel',
          child: ListTile(
            leading: Icon(Icons.cancel_outlined, color: Colors.orange),
            title: Text('Hủy', style: TextStyle(color: Colors.orange)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
      ]);
    }

    menuItems.add(
      const PopupMenuItem<String>(
        value: 'delete',
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: Colors.red),
          title: Text('Xóa', style: TextStyle(color: Colors.red)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    );

    return [
      if (journey.status == JourneyStatus.paused)
        IconButton(
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Tiếp tục',
          onPressed: () async {
            final provider = context.read<JourneyProvider>();
            await provider.resumeJourney(journey.id);
            if (!context.mounted) return;
            if (provider.hasError) {
              ErrorHandler.showErrorSnackBar(
                context,
                provider.errorMessage ?? 'Tiếp tục hành trình thất bại',
              );
            } else {
              ErrorHandler.showSuccessSnackBar(
                context,
                'Đã tiếp tục hành trình',
              );
            }
          },
        ),
      PopupMenuButton<String>(
        onSelected: (value) async {
          final provider = context.read<JourneyProvider>();
          final taskBoardProvider = context.read<TaskBoardProvider>();
          switch (value) {
            case 'pause':
              await provider.pauseJourney(journey.id);
              if (context.mounted && provider.hasError) {
                ErrorHandler.showErrorSnackBar(
                  context,
                  provider.errorMessage ?? 'Tạm dừng hành trình thất bại',
                );
              } else {
                taskBoardProvider.loadBoard(); // Sync archived tasks
                if (context.mounted) {
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Đã tạm dừng hành trình. Lưu ý: Lịch hẹn với Mentor vẫn diễn ra theo kế hoạch.',
                  );
                }
              }
              break;
            case 'complete':
              await provider.completeJourney(journey.id);
              if (context.mounted && provider.hasError) {
                final msg = provider.errorMessage ?? '';
                // 409: Gate blocked — journey chưa đạt final verification gate
                if (msg.contains('409') ||
                    msg.toLowerCase().contains('gate') ||
                    msg.toLowerCase().contains('chưa đạt')) {
                  ErrorHandler.showWarningSnackBar(
                    context,
                    'Hành trình chưa đạt final verification gate. Vui lòng hoàn thành xác thực trước.',
                  );
                } else {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    msg.isNotEmpty ? msg : 'Không thể hoàn thành hành trình',
                  );
                }
              } else if (context.mounted) {
                ErrorHandler.showSuccessSnackBar(
                  context,
                  'Đã hoàn thành hành trình 🎉',
                );
              }
              break;
            case 'cancel':
              if (journey.hasActiveMentorBooking == true) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Không thể hủy'),
                      content: const Text(
                        'Bạn đang có lịch booking mentor đang hoạt động cho hành trình này. Vui lòng giải quyết booking trước khi hủy.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đã hiểu'),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }
              final confirmed = await _showConfirmDialog(
                context,
                'Hủy hành trình',
                'Nếu hành trình đang có lịch hẹn với Mentor, các lịch hẹn đó cũng sẽ bị ảnh hưởng.\n\nBạn có chắc muốn hủy hành trình này?',
              );
              if (confirmed == true) {
                await provider.cancelJourney(journey.id);
                if (context.mounted && provider.hasError) {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    provider.errorMessage ?? 'Hủy hành trình thất bại',
                  );
                } else {
                  taskBoardProvider.loadBoard(); // Sync archived tasks
                  if (context.mounted) {
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      'Đã hủy hành trình',
                    );
                  }
                }
              }
              break;
            case 'delete':
              if (journey.hasActiveMentorBooking == true) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Không thể xóa'),
                      content: const Text(
                        'Bạn đang có lịch booking mentor đang hoạt động cho hành trình này. Bạn cần hoàn thành lộ trình học và giải phóng tiền cho mentor trước.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đã hiểu'),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }
              final confirmedDelete = await _showConfirmDialog(
                context,
                'Xóa hành trình',
                'Bạn có chắc muốn xóa hành trình này? Hành động này không thể hoàn tác.',
              );
              if (confirmedDelete == true) {
                final result = await provider.deleteJourney(journey.id);
                taskBoardProvider.loadBoard(); // Sync deleted tasks
                if (result && context.mounted) {
                  context.go('/journey');
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Đã xóa hành trình',
                  );
                } else if (context.mounted && provider.errorMessage != null) {
                  ErrorHandler.showErrorSnackBar(
                    context,
                    provider.errorMessage!,
                  );
                }
              }
              break;
          }
        },
        itemBuilder: (context) => menuItems,
      ),
    ];
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Status Header
  // ============================================================================

  Widget _buildStatusHeader(
    BuildContext context,
    JourneySummaryDto journey,
    bool isDark,
  ) {
    final String mainTitle = journey.type == 'SKILL'
        ? (journey.skillName ?? journey.domain)
        : (journey.jobRole ?? journey.domain);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                  AppTheme.accentCyan.withValues(alpha: 0.1),
                ]
              : [
                  AppTheme.primaryBlueDark.withValues(alpha: 0.08),
                  AppTheme.accentCyan.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore, color: AppTheme.primaryBlueDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mainTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getGoalLabel(journey.goal),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // Progress
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: journey.progressPercentage / 100,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlueDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${journey.progressPercentage}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _infoChip(journey.domain, Icons.category, isDark),
              if (journey.currentLevel != null)
                _infoChip(
                  _getLevelLabel(journey.currentLevel!),
                  Icons.bar_chart,
                  isDark,
                ),
              if (journey.type != null)
                _infoChip(
                  journey.type == 'CAREER' ? 'Nghề nghiệp' : 'Kỹ năng',
                  Icons.flag,
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryBlueDark),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================================================
  // Content By Status
  // ============================================================================

  Widget _buildContentByStatus(
    BuildContext context,
    JourneySummaryDto journey,
    JourneyProvider provider,
    bool isDark,
  ) {
    switch (journey.status) {
      case JourneyStatus.notStarted:
      case JourneyStatus.assessmentPending:
        return _buildAssessmentPending(context, journey, provider, isDark);

      case JourneyStatus.testInProgress:
        return _buildTestInProgress(context, journey, provider, isDark);

      case JourneyStatus.evaluationPending:
        return _buildEvaluationResult(context, journey, provider, isDark);

      case JourneyStatus.roadmapGenerated:
        return _buildRoadmapReady(context, journey, provider, isDark);

      case JourneyStatus.studyPlanInProgress:
      case JourneyStatus.active:
        return _buildActive(context, journey, isDark);

      case JourneyStatus.completed:
      case JourneyStatus.completedVerified:
        return _buildCompleted(context, journey, isDark);

      case JourneyStatus.completedUnverified:
      case JourneyStatus.awaitingVerification:
        return _buildCompleted(context, journey, isDark);

      case JourneyStatus.paused:
        return _buildPaused(context, journey, isDark);

      case JourneyStatus.cancelled:
        return _buildCancelled(context, isDark);
    }
  }

  // --- Assessment Pending ---
  Widget _buildAssessmentPending(
    BuildContext context,
    JourneySummaryDto journey,
    JourneyProvider provider,
    bool isDark,
  ) {
    final isGenerating = provider.isLoadingFor('generateTest');

    // Show auto-generating UI when Provider is generating test in background
    if (journey.assessmentTestId == null && provider.isAutoGenerating) {
      return _sectionCard(
        isDark: isDark,
        icon: Icons.auto_awesome,
        title: 'AI đang tạo bài test...',
        child: Column(
          children: [
            const SizedBox(height: 8),
            const AiGenerationLoadingView(
              speech: 'Meowl đang soạn bài đánh giá mở màn cho bạn nè! 🧪',
              title: 'Đang tạo bài test đầu vào',
              description:
                  'AI đang phân tích lĩnh vực để tạo bộ câu hỏi phù hợp với hành trình của bạn.',
              etaText: 'Thường mất khoảng 20-40 giây',
              steps: [
                ('Đọc lĩnh vực', Icons.travel_explore_outlined),
                ('Phân tích AI', Icons.psychology_outlined),
                ('Soạn câu hỏi', Icons.quiz_outlined),
                ('Sẵn sàng', Icons.check_circle_outline),
              ],
              avatarSize: 96,
              topSpacing: 8,
              padding: EdgeInsets.zero,
              useSafeArea: false,
              scrollable: false,
            ),
            if (provider.hasError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage ?? 'Tạo bài test thất bại',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  provider.autoGenerateTestIfNeeded(journey.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueDark,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isGenerating) {
      return _sectionCard(
        isDark: isDark,
        icon: Icons.auto_awesome,
        title: 'AI đang tạo bài test...',
        child: const AiGenerationLoadingView(
          speech: 'Meowl đang dựng bài test cho bạn ngay đây! ✨',
          title: 'Đang tạo bài test AI',
          description:
              'AI đang chọn độ khó và biên soạn câu hỏi đánh giá phù hợp với năng lực hiện tại.',
          etaText: 'Thường mất khoảng 20-40 giây',
          steps: [
            ('Đọc mục tiêu', Icons.flag_outlined),
            ('Phân tích mức độ', Icons.insights_outlined),
            ('Tạo câu hỏi', Icons.quiz_outlined),
            ('Hoàn thiện', Icons.check_circle_outline),
          ],
          avatarSize: 96,
          topSpacing: 8,
          padding: EdgeInsets.zero,
          useSafeArea: false,
          scrollable: false,
        ),
      );
    }

    return _sectionCard(
      isDark: isDark,
      icon: Icons.quiz,
      title: 'Bài đánh giá',
      child: Column(
        children: [
          if (journey.assessmentTestId != null) ...[
            Text(
              'Bài test đã được tạo sẵn sàng!',
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                _loadJourney();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Bắt đầu làm bài'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            Text(
              'AI sẽ tạo bài test đánh giá kỹ năng phù hợp với lĩnh vực của bạn.',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isGenerating
                  ? null
                  : () async {
                      try {
                        await provider.generateTest(journey.id);
                        if (mounted) _loadJourney();
                      } catch (e) {
                        if (context.mounted) {
                          ErrorHandler.showErrorSnackBar(
                            context,
                            e.toString().replaceAll('Exception: ', ''),
                          );
                        }
                      }
                    },
              icon: isGenerating
                  ? CommonLoading.button()
                  : const Icon(Icons.auto_awesome),
              label: Text(isGenerating ? 'Đang tạo...' : 'Tạo bài test AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Test In Progress ---
  Widget _buildTestInProgress(
    BuildContext context,
    JourneySummaryDto journey,
    JourneyProvider provider,
    bool isDark,
  ) {
    final isSubmitting = provider.isLoadingFor('submitTest');

    // ── Full-screen overlay while AI is evaluating ──
    if (isSubmitting) {
      return _sectionCard(
        isDark: isDark,
        icon: Icons.psychology,
        title: 'AI đang chấm bài...',
        child: const AiGenerationLoadingView(
          speech: 'Meowl đang chấm bài cho bạn, chờ xíu nha! 📝',
          title: 'Đang đánh giá kết quả',
          description:
              'AI đang phân tích câu trả lời, đánh giá năng lực và tạo báo cáo chi tiết.',
          etaText: 'Thường mất khoảng 15-30 giây',
          steps: [
            ('Nhận bài', Icons.inbox_outlined),
            ('Phân tích', Icons.analytics_outlined),
            ('Đánh giá', Icons.grading_outlined),
            ('Hoàn tất', Icons.check_circle_outline),
          ],
          avatarSize: 96,
          topSpacing: 8,
          padding: EdgeInsets.zero,
          useSafeArea: false,
          scrollable: false,
        ),
      );
    }

    // Parse questions from state or generated test
    List<dynamic> questions = _loadedQuestions ?? [];
    if (questions.isEmpty && provider.generatedTest?.questionsJson != null) {
      try {
        questions = jsonDecode(provider.generatedTest!.questionsJson!);
      } catch (_) {}
    }

    if (questions.isEmpty && journey.assessmentTestId != null) {
      // Error state — show retry button
      if (_loadQuestionsError != null) {
        return _sectionCard(
          isDark: isDark,
          icon: Icons.error_outline,
          title: 'Không thể tải bài test',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  _loadQuestionsError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.red[300] : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      _loadQuestions(journey.id, journey.assessmentTestId!),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        );
      }
      // Auto-trigger nếu chưa loading
      if (!_isLoadingQuestions) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _loadedQuestions == null) {
            _loadQuestions(journey.id, journey.assessmentTestId!);
          }
        });
      }
      return _sectionCard(
        isDark: isDark,
        icon: Icons.edit_note,
        title: 'Đang tải bài test...',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CommonLoading.center(),
        ),
      );
    }

    if (questions.isEmpty) {
      return _sectionCard(
        isDark: isDark,
        icon: Icons.pending,
        title: 'Đang chờ',
        child: const Text('Đang tải câu hỏi bài test...'),
      );
    }

    // ── Single-question-at-a-time view ──
    final totalQ = questions.length;
    // Clamp index to valid range
    if (_currentQuestionIndex >= totalQ) _currentQuestionIndex = totalQ - 1;
    if (_currentQuestionIndex < 0) _currentQuestionIndex = 0;

    final q = questions[_currentQuestionIndex] as Map<String, dynamic>;
    final questionId =
        q['questionId']?.toString() ??
        q['id']?.toString() ??
        '$_currentQuestionIndex';
    final questionText =
        q['question'] ??
        q['questionText'] ??
        'Câu ${_currentQuestionIndex + 1}';
    final isBookmarked = _bookmarkedQuestions.contains(_currentQuestionIndex);
    final answeredCount = _answers.length;
    final isLastQuestion = _currentQuestionIndex == totalQ - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          isDark: isDark,
          icon: Icons.edit_note,
          title: 'Bài đánh giá ($totalQ câu)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress bar ──
              Row(
                children: [
                  Text(
                    'Đã trả lời: $answeredCount/$totalQ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Bookmark toggle
                  Semantics(
                    label: isBookmarked ? 'Bỏ đánh dấu' : 'Đánh dấu câu hỏi',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          if (isBookmarked) {
                            _bookmarkedQuestions.remove(_currentQuestionIndex);
                          } else {
                            _bookmarkedQuestions.add(_currentQuestionIndex);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked
                              ? Colors.amber
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalQ > 0 ? answeredCount / totalQ : 0,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlueDark,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),

              // ── Question card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'Câu ${_currentQuestionIndex + 1}',
                      child: Text(
                        'Câu ${_currentQuestionIndex + 1}: $questionText',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Render A-D multiple-choice options
                    ..._buildOptionsRadio(
                      q,
                      questionId,
                      isDark,
                      journeyId: journey.id,
                      testId: journey.assessmentTestId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Navigation dots ──
              Center(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: List.generate(totalQ, (i) {
                    final qId =
                        (questions[i] as Map<String, dynamic>)['questionId']
                            ?.toString() ??
                        (questions[i] as Map<String, dynamic>)['id']
                            ?.toString() ??
                        '$i';
                    final isAnswered = _answers.containsKey(qId);
                    final isCurrent = i == _currentQuestionIndex;
                    final isBm = _bookmarkedQuestions.contains(i);

                    return GestureDetector(
                      onTap: () => setState(() => _currentQuestionIndex = i),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? AppTheme.primaryBlueDark
                              : isAnswered
                              ? AppTheme.primaryBlueDark.withValues(alpha: 0.25)
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade200),
                          border: isBm
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                  ? AppTheme.primaryBlueDark
                                  : (isDark
                                        ? AppTheme.darkTextSecondary
                                        : Colors.grey.shade600),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // ── Prev / Next buttons ──
              Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _currentQuestionIndex--),
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: Semantics(
                          label: 'Câu trước',
                          child: const Text('Câu trước'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.darkBorderColor
                                : Colors.grey.shade300,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  if (!isLastQuestion)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _currentQuestionIndex++),
                        icon: Semantics(
                          label: 'Câu tiếp',
                          child: const Text('Câu tiếp'),
                        ),
                        label: const Icon(Icons.arrow_forward_ios, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlueDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),

              // ── Submit button (visible on last question or when all answered) ──
              if (isLastQuestion || answeredCount == totalQ) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        (journey.assessmentTestId == null ||
                            journey.assessmentTestId == 0 ||
                            isSubmitting)
                        ? null
                        : () async {
                            if (_answers.isEmpty) {
                              ErrorHandler.showWarningSnackBar(
                                context,
                                'Vui lòng trả lời ít nhất một câu hỏi',
                              );
                              return;
                            }
                            // Confirm if not all questions answered
                            if (_answers.length < totalQ) {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Nộp bài chưa hoàn tất?'),
                                  content: Text(
                                    'Bạn mới trả lời ${_answers.length}/$totalQ câu.\n'
                                    'Những câu chưa trả lời sẽ được tính là sai.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(false),
                                      child: const Text('Làm tiếp'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.primaryBlueDark,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Nộp ngay'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !context.mounted) return;
                            }
                            try {
                              final request = SubmitTestRequest(
                                testId: journey.assessmentTestId!,
                                answers: _answers,
                              );
                              await provider.submitTest(
                                journeyId: journey.id,
                                request: request,
                              );
                              // Show celebration dialog on success
                              if (context.mounted) {
                                _showCompletionCelebration(context, isDark);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ErrorHandler.showErrorSnackBar(
                                  context,
                                  ErrorHandler.getErrorMessage(e),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.send),
                    label: Semantics(
                      label: 'Nộp bài',
                      child: const Text('Nộp bài'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Build A-D radio button options for a multiple choice question
  List<Widget> _buildOptionsRadio(
    Map<String, dynamic> question,
    String questionId,
    bool isDark, {
    int? journeyId,
    int? testId,
  }) {
    final options = question['options'];
    if (options == null || options is! List || options.isEmpty) {
      return [
        Text(
          'Không có đáp án cho câu hỏi này',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ];
    }

    final selectedAnswer = _answers[questionId];

    return List<Widget>.generate(options.length, (i) {
      final option = options[i].toString();
      // Extract the option key (A, B, C, D) from text like "A. Some answer"
      final optionKey = String.fromCharCode(65 + i); // A=65, B=66, C=67, D=68

      final isSelected = selectedAnswer == optionKey;

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _answers[questionId] = optionKey;
            });
            // Fire-and-forget auto-save to backend (matches Prototype)
            if (journeyId != null && testId != null) {
              JourneyService().saveTestProgress(
                journeyId: journeyId,
                testId: testId,
                answers: Map.fromEntries(
                  _answers.entries
                      .where((e) => int.tryParse(e.key) != null)
                      .map((e) => MapEntry(int.parse(e.key), e.value)),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkBorderColor
                              : Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      optionKey,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // Strip the leading "A. " prefix if present, show clean text
                    option.replaceFirst(RegExp(r'^[A-D]\s*[\.\)\-:]\s*'), ''),
                    style: TextStyle(
                      fontSize: 14,
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
        ),
      );
    });
  }

  // --- Evaluation Result ---
  Widget _buildEvaluationResult(
    BuildContext context,
    JourneySummaryDto journey,
    JourneyProvider provider,
    bool isDark,
  ) {
    final result = journey.latestTestResult;
    final isGenerating =
        provider.isLoadingFor('generateRoadmap') ||
        provider.isRoadmapGenerationPendingFor(journey.id);
    final challengeBlocksRoadmap =
        result?.challengeRequired == true && result?.challengeAvailable == true;

    return Column(
      children: [
        if (result != null)
          _sectionCard(
            isDark: isDark,
            icon: Icons.analytics,
            title: 'Kết quả đánh giá',
            child: Column(
              children: [
                // Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${result.scorePercentage}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: result.scorePercentage >= 70
                            ? AppTheme.successColor
                            : AppTheme.primaryBlueDark,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 20,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Trình độ: ${_getLevelLabel(result.evaluatedLevel)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                // Adaptive: show testedLevel if different
                if (result.testedLevel != null &&
                    result.testedLevel != result.evaluatedLevel) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Độ khó bài test: ${_getLevelLabel(result.testedLevel!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip(
                      '${result.skillGapsCount} điểm yếu',
                      Colors.orange,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      '${result.strengthsCount} điểm mạnh',
                      AppTheme.successColor,
                      isDark,
                    ),
                  ],
                ),
                // Adaptive: provisional status message
                if (result.provisional == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.challengeRequired == true
                                ? 'Kết quả tạm tính. Bạn cần làm bài challenge-up để xác nhận trình độ.'
                                : 'Kết quả tạm tính. AI đang chuẩn bị bài đánh giá bổ sung.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Adaptive: Challenge-up / Retake buttons
                if (result.challengeAvailable == true ||
                    result.challengeRequired == true) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoadingFor('generateTest')
                          ? null
                          : () async {
                              try {
                                await provider.generateTest(journey.id);
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorHandler.showErrorSnackBar(
                                    context,
                                    e.toString().replaceAll('Exception: ', ''),
                                  );
                                }
                              }
                            },
                      icon: provider.isLoadingFor('generateTest')
                          ? CommonLoading.button(color: Colors.white)
                          : const Icon(Icons.trending_up, size: 18),
                      label: Text(
                        provider.isLoadingFor('generateTest')
                            ? 'Đang tạo Challenge-up...'
                            : 'Làm bài Challenge-up',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlueDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (result.resultId != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: provider.isLoadingFor('getTestResult')
                        ? null
                        : () async {
                            try {
                              final detailedResult = await provider
                                  .getTestResult(
                                    journeyId: journey.id,
                                    resultId: result.resultId!,
                                  );
                              if (detailedResult != null && context.mounted) {
                                EvaluationResultDialog.show(
                                  context,
                                  detailedResult,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ErrorHandler.showErrorSnackBar(
                                  context,
                                  e.toString().replaceAll('Exception: ', ''),
                                );
                              }
                            }
                          },
                    icon: provider.isLoadingFor('getTestResult')
                        ? CommonLoading.button(color: AppTheme.primaryBlueDark)
                        : const Icon(Icons.info_outline),
                    label: Text(
                      provider.isLoadingFor('getTestResult')
                          ? 'Đang tải...'
                          : 'Xem chi tiết đánh giá',
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        _sectionCard(
          isDark: isDark,
          icon: Icons.map,
          title: 'Tiếp theo',
          child: isGenerating
              ? const AiGenerationLoadingView(
                  speech:
                      'Meowl đang ghép lộ trình học tiếp theo cho bạn đó! 🚀',
                  title: 'Đang tạo lộ trình AI',
                  description:
                      'AI đang dựa trên kết quả đánh giá để đề xuất các bước học phù hợp tiếp theo.',
                  etaText: 'Thường mất khoảng 30-60 giây',
                  steps: [
                    ('Đọc kết quả', Icons.analytics_outlined),
                    ('Phân tích khoảng trống', Icons.psychology_outlined),
                    ('Xếp mốc học', Icons.route_outlined),
                    ('Hoàn thiện', Icons.check_circle_outline),
                  ],
                  avatarSize: 96,
                  topSpacing: 8,
                  padding: EdgeInsets.zero,
                  useSafeArea: false,
                  scrollable: false,
                )
              : challengeBlocksRoadmap
              ? Column(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 40,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bạn cần hoàn thành bài challenge-up để xác nhận trình độ trước khi tạo roadmap.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  children: [
                    const Text(
                      'AI sẽ tạo lộ trình học tập dựa trên kết quả đánh giá.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final updated = await provider.generateRoadmap(
                            journey.id,
                          );
                          final roadmapSessionId =
                              updated?.roadmapSessionId ??
                              provider.currentJourney?.roadmapSessionId;
                          if (roadmapSessionId != null && context.mounted) {
                            context.push(
                              '/roadmap/$roadmapSessionId?journeyId=${journey.id}',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ErrorHandler.showErrorSnackBar(
                              context,
                              e.toString().replaceAll('Exception: ', ''),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Tạo lộ trình AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlueDark,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // --- Roadmap Ready ---
  Widget _buildRoadmapReady(
    BuildContext context,
    JourneySummaryDto journey,
    JourneyProvider provider,
    bool isDark,
  ) {
    return _sectionCard(
      isDark: isDark,
      icon: Icons.map,
      title: 'Lộ trình đã sẵn sàng!',
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 48, color: AppTheme.successColor),
          const SizedBox(height: 12),
          const Text('Lộ trình học tập đã được tạo. Bắt đầu học ngay!'),
          const SizedBox(height: 16),
          if (journey.roadmapSessionId != null)
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/roadmap/${journey.roadmapSessionId}?journeyId=${journey.id}',
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Xem lộ trình'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlueDark,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // --- Active Journey ---
  Widget _buildActive(
    BuildContext context,
    JourneySummaryDto journey,
    bool isDark,
  ) {
    return Column(
      children: [
        _sectionCard(
          isDark: isDark,
          icon: Icons.play_circle,
          title: 'Đang học',
          child: Column(
            children: [
              if (journey.totalNodesCompleted != null)
                Text('Đã hoàn thành ${journey.totalNodesCompleted} node'),
              const SizedBox(height: 12),
              if (journey.roadmapSessionId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '/roadmap/${journey.roadmapSessionId}?journeyId=${journey.id}',
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('Xem lộ trình'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (journey.latestTestResult != null) ...[
          const SizedBox(height: 12),
          _sectionCard(
            isDark: isDark,
            icon: Icons.analytics,
            title: 'Kết quả đánh giá AI',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn(
                      'Điểm',
                      '${journey.latestTestResult!.scorePercentage}%',
                    ),
                    _statColumn(
                      'Trình độ',
                      _getLevelLabel(journey.latestTestResult!.evaluatedLevel),
                    ),
                  ],
                ),
                if (journey.latestTestResult?.resultId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          context.read<JourneyProvider>().isLoadingFor(
                            'getTestResult',
                          )
                          ? null
                          : () async {
                              try {
                                final p = context.read<JourneyProvider>();
                                final detailedResult = await p.getTestResult(
                                  journeyId: journey.id,
                                  resultId: journey.latestTestResult!.resultId!,
                                );
                                if (detailedResult != null && context.mounted) {
                                  EvaluationResultDialog.show(
                                    context,
                                    detailedResult,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ErrorHandler.showErrorSnackBar(
                                    context,
                                    e.toString().replaceAll('Exception: ', ''),
                                  );
                                }
                              }
                            },
                      icon:
                          context.read<JourneyProvider>().isLoadingFor(
                            'getTestResult',
                          )
                          ? CommonLoading.button(
                              color: AppTheme.primaryBlueDark,
                            )
                          : const Icon(Icons.info_outline),
                      label: Text(
                        context.read<JourneyProvider>().isLoadingFor(
                              'getTestResult',
                            )
                            ? 'Đang tải...'
                            : 'Xem chi tiết phân tích AI',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Completed ---
  Widget _buildCompleted(
    BuildContext context,
    JourneySummaryDto journey,
    bool isDark,
  ) {
    return _sectionCard(
      isDark: isDark,
      icon: Icons.emoji_events,
      title: 'Hoàn thành! 🎉',
      child: Column(
        children: [
          Icon(Icons.celebration, size: 48, color: AppTheme.successColor),
          const SizedBox(height: 12),
          const Text(
            'Chúc mừng bạn đã hoàn thành hành trình!',
            textAlign: TextAlign.center,
          ),
          if (journey.aiSummaryReport != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
              ),
              child: Text(
                journey.aiSummaryReport!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Paused ---
  Widget _buildPaused(
    BuildContext context,
    JourneySummaryDto journey,
    bool isDark,
  ) {
    return _sectionCard(
      isDark: isDark,
      icon: Icons.pause_circle,
      title: 'Tạm dừng',
      child: Column(
        children: [
          const Text(
            'Hành trình đang tạm dừng. Bạn có thể tiếp tục bất cứ lúc nào.',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                context.read<JourneyProvider>().resumeJourney(journey.id),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tiếp tục'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlueDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- Cancelled ---
  Widget _buildCancelled(BuildContext context, bool isDark) {
    return _sectionCard(
      isDark: isDark,
      icon: Icons.cancel,
      title: 'Đã hủy',
      child: Column(
        children: [
          Icon(Icons.cancel_outlined, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text('Hành trình này đã bị hủy.'),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push('/journey/create'),
            icon: const Icon(Icons.add),
            label: const Text('Tạo hành trình mới'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Milestones
  // ============================================================================

  Widget _buildMilestones(
    BuildContext context,
    List<MilestoneDto> milestones,
    bool isDark,
  ) {
    // Deduplicate by milestone key — keep only one entry per milestone type
    // Prefer the completed one if duplicates exist
    final seen = <String>{};
    final uniqueMilestones = <MilestoneDto>[];
    for (final m in milestones) {
      if (!seen.contains(m.milestone)) {
        seen.add(m.milestone);
        uniqueMilestones.add(m);
      }
    }

    return _sectionCard(
      isDark: isDark,
      icon: Icons.flag,
      title: 'Các mốc quan trọng',
      child: Column(
        children: uniqueMilestones.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  m.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: m.isCompleted ? AppTheme.successColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getMilestoneLabel(m.milestone),
                    style: TextStyle(
                      color: m.isCompleted
                          ? (isDark ? AppTheme.darkTextSecondary : Colors.grey)
                          : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================================
  // Helpers
  // ============================================================================

  Widget _sectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryBlueDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlueDark,
          ),
        ),
      ],
    );
  }

  String _getGoalLabel(String goal) {
    switch (goal.toUpperCase()) {
      case 'EXPLORE':
        return 'Khám phá ngành';
      case 'INTERNSHIP':
        return 'Chuẩn bị thực tập';
      case 'CAREER_CHANGE':
        return 'Chuyển ngành';
      case 'UPSKILL':
        return 'Nâng cao kỹ năng';
      case 'FROM_SCRATCH':
        return 'Bắt đầu từ đầu';
      default:
        return goal;
    }
  }

  String _getLevelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.beginner:
        return 'Mới bắt đầu';
      case SkillLevel.elementary:
        return 'Sơ cấp';
      case SkillLevel.intermediate:
        return 'Trung cấp';
      case SkillLevel.advanced:
        return 'Nâng cao';
      case SkillLevel.expert:
        return 'Chuyên gia';
    }
  }

  String _getMilestoneLabel(String milestone) {
    switch (milestone) {
      case 'ASSESSMENT_COMPLETED':
        return 'Hoàn thành đánh giá';
      case 'TEST_GENERATED':
        return 'Bài test đã tạo';
      case 'TEST_COMPLETED':
        return 'Hoàn thành bài test';
      case 'EVALUATION_COMPLETED':
        return 'AI đánh giá xong';
      case 'ROADMAP_CREATED':
        return 'Lộ trình đã tạo';
      case 'STUDY_PLAN_CREATED':
        return 'Kế hoạch học đã tạo';
      case 'FIRST_NODE_COMPLETED':
        return 'Hoàn thành node đầu tiên';
      case 'JOURNEY_COMPLETED':
        return 'Hoàn thành hành trình';
      default:
        return milestone;
    }
  }

  Widget _buildVerificationCta(
    BuildContext context,
    JourneySummaryDto journey,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Yêu cầu xác minh hoàn thành',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Hành trình của bạn cần được mentor xác minh trước khi hoàn thành chính thức.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (journey.status == JourneyStatus.completedUnverified)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final provider = context.read<JourneyProvider>();
                  final result = await provider.requestVerification(journey.id);
                  if (!context.mounted) return;

                  if (result != null) {
                    ErrorHandler.showSuccessSnackBar(
                      context,
                      'Đã gửi yêu cầu xác minh hành trình',
                    );
                  } else if (provider.hasError) {
                    ErrorHandler.showErrorSnackBar(
                      context,
                      provider.errorMessage ?? 'Yêu cầu xác minh thất bại',
                    );
                  }
                },
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Gửi yêu cầu xác minh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themeGreenStart,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (journey.status == JourneyStatus.awaitingVerification)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/journey/${journey.id}/final-verification'),
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Xem xác minh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Celebration modal after test submission ──
  void _showCompletionCelebration(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlueDark,
                        AppTheme.primaryBlueDark.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '🎉 Tuyệt vời!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bạn đã hoàn thành bài đánh giá!\nMeowl đang chấm bài và phân tích năng lực cho bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🐱 "Cố lên nào, Meowl tin bạn sẽ làm tốt!"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xem kết quả',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
