import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/module_with_content_models.dart';
import '../../../data/models/lesson_models.dart';
import '../../../data/services/module_service.dart';
import '../../../data/services/lesson_service.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/group_chat_service.dart';
import '../../widgets/video_lesson_player.dart';
import '../../widgets/reading_lesson_content.dart';
import 'quiz_attempt_page.dart';
import 'assignment_page.dart';
import 'certificate_view_page.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';

// ──────────────────────────────────────────────
// Unified Curriculum Item (lesson / quiz / assignment)
// ──────────────────────────────────────────────
class _CurriculumItem {
  final int moduleId;
  final String moduleTitle;
  final int itemId;
  final String itemType; // 'lesson' | 'quiz' | 'assignment'
  final String title;
  final int orderIndex;

  // Lesson-specific
  final LessonType? lessonType;
  final String? resourceUrl;
  final int? durationSec;

  // Quiz-specific
  final int? passScore;

  // Assignment-specific
  final String? submissionType;
  final int? maxScore;

  const _CurriculumItem({
    required this.moduleId,
    required this.moduleTitle,
    required this.itemId,
    required this.itemType,
    required this.title,
    required this.orderIndex,
    this.lessonType,
    this.resourceUrl,
    this.durationSec,
    this.passScore,
    this.submissionType,
    this.maxScore,
  });
}

// ──────────────────────────────────────────────
// Course Learning Page
// ──────────────────────────────────────────────
class CourseLearningPage extends StatefulWidget {
  final String courseId;
  const CourseLearningPage({super.key, required this.courseId});

  @override
  State<CourseLearningPage> createState() => _CourseLearningPageState();
}

class _CourseLearningPageState extends State<CourseLearningPage> {
  final ModuleService _moduleService = ModuleService();
  final LessonService _lessonService = LessonService();

  List<ModuleWithContentDto> _modules = [];
  List<_CurriculumItem> _curriculumItems = [];
  final Set<int> _completedLessonIds = {};
  final Set<int> _completedQuizIds = {};
  final Set<int> _completedAssignmentIds = {};

  int _activeCurriculumIndex = -1;
  LessonDetailDto? _currentLessonDetail; // Only for lesson items

  // Course completion / certificate state
  int _coursePercent = 0;
  int? _certificateId;

  // GlobalKey giữ state VideoLessonPlayer sống sót khi tree restructure (portrait ↔ landscape)
  // Reset key khi đổi bài để buộc tạo player mới
  GlobalKey _videoPlayerKey = GlobalKey(); // ignore: prefer_final_fields

  bool _isLoadingModules = true;
  bool _isLoadingLesson = false;
  bool _isMarkingComplete = false;

  @override
  void initState() {
    super.initState();
    _loadModulesWithContent();
  }

