import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/module_models.dart';
import '../../../data/models/lesson_models.dart';
import '../../../data/services/module_service.dart';
import '../../../data/services/lesson_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/video_lesson_player.dart';
import '../../widgets/reading_lesson_content.dart';

class CourseLearningPage extends StatefulWidget {
  final String courseId;
  const CourseLearningPage({super.key, required this.courseId});

  @override
  State<CourseLearningPage> createState() => _CourseLearningPageState();
}

class _CourseLearningPageState extends State<CourseLearningPage> {
  final ModuleService _moduleService = ModuleService();
  final LessonService _lessonService = LessonService();

  List<ModuleSummaryDto> _modules = [];
  Map<int, List<LessonBriefDto>> _moduleLessons = {};

  int? _activeModuleId;
  int? _activeLessonId;
  LessonDetailDto? _currentLessonDetail;

  bool _isLoadingModules = true;
  bool _isLoadingLesson = false;
  bool _isMarkingComplete = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);

    try {
      final courseId = int.parse(widget.courseId);
      final modules = await _moduleService.listModules(courseId: courseId);

      setState(() {
        _modules = modules;
        _isLoadingModules = false;
      });

      // Load lessons for first module and select first lesson
      if (_modules.isNotEmpty) {
        await _loadLessonsForModule(_modules[0].id);
        if (_moduleLessons[_modules[0].id]?.isNotEmpty ?? false) {
          await _selectLesson(_modules[0].id, _moduleLessons[_modules[0].id]![0].id);
        }
      }
    } catch (e) {
      setState(() => _isLoadingModules = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải modules: $e')),
        );
      }
    }
  }

  Future<void> _loadLessonsForModule(int moduleId) async {
    if (_moduleLessons.containsKey(moduleId)) return;

    try {
      final lessons = await _moduleService.listLessons(moduleId: moduleId);
      setState(() {
        _moduleLessons[moduleId] = lessons;
      });
    } catch (e) {
      debugPrint('Error loading lessons for module $moduleId: $e');
    }
  }

  Future<void> _selectLesson(int moduleId, int lessonId) async {
    setState(() {
      _activeModuleId = moduleId;
      _activeLessonId = lessonId;
      _isLoadingLesson = true;
    });

    try {
      final lessonDetail = await _lessonService.getLesson(lessonId: lessonId);
      setState(() {
        _currentLessonDetail = lessonDetail;
        _isLoadingLesson = false;
      });
    } catch (e) {
      setState(() => _isLoadingLesson = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải bài học: $e')),
        );
      }
    }
  }

  Future<void> _markLessonComplete() async {
    if (_activeModuleId == null || _activeLessonId == null) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    setState(() => _isMarkingComplete = true);

    try {
      await _lessonService.markLessonCompleted(
        moduleId: _activeModuleId!,
        lessonId: _activeLessonId!,
        userId: authProvider.user!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành bài học!')),
        );
      }

      // Move to next lesson
      await _goToNextLesson();
    } catch (e) {
      debugPrint('Error marking lesson complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đánh dấu hoàn thành: $e')),
        );
      }
    } finally {
      setState(() => _isMarkingComplete = false);
    }
  }

  Future<void> _goToNextLesson() async {
    if (_activeModuleId == null || _activeLessonId == null) return;

    try {
      final nextLesson = await _lessonService.getNextLesson(
        moduleId: _activeModuleId!,
        lessonId: _activeLessonId!,
      );

      if (nextLesson != null) {
        await _selectLesson(_activeModuleId!, nextLesson.id);
      } else {
        // No next lesson in current module, try next module
        final currentModuleIndex = _modules.indexWhere((m) => m.id == _activeModuleId);
        if (currentModuleIndex < _modules.length - 1) {
          final nextModule = _modules[currentModuleIndex + 1];
          await _loadLessonsForModule(nextModule.id);
          final nextModuleLessons = _moduleLessons[nextModule.id];
          if (nextModuleLessons != null && nextModuleLessons.isNotEmpty) {
            await _selectLesson(nextModule.id, nextModuleLessons[0].id);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã hoàn thành khóa học!')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã hoàn thành khóa học!')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting next lesson: $e');
    }
  }

  Future<void> _goToPreviousLesson() async {
    if (_activeModuleId == null || _activeLessonId == null) return;

    try {
      final prevLesson = await _lessonService.getPreviousLesson(
        moduleId: _activeModuleId!,
        lessonId: _activeLessonId!,
      );

      if (prevLesson != null) {
        await _selectLesson(_activeModuleId!, prevLesson.id);
      } else {
        // No previous lesson in current module, try previous module
        final currentModuleIndex = _modules.indexWhere((m) => m.id == _activeModuleId);
        if (currentModuleIndex > 0) {
          final prevModule = _modules[currentModuleIndex - 1];
          await _loadLessonsForModule(prevModule.id);
          final prevModuleLessons = _moduleLessons[prevModule.id];
          if (prevModuleLessons != null && prevModuleLessons.isNotEmpty) {
            await _selectLesson(prevModule.id, prevModuleLessons.last.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting previous lesson: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModules) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_modules.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Khóa học')),
        body: const Center(child: Text('Khóa học chưa có nội dung')),
      );
    }

    final currentModule = _modules.firstWhere(
      (m) => m.id == _activeModuleId,
      orElse: () => _modules[0],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentModule.title),
      ),
      body: Row(
        children: [
          // Sidebar - Module & Lesson List
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                final lessons = _moduleLessons[module.id];
                final isExpanded = module.id == _activeModuleId;

                return ExpansionTile(
                  initiallyExpanded: isExpanded,
                  title: Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: module.description != null
                      ? Text(
                          module.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  onExpansionChanged: (expanded) {
                    if (expanded) {
                      _loadLessonsForModule(module.id);
                    }
                  },
                  children: [
                    if (lessons == null)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (lessons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Chưa có bài học'),
                      )
                    else
                      ...lessons.map((lesson) {
                        final isActive = lesson.id == _activeLessonId;
                        return ListTile(
                          leading: Icon(
                            _getLessonIcon(lesson.type),
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(lesson.title),
                          subtitle: lesson.durationSec != null
                              ? Text(_formatDuration(lesson.durationSec!))
                              : null,
                          selected: isActive,
                          selectedTileColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          onTap: () => _selectLesson(module.id, lesson.id),
                        );
                      }),
                  ],
                );
              },
            ),
          ),

          // Main Content Area
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoadingLesson || _currentLessonDetail == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final lesson = _currentLessonDetail!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lesson Title
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Lesson Type & Duration
          Row(
            children: [
              Icon(_getLessonIcon(lesson.lessonType), size: 20),
              const SizedBox(width: 8),
              Text(
                _getLessonTypeName(lesson.lessonType),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (lesson.durationSec != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(lesson.durationSec!),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Lesson Content
          Expanded(
            child: _buildLessonContent(lesson),
          ),

          const SizedBox(height: 16),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _goToPreviousLesson,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Bài trước'),
              ),
              ElevatedButton.icon(
                onPressed: _isMarkingComplete ? null : _markLessonComplete,
                icon: _isMarkingComplete
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Hoàn thành & Tiếp theo'),
              ),
              TextButton.icon(
                onPressed: _goToNextLesson,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Bài tiếp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonContent(LessonDetailDto lesson) {
    switch (lesson.lessonType) {
      case LessonType.video:
        return VideoLessonPlayer(
          videoUrl: lesson.videoUrl,
          lessonId: lesson.id,
        );
      case LessonType.reading:
        return ReadingLessonContent(
          content: lesson.contentText,
        );
      case LessonType.quiz:
        return const Center(
          child: Text('Quiz sẽ được triển khai sau'),
        );
      case LessonType.assignment:
        return const Center(
          child: Text('Assignment sẽ được triển khai sau'),
        );
      case LessonType.codelab:
        return const Center(
          child: Text('Codelab không khả dụng trên mobile'),
        );
    }
  }

  IconData _getLessonIcon(LessonType type) {
    switch (type) {
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

  String _getLessonTypeName(LessonType type) {
    switch (type) {
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${secs}s';
    }
  }
}
