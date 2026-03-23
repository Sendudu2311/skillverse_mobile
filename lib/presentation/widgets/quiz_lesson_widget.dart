import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/quiz_models.dart';
import '../../data/services/quiz_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/widgets/glass_card.dart';
import '../../presentation/themes/app_theme.dart';

class QuizLessonWidget extends StatefulWidget {
  final int quizId;
  final VoidCallback? onCompleted;

  const QuizLessonWidget({super.key, required this.quizId, this.onCompleted});

  @override
  State<QuizLessonWidget> createState() => _QuizLessonWidgetState();
}

class _QuizLessonWidgetState extends State<QuizLessonWidget> {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  QuizDetailDto? _quiz;
  QuizAttemptStatusDto? _attemptStatus;

  // State for tracking user answers
  // QuestionID -> Selected Option IDs (for multiple choice) or Answer Text
  final Map<int, List<int>> _selectedOptions = {};

  QuizSubmitResponseDto? _result;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Load quiz and attempt status in parallel
      final results = await Future.wait([
        _quizService.getQuiz(widget.quizId),
        if (authProvider.user != null)
          _quizService.getQuizAttemptStatus(
            quizId: widget.quizId,
          ),
      ]);

      setState(() {
        _quiz = results[0] as QuizDetailDto;
        if (results.length > 1) {
          _attemptStatus = results[1] as QuizAttemptStatusDto;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleOption(int questionId, int optionId, QuestionType type) {
    if (_result != null) return; // Cannot change answers after submission

    setState(() {
      if (!_selectedOptions.containsKey(questionId)) {
        _selectedOptions[questionId] = [];
      }

      if (type == QuestionType.multipleChoice ||
          type == QuestionType.trueFalse) {
        // Since we don't have single choice vs multiple choice distinction in provided QuestionType for simple multichoice,
        // we'll assume standard radio behavior for True/False and checkbox for Multiple Choice if functionality requires it.
        // However, standard quizzes usually treat Multiple Choice as Single Select unless specified "Select All".
        // Let's assume Single Select for now to keep it simple, or check if we need multiple selection logic.
        // Looking at backend models, `selectedOptionIds` is a List, implying multiple support.
        // But for typical quizzes, it's often single select. Let's support swapping selection for now.

        // Actually True/False is definitely single select.
        // Multiple Choice can be single or multi. Let's assume Single Select behavior for simplicity first,
        // or allow multiple if user taps another.
        // Let's implement Single Select behavior for now (clearing previous).
        _selectedOptions[questionId] = [optionId];
      }
    });
  }

  Future<void> _submitQuiz() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để nộp bài')),
      );
      return;
    }

    if (_quiz == null || _quiz!.questions == null) return;

    // Check if all questions are answered
    if (_selectedOptions.length < _quiz!.questions!.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng trả lời tất cả các câu hỏi')),
      );
      return;
    }