  Future<void> _executeAsync(
    Future<void> Function() operation, {
    void Function(bool)? setLoading,
    void Function(String)? onError,
  }) async {
    setLoading?.call(true);
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        if (onError != null) {
          onError(ErrorHandler.getErrorMessage(e));
        } else {
          ErrorHandler.showErrorSnackBar(context, ErrorHandler.getErrorMessage(e));
        }
      }
    } finally {
      if (mounted) setLoading?.call(false);
    }
  }

  // ── Data Loading ──────────────────────────────

  Future<void> _loadModulesWithContent() async {
    await _executeAsync(() async {
      final courseId = int.parse(widget.courseId);
      final modules = await _moduleService.listModulesWithContent(courseId: courseId);
      
      modules.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      if (mounted) {
        setState(() {
          _modules = modules;
          _curriculumItems = _buildCurriculumItems(modules);
        });
      }

      await _loadCompletedLessonIds();

      // Auto-select first uncompleted item
      if (_curriculumItems.isNotEmpty) {
        final targetIndex = _findFirstUncompletedIndex();
        await _selectCurriculumItem(targetIndex);
      }
    }, setLoading: (val) => setState(() => _isLoadingModules = val));
  }

  /// Build a flat list of curriculum items from modules
  /// Sort: module.orderIndex → item.orderIndex → type rank (lesson < quiz < assignment)
  List<_CurriculumItem> _buildCurriculumItems(
    List<ModuleWithContentDto> modules,
  ) {
    final items = <_CurriculumItem>[];

    for (final module in modules) {
      final moduleItems = <_CurriculumItem>[];

      // Add lessons
      for (final lesson in module.lessons) {
        moduleItems.add(
          _CurriculumItem(
            moduleId: module.id,
            moduleTitle: module.title,
            itemId: lesson.id,
            itemType: 'lesson',
            title: lesson.title,
            orderIndex: lesson.orderIndex,
            lessonType: lesson.type,
            durationSec: lesson.durationSec,
            resourceUrl: lesson.resourceUrl,
          ),
        );
      }

      // Add quizzes
      for (final quiz in module.quizzes) {
        moduleItems.add(
          _CurriculumItem(
            moduleId: module.id,
            moduleTitle: module.title,
            itemId: quiz.id,
            itemType: 'quiz',
            title: quiz.title ?? 'Bài kiểm tra',
            orderIndex: quiz.orderIndex ?? 999,
            passScore: quiz.passScore,
          ),
        );
      }

      // Add assignments
      for (final assignment in module.assignments) {
        moduleItems.add(
          _CurriculumItem(
            moduleId: module.id,
            moduleTitle: module.title,
            itemId: assignment.id,
            itemType: 'assignment',
            title: assignment.title ?? 'Bài tập',
            orderIndex: assignment.orderIndex ?? 999,
            submissionType: assignment.submissionType,
            maxScore: assignment.maxScore,
          ),
        );
      }

      // Sort within module: by orderIndex, then type rank
      moduleItems.sort((a, b) {
        final orderCmp = a.orderIndex.compareTo(b.orderIndex);
        if (orderCmp != 0) return orderCmp;
        return _typeRank(a.itemType).compareTo(_typeRank(b.itemType));
      });

      items.addAll(moduleItems);
    }

    return items;
  }

  int _typeRank(String itemType) {
    switch (itemType) {
      case 'lesson':
        return 0;
      case 'quiz':
        return 1;
      case 'assignment':
        return 2;
      default:
        return 3;
    }
  }

  /// Load course learning status (completed IDs, progress, certificate) from backend
  Future<void> _loadCompletedLessonIds() async {
    await _executeAsync(() async {
      final courseId = int.parse(widget.courseId);

      try {
        // Single API call replaces separate lesson + N quiz calls
        final status = await _lessonService.getCourseLearningStatus(
          courseId: courseId,
        );

        if (mounted) {
          setState(() {
            _completedLessonIds.addAll(status.completedLessonIds);
            _completedQuizIds.addAll(status.completedQuizIds);
            _completedAssignmentIds.addAll(status.completedAssignmentIds);
            _coursePercent = status.percent;
            _certificateId = status.certificateId;
          });
        }
      } catch (_) {
        // Fallback: use old API if course-learning/status is not available
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user == null) return;
        final completedIds = await _lessonService.getCompletedLessonIds(
          courseId: courseId,
          userId: authProvider.user!.id,
        );
        if (mounted) {
          setState(() {
            _completedLessonIds.addAll(completedIds);
          });
        }
      }
    }, onError: (msg) => debugPrint('Error loading completion status: $msg'));
  }

  /// Find the first curriculum item that is NOT completed
  int _findFirstUncompletedIndex() {
    for (int i = 0; i < _curriculumItems.length; i++) {
      final item = _curriculumItems[i];
      switch (item.itemType) {
        case 'lesson':
          if (!_completedLessonIds.contains(item.itemId)) return i;
          break;
        case 'quiz':
          if (!_completedQuizIds.contains(item.itemId)) return i;
          break;
        case 'assignment':
          if (!_completedAssignmentIds.contains(item.itemId)) return i;
          break;
      }
    }
    // All completed — default to first item
    return 0;
  }

  // ── Item Selection ────────────────────────────

  Future<void> _selectCurriculumItem(int index) async {
    if (index < 0 || index >= _curriculumItems.length) return;

    final item = _curriculumItems[index];

    setState(() {
      _activeCurriculumIndex = index;
      _currentLessonDetail = null;
      if (item.itemType == 'lesson') _videoPlayerKey = GlobalKey();
    });

    if (item.itemType == 'lesson') {
      await _executeAsync(() async {
        final lessonDetail = await _lessonService.getLesson(lessonId: item.itemId);
        if (mounted) setState(() => _currentLessonDetail = lessonDetail);
      }, setLoading: (val) => setState(() => _isLoadingLesson = val));
    } else {
      setState(() => _isLoadingLesson = false);
    }
  }

  // ── Navigation ────────────────────────────────

  void _goToNextItem() {
    if (_activeCurriculumIndex >= 0 &&
        _activeCurriculumIndex < _curriculumItems.length - 1) {
      _selectCurriculumItem(_activeCurriculumIndex + 1);
    } else {
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, '🎉 Đã hoàn thành khóa học!');
      }
    }
  }

  void _goToPreviousItem() {
    if (_activeCurriculumIndex > 0) {
      _selectCurriculumItem(_activeCurriculumIndex - 1);
    }
  }

  // ── Complete Logic ────────────────────────────

  Future<void> _markLessonComplete() async {
    if (_activeCurriculumIndex < 0) return;

    final item = _curriculumItems[_activeCurriculumIndex];
    if (item.itemType != 'lesson') return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    await _executeAsync(() async {
      await _lessonService.markLessonCompleted(
        moduleId: item.moduleId,
        lessonId: item.itemId,
        userId: authProvider.user!.id,
      );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, '✅ Đã hoàn thành bài học!');
        setState(() => _completedLessonIds.add(item.itemId));
        _goToNextItem();
      }
    }, setLoading: (val) => setState(() => _isMarkingComplete = val));
  }

  // Called by QuizLessonWidget when quiz is completed
  void _onQuizCompleted() {
    _goToNextItem();
  }

  // ── Open Group Chat ──────────────────────────────

  void _openGroupChat(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    try {
      final courseId = int.tryParse(widget.courseId);
      if (courseId == null) return;

      // Fetch the specific group for this course
      final courseGroup = await GroupChatService().getGroupByCourse(
        courseId,
        authProvider.user!.id,
      );

      if (!mounted) return;

      if (courseGroup != null) {
        // Automatically join if they aren't a member yet
        if (!courseGroup.isMember) {
          await GroupChatService().joinGroup(courseGroup.id, authProvider.user!.id);
        }
        context.push('/group-chat/${courseGroup.id}');
      } else {
        ErrorHandler.showWarningSnackBar(context, 'Khóa học này chưa có nhóm chat');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Không thể mở nhóm chat');
    }
  }

  // ── Module List Bottom Sheet ──────────────────

  void _showModuleList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.lightBackgroundSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nội dung khóa học',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Module list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _modules.length,
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    final activeItem = _activeCurriculumIndex >= 0
                        ? _curriculumItems[_activeCurriculumIndex]
                        : null;
                    final isExpanded = module.id == activeItem?.moduleId;

                    // Get all curriculum items for this module
                    final moduleItems = _curriculumItems
                        .where((item) => item.moduleId == module.id)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        title: Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: module.description != null
                            ? Text(
                                module.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : null,
                        children: [
                          if (moduleItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Chưa có bài học'),
                            )
                          else
                            ...moduleItems.map((item) {
                              final globalIndex = _curriculumItems.indexOf(
                                item,
                              );
                              final isActive =
                                  globalIndex == _activeCurriculumIndex;
                              final isCompleted =
                                  (item.itemType == 'lesson' &&
                                      _completedLessonIds.contains(
                                        item.itemId,
                                      )) ||
                                  (item.itemType == 'quiz' &&
                                      _completedQuizIds.contains(item.itemId));

                              return ListTile(
                                leading: Icon(
                                  isCompleted
                                      ? Icons.check_circle
                                      : _getItemIcon(item),
                                  color: isCompleted
                                      ? AppTheme.successColor
                                      : isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : null,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isCompleted ? AppTheme.lightTextSecondary : null,
                                  ),
                                ),
                                subtitle: Text(
                                  isCompleted
                                      ? 'Đã hoàn thành'
                                      : _getItemSubtitle(item),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? AppTheme.successColor
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                trailing: isActive
                                    ? Icon(
                                        Icons.play_circle_filled,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 20,
                                      )
                                    : null,
                                selected: isActive,
                                selectedTileColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                onTap: () {
                                  _selectCurriculumItem(globalIndex);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModules) {
      return Scaffold(
        appBar: const SkillVerseAppBar(title: 'Đang tải...'),
        body: CommonLoading.center(),
      );
    }

    if (_modules.isEmpty) {
      return Scaffold(
        appBar: const SkillVerseAppBar(title: 'Khóa học'),
        body: const Center(
          child: EmptyStateWidget(
            icon: Icons.auto_stories,
            title: 'Trống',
            subtitle: 'Khóa học chưa có nội dung',
            iconGradient: AppTheme.blueGradient,
          ),
        ),
      );
    }

    final activeItem = _activeCurriculumIndex >= 0
        ? _curriculumItems[_activeCurriculumIndex]
        : null;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: activeItem?.moduleTitle ?? _modules[0].title,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => _openGroupChat(context),
            tooltip: 'Nhóm chat khóa học',
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showModuleList,
            tooltip: 'Nội dung khóa học',
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_activeCurriculumIndex < 0) {
      return const Center(child: Text('Chọn một bài học để bắt đầu'));
    }

    // Show certificate banner if course is 100% complete
    if (_coursePercent >= 100 && _certificateId != null) {
      return Column(
        children: [
          _buildCertificateBanner(),
          Expanded(child: _buildLearningContent()),
        ],
      );
    }

    return _buildLearningContent();
  }

  Widget _buildCertificateBanner() {
    return GestureDetector(
      onTap: () {
        if (_certificateId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CertificateViewPage(
                certificateId: _certificateId!,
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chúc mừng! Bạn đã hoàn thành khóa học 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nhấn để xem chứng chỉ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningContent() {

    final item = _curriculumItems[_activeCurriculumIndex];

    final isVideoLesson = item.itemType == 'lesson' &&
        !_isLoadingLesson &&
        _currentLessonDetail != null &&
        _currentLessonDetail!.lessonType == LessonType.video;

    // Tạo video widget MỘT LẦN trước OrientationBuilder
    // → Flutter reparent thay vì destroy+recreate khi xoay màn hình
    final videoWidget = isVideoLesson
        ? VideoLessonPlayer(
            key: _videoPlayerKey,
            videoUrl: _currentLessonDetail!.videoUrl,
            lessonId: _currentLessonDetail!.id,
          )
        : null;

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape && videoWidget != null) {
          // Landscape + video: Row layout — video trái, nav + metadata phải
          return Row(
            children: [
              Expanded(flex: 6, child: videoWidget),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildVideoLessonInfo(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(item),
                  ],
                ),
              ),
            ],
          );
        }

        // Quiz or Assignment items need Expanded layout (they manage own scrolling)
        final isExpandedItem = item.itemType == 'quiz' || item.itemType == 'assignment';

        if (isExpandedItem) {
          return Column(
            children: [
              Expanded(child: _buildItemContent(item)),
              _buildBottomBar(item),
            ],
          );
        }

        // Portrait layout (hoặc non-video landscape)
        return Column(
          children: [
            if (videoWidget != null) videoWidget,

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isVideoLesson)
                      _buildVideoLessonInfo()
                    else ...[
                      _buildInfoHeader(item),
                      _buildItemContent(item),
                    ],
                  ],
                ),
              ),
            ),

            _buildBottomBar(item),
          ],
        );
      },
    );
  }

  Widget _buildInfoHeader(_CurriculumItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getItemIcon(item), size: 18),
              const SizedBox(width: 6),
              Text(
                _getItemTypeName(item),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (item.durationSec != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(item.durationSec!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLessonInfo() {
    final lesson = _currentLessonDetail;
    if (lesson == null) return const SizedBox.shrink();

    final activeItem = _activeCurriculumIndex >= 0
        ? _curriculumItems[_activeCurriculumIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề bài học
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          // Thời lượng nếu có
          if (activeItem?.durationSec != null && activeItem!.durationSec! > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(activeItem.durationSec!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          // Mô tả nếu có
          if (lesson.contentText != null && lesson.contentText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              lesson.contentText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemContent(_CurriculumItem item) {
    switch (item.itemType) {
      case 'lesson':
        return _buildLessonContent(item);
      case 'quiz':
        return _buildQuizContent(item);
      case 'assignment':
        return _buildAssignmentContent(item);
      default:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nội dung không khả dụng')),
        );
    }
  }

  Widget _buildLessonContent(_CurriculumItem item) {
    if (_isLoadingLesson || _currentLessonDetail == null) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CommonLoading()),
      );
    }

    final lesson = _currentLessonDetail!;

    switch (lesson.lessonType) {
      case LessonType.video:
        return VideoLessonPlayer(
          key: ValueKey(lesson.id),
          videoUrl: lesson.videoUrl,
          lessonId: lesson.id,
        );
      case LessonType.reading:
        return ReadingLessonContent(
          content: lesson.contentText,
          resourceUrl: lesson.resourceUrl,
        );
      case LessonType.quiz:
        // Inline quiz within a lesson — use QuizAttemptPage (replaces old QuizLessonWidget)
        return QuizAttemptPage(
          key: ValueKey('lesson_quiz_${lesson.id}'),
          quizId: lesson.id,
          isInline: true,
          onCompleted: _onQuizCompleted,
        );
      case LessonType.assignment:
        // Render assignment inline
        return AssignmentPage(
          key: ValueKey('lesson_assignment_${lesson.id}'),
          assignmentId: lesson.id,
          isInline: true,
          onSubmitted: () {},
        );
      case LessonType.codelab:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Codelab không khả dụng trên mobile')),
        );
    }
  }

  Widget _buildQuizContent(_CurriculumItem item) {
    // Render quiz inline instead of pushing a separate route
    return QuizAttemptPage(
      key: ValueKey('quiz_${item.itemId}'),
      quizId: item.itemId,
      moduleId: item.moduleId,
      isInline: true,
      onCompleted: () {
        setState(() => _completedQuizIds.add(item.itemId));
        _onQuizCompleted();
      },
    );
  }

  Widget _buildAssignmentContent(_CurriculumItem item) {
    // Render assignment inline instead of pushing a separate route
    return AssignmentPage(
      key: ValueKey('assignment_${item.itemId}'),
      assignmentId: item.itemId,
      isInline: true,
      onSubmitted: () {
        // Refresh or show success
      },
    );
  }

  Widget _buildBottomBar(_CurriculumItem item) {
    final isLesson = item.itemType == 'lesson';
    final isQuiz = item.itemType == 'quiz';
    final isAssignment = item.itemType == 'assignment';
    final isInlineItem = isQuiz || isAssignment;

    // Determine complete button state
    String completeLabel;
    bool canComplete;
    VoidCallback? onCompletePressed;

    if (isLesson) {
      completeLabel = 'Hoàn thành';
      canComplete = !_isMarkingComplete;
      onCompletePressed = _markLessonComplete;
    } else if (isQuiz) {
      // Quiz: only allow navigating to next if passed
      final quizPassed = _completedQuizIds.contains(item.itemId);
      completeLabel = quizPassed ? 'Tiếp theo' : 'Làm bài kiểm tra';
      canComplete = quizPassed && _activeCurriculumIndex < _curriculumItems.length - 1;
      onCompletePressed = quizPassed ? _goToNextItem : null;
    } else if (isAssignment) {
      completeLabel = 'Tiếp theo';
      canComplete = _activeCurriculumIndex < _curriculumItems.length - 1;
      onCompletePressed = _goToNextItem;
    } else {
      completeLabel = 'Hoàn thành';
      canComplete = false;
      onCompletePressed = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _activeCurriculumIndex > 0
                    ? _goToPreviousItem
                    : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                label: const Text('Trước'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Complete/Action button (Hidden for inline Quiz/Assignment to avoid redundancy)
            if (!isInlineItem)
              const SizedBox(width: 12),
            if (!isInlineItem)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: canComplete ? onCompletePressed : null,
                  icon: _isMarkingComplete
                      ? CommonLoading.button()
                      : Icon(
                          isLesson
                              ? Icons.check
                              : Icons.laptop_mac_outlined,
                          size: 20,
                        ),
                  label: Text(
                    completeLabel,
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Next button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_activeCurriculumIndex < _curriculumItems.length - 1
                    && !(isQuiz && !_completedQuizIds.contains(item.itemId)))
                    ? _goToNextItem
                    : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                label: const Text('Sau'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────

  IconData _getItemIcon(_CurriculumItem item) {
    switch (item.itemType) {
      case 'quiz':
        return Icons.quiz_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'lesson':
      default:
        if (item.lessonType == null) return Icons.article_outlined;
        switch (item.lessonType!) {
          case LessonType.video:
            return Icons.play_circle_outline;
          case LessonType.reading:
            return Icons.article_outlined;
          case LessonType.quiz:
            return Icons.quiz_outlined;
          case LessonType.assignment:
            return Icons.assignment_outlined;
          case LessonType.codelab:
            return Icons.code;
        }
    }
  }

  String _getItemTypeName(_CurriculumItem item) {
    switch (item.itemType) {
      case 'quiz':
        return 'Bài kiểm tra';
      case 'assignment':
        return 'Bài tập';
      case 'lesson':
      default:
        if (item.lessonType == null) return 'Bài học';
        switch (item.lessonType!) {
          case LessonType.video:
            return 'Video';
          case LessonType.reading:
            return 'Đọc';
          case LessonType.quiz:
            return 'Quiz';
          case LessonType.assignment:
            return 'Bài tập';
          case LessonType.codelab:
            return 'Codelab';
        }
    }
  }

  String _getItemSubtitle(_CurriculumItem item) {
    switch (item.itemType) {
      case 'quiz':
        return 'Quiz${item.passScore != null ? ' · Cần ${item.passScore}% để đạt' : ''}';
      case 'assignment':
        return 'Bài tập';
      case 'lesson':
      default:
        final type = _getItemTypeName(item);
        if (item.durationSec != null) {
          return '$type · ${_formatDuration(item.durationSec!)}';
        }
        return type;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}