    // Check if user can submit (not exceeded attempts or in cooldown)
    if (_attemptStatus != null &&
        !_attemptStatus!.canRetry &&
        _result == null) {
      String message = 'Bạn đã hết lượt làm bài quiz này';
      if (_attemptStatus!.secondsUntilRetry > 0) {
        final hours = _attemptStatus!.secondsUntilRetry ~/ 3600;
        final minutes = (_attemptStatus!.secondsUntilRetry % 3600) ~/ 60;
        message = 'Vui lòng chờ ${hours}h ${minutes}m để làm lại';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final answers = _selectedOptions.entries.map((entry) {
        return QuizAnswerDto(
          questionId: entry.key,
          selectedOptionIds: entry.value,
        );
      }).toList();

      final submission = SubmitQuizDto(quizId: widget.quizId, answers: answers);

      final result = await _quizService.submitQuiz(
        quizId: widget.quizId,
        submitData: submission,
      );

      setState(() {
        _result = result;
        _isSubmitting = false;
        _showReview = true;
      });

      // Reload attempt status to update count
      _loadQuizData();

      if (result.passed && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      // Extract error message
      String errorMsg = 'Lỗi nộp bài';
      if (e.toString().contains('Bạn đã hết lượt làm bài')) {
        errorMsg = 'Bạn đã hết lượt làm bài quiz này';
      } else if (e.toString().contains('ApiException')) {
        errorMsg = e.toString().replaceAll('ApiException: ', '');
      } else {
        errorMsg = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      // Reload attempt status to update count
      _loadQuizData();
    }
  }

  void _retry() {
    // Check if user can retry
    if (_attemptStatus != null && !_attemptStatus!.canRetry) {
      String message = 'Bạn đã hết lượt làm bài quiz này';
      if (_attemptStatus!.secondsUntilRetry > 0) {
        final hours = _attemptStatus!.secondsUntilRetry ~/ 3600;
        final minutes = (_attemptStatus!.secondsUntilRetry % 3600) ~/ 60;
        message = 'Vui lòng chờ ${hours}h ${minutes}m để làm lại';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _selectedOptions.clear();
      _result = null;
      _showReview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadQuizData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_quiz == null) {
      return const Center(child: Text('Không tìm thấy bài kiểm tra'));
    }

    // Show Result View
    if (_result != null && !_showReview) {
      return _buildResultView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (_result != null) _buildResultHeader(),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _quiz!.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_quiz!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(_quiz!.description!),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.help_outline, size: 16),
                        const SizedBox(width: 4),
                        Text('${_quiz!.questions?.length ?? 0} câu hỏi'),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 4),
                        Text('Điểm đạt: ${_quiz!.passScore}%'),
                      ],
                    ),
                    if (_attemptStatus != null &&
                        _attemptStatus!.attemptsUsed > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_attemptStatus!.attemptsUsed}/${_attemptStatus!.maxAttempts} lần',
                          ),
                        ],
                      ),
                    if (_attemptStatus != null && _attemptStatus!.hasPassed)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('Điểm cao nhất: ${_attemptStatus!.bestScore}%'),
                        ],
                      ),
                  ],
                ),

                // Status cards
                if (_attemptStatus != null) ...[
                  // Passed status
                  if (_attemptStatus!.hasPassed)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn đã hoàn thành quiz với ${_attemptStatus!.bestScore}%',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Cooldown warning
                  if (!_attemptStatus!.canRetry &&
                      _attemptStatus!.secondsUntilRetry > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vui lòng chờ ${_formatCooldown(_attemptStatus!.secondsUntilRetry)} để làm lại',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Max attempts reached
                  if (!_attemptStatus!.canRetry &&
                      _attemptStatus!.secondsUntilRetry == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bạn đã hết lượt làm bài (${_attemptStatus!.attemptsUsed}/${_attemptStatus!.maxAttempts})',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent attempts history
          if (_attemptStatus != null &&
              _attemptStatus!.recentAttempts != null &&
              _attemptStatus!.recentAttempts!.isNotEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lịch sử làm bài',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._attemptStatus!.recentAttempts!.take(3).map((attempt) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: attempt.passed
                            ? Colors.green.withOpacity(0.05)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: attempt.passed
                              ? Colors.green.withOpacity(0.3)
                              : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            attempt.passed ? Icons.check_circle : Icons.cancel,
                            color: attempt.passed ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${attempt.score}% - ${attempt.passed ? "Đạt" : "Chưa đạt"}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: attempt.passed ? Colors.green : null,
                                  ),
                                ),
                                if (attempt.submittedAt != null)
                                  Text(
                                    _formatDate(attempt.submittedAt!),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${attempt.correctAnswers ?? 0}/${attempt.totalQuestions ?? 0}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Questions
          ...?_quiz!.questions?.map((question) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildQuestionCard(question),
            );
          }),

          // Submit Button
          if (_result == null)
            ElevatedButton(
              onPressed:
                  (_isSubmitting ||
                      (_attemptStatus != null && !_attemptStatus!.canRetry))
                  ? null
                  : _submitQuiz,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.themeOrangeStart,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      (_attemptStatus != null && !_attemptStatus!.canRetry)
                          ? 'Đã hết lượt'
                          : 'Nộp bài',
                    ),
            )
          else
            ElevatedButton(
              onPressed: (_attemptStatus != null && !_attemptStatus!.canRetry)
                  ? null
                  : _retry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.themeBlueStart,
                foregroundColor: Colors.white,
              ),
              child: Text(
                (_attemptStatus != null && !_attemptStatus!.canRetry)
                    ? 'Đã hết lượt'
                    : 'Làm lại',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    final passed = _result!.passed;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed
            ? Colors.green.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: passed ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed
                      ? 'Chúc mừng! Bạn đã vượt qua.'
                      : 'Bạn chưa đạt điểm yêu cầu.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: passed ? Colors.green : Colors.red,
                  ),
                ),
                Text('Điểm của bạn: ${_result!.score}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    // Simplified result view if we want a dedicated screen,
    // but for now we just show the header and review mode.
    return Container();
  }

  Widget _buildQuestionCard(QuizQuestionDetailDto question) {
    bool isAnswerCorrect = false;
    QuizAnswerResultDto? answerResult;

    // Find result for this question if in review mode
    if (_result != null && _result!.attempt.answers != null) {
      try {
        answerResult = _result!.attempt.answers!.firstWhere(
          (a) => a.questionId == question.id,
        );
        isAnswerCorrect = answerResult.isCorrect;
      } catch (_) {}
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: _result != null
          ? (isAnswerCorrect
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Câu ${question.orderIndex + 1}:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...?question.options?.map((option) {
            final isSelected =
                _selectedOptions[question.id]?.contains(option.id) ?? false;

            Color? optionColor;
            if (_result != null) {
              if (option.correct) {
                optionColor = Colors.green.withValues(alpha: 0.2);
              } else if (isSelected && !option.correct) {
                optionColor = Colors.red.withValues(alpha: 0.2);
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color:
                    optionColor ??
                    (isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                        : null),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: optionColor != null
                      ? Colors.transparent
                      : (isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor),
                ),
              ),
              child: RadioListTile<int>(
                value: option.id,
                groupValue: _selectedOptions[question.id]?.firstOrNull,
                onChanged: _result == null
                    ? (val) => _toggleOption(
                        question.id,
                        option.id,
                        question.questionType,
                      )
                    : null,
                title: Text(option.optionText),
                activeColor: Theme.of(context).colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
              ),
            );
          }),

          if (_result != null &&
              answerResult != null &&
              !answerResult.isCorrect)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sai. Đáp án đúng được tô màu xanh.',
                style: TextStyle(
                  color: Colors.red[300],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCooldown(int seconds) {
    if (seconds <= 0) return '0 phút';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes} phút';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}
