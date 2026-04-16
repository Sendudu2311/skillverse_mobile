import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/models/quiz_models.dart';
import '../../../data/services/quiz_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';

/// QuizAttemptPage — full 3-screen quiz experience (START / TAKING / RESULT)
/// Navigates from: CourseLearningPage → push('/quiz/:quizId')
class QuizAttemptPage extends StatefulWidget {
  final int quizId;
  final int? moduleId;
  final VoidCallback? onCompleted;
  final bool isInline;

  const QuizAttemptPage({
    super.key,
    required this.quizId,
    this.moduleId,
    this.onCompleted,
    this.isInline = false,
  });

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  final QuizService _quizService = QuizService();

  // Three-screen state machine
  // 'start' = overview + history | 'taking' = in-progress | 'result' = scored
  String _viewMode = 'start';

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  QuizDetailDto? _quiz;
  QuizAttemptStatusDto? _attemptStatus;
  QuizAttemptReviewDto? _review; // answer-by-answer review
  QuizSubmitResponseDto? _result;

  // Answer tracking: questionId → { selectedOptionIds?, textAnswer? }
  final Map<int, List<int>> _selectedOptions = {};
  final Map<int, String> _textAnswers = {};

  // Session management
  String? _sessionToken;
  Timer? _heartbeatTimer;

  // Countdown timer
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadQuizData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _quizService.getQuiz(widget.quizId),
        _quizService.getQuizAttemptStatus(quizId: widget.quizId),
      ]);

      final quiz = results[0] as QuizDetailDto;
      final status = results[1] as QuizAttemptStatusDto;

      setState(() {
        _quiz = quiz;
        _attemptStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReview() async {
    try {
      final review = await _quizService.getMyLatestReview(
        quizId: widget.quizId,
      );
      if (mounted && review != null) {
        setState(() => _review = review);
      }
    } catch (e) {
      debugPrint('Failed to load review: $e');
    }
  }

  String _formatTimerDisplay() {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _isTimerUrgent => _secondsRemaining > 0 && _secondsRemaining < 300;

  // ── Session Management ───────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_sessionToken != null && _viewMode == 'taking') {
        _sendHeartbeat();
      }
    });
  }

  Future<void> _sendHeartbeat() async {
    if (_sessionToken == null) return;
    try {
      await _quizService.heartbeatAttemptSession(
        quizId: widget.quizId,
        sessionToken: _sessionToken!,
      );
    } catch (e) {
      debugPrint('Heartbeat failed: $e');
    }
  }

  // ── Taking Quiz ──────────────────────────────────────────────────────────

  Future<void> _beginQuiz() async {
    setState(() => _isLoading = true);

    try {
      final session = await _quizService.startAttemptSession(
        quizId: widget.quizId,
      );

      _sessionToken = session.sessionToken;

      final now = DateTime.now().toUtc();
      int remainingSeconds = (_quiz?.timeLimitMinutes ?? 30) * 60;
      bool isResumed = false;

      if (session.status == 'IN_PROGRESS' && session.expiresAt != null) {
        final expiresAt = session.expiresAt!.toUtc();
        final actualRemaining = expiresAt.difference(now).inSeconds;

        // If the session was already created before (startedAt earlier than now by > 10 seconds),
        // we consider it a resumed session and cap the remaining time.
        if (session.startedAt != null) {
          final startedAt = session.startedAt!.toUtc();
          if (now.difference(startedAt).inSeconds > 10) {
            remainingSeconds = actualRemaining.clamp(0, remainingSeconds);
            isResumed = true;
          }
        }
      }

      setState(() {
        _viewMode = 'taking';
        _isLoading = false;
      });

      _countdownTimer?.cancel();
      _secondsRemaining = remainingSeconds;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _countdownTimer?.cancel();
          if (_viewMode == 'taking') _submitQuiz();
        }
      });

      _startHeartbeat();

      if (isResumed && mounted) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Tiếp tục phiên làm bài. Thời gian còn lại được giữ nguyên.',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Không thể bắt đầu phiên làm bài: $e',
        );
      }
    }
  }

  void _toggleOption(
    int questionId,
    int optionId,
    QuestionType type, {
    bool allowMultiple = false,
  }) {
    if (_result != null) return;

    if (type == QuestionType.multipleChoice && allowMultiple) {
      // Multiple choice: toggle selection
      setState(() {
        if (!_selectedOptions.containsKey(questionId)) {
          _selectedOptions[questionId] = [];
        }
        if (_selectedOptions[questionId]!.contains(optionId)) {
          _selectedOptions[questionId] = List.from(
            _selectedOptions[questionId]!,
          )..remove(optionId);
        } else {
          _selectedOptions[questionId] = List.from(
            _selectedOptions[questionId]!,
          )..add(optionId);
        }
      });
    } else {
      // Single select (true/false + default multiple)
      setState(() => _selectedOptions[questionId] = [optionId]);
    }
  }

  void _setTextAnswer(int questionId, String text) {
    setState(() {
      _textAnswers[questionId] = text;
      _selectedOptions.remove(questionId); // clear options when typing text
    });
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null || _quiz!.questions == null) return;

    // Validate: every question must have an answer
    final unanswered = _quiz!.questions!
        .where((q) => !_hasAnswer(q.id, q.questionType))
        .length;

    if (unanswered > 0) {
      final confirmed = await _showConfirmDialog(
        title: 'Chưa trả lời hết',
        message: 'Còn $unanswered câu chưa trả lời. Bạn có chắc muốn nộp bài?',
        confirmText: 'Nộp bài',
      );
      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      final answers = _buildAnswers();

      final submission = SubmitQuizDto(
        quizId: widget.quizId,
        answers: answers,
        sessionToken: _sessionToken,
      );

      final result = await _quizService.submitQuiz(
        quizId: widget.quizId,
        submitData: submission,
      );

      setState(() {
        _result = result;
        _viewMode = 'result';
        _isSubmitting = false;
      });

      // Load review if passed
      if (result.passed) {
        await _loadReview();
      }

      // Reload status to update counts
      await _loadQuizData();

      if (result.passed && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      String msg = 'Nộp bài thất bại';
      final err = e.toString();
      if (err.contains('QUIZ_RETRY_LOCKED_BY_PASS')) {
        msg = 'Bạn đã đạt quiz này rồi';
      } else if (err.contains('ApiException')) {
        msg = ErrorHandler.getErrorMessage(e);
      }
      if (mounted) ErrorHandler.showErrorSnackBar(context, msg);
    }
  }

  List<QuizAnswerDto> _buildAnswers() {
    final answers = <QuizAnswerDto>[];

    for (final q in _quiz!.questions!) {
      if (_textAnswers.containsKey(q.id)) {
        answers.add(
          QuizAnswerDto(questionId: q.id, textAnswer: _textAnswers[q.id]),
        );
      } else if (_selectedOptions.containsKey(q.id)) {
        answers.add(
          QuizAnswerDto(
            questionId: q.id,
            selectedOptionIds: _selectedOptions[q.id],
          ),
        );
      }
    }

    return answers;
  }

  bool _hasAnswer(int questionId, QuestionType type) {
    if (type == QuestionType.shortAnswer) {
      return _textAnswers[questionId]?.trim().isNotEmpty ?? false;
    }
    return _selectedOptions[questionId]?.isNotEmpty ?? false;
  }

  void _retry() {
    _selectedOptions.clear();
    _textAnswers.clear();
    for (var controller in _textControllers.values) {
      controller.clear();
    }
    _result = null;
    _review = null;
    _sessionToken = null;
    _viewMode = 'start';
    _loadQuizData();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  String _formatCooldown(int seconds) {
    if (seconds <= 0) return '0 phút';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '$m phút';
  }

  int get _answeredCount {
    if (_quiz?.questions == null) return 0;
    return _quiz!.questions!
        .where((q) => _hasAnswer(q.id, q.questionType))
        .length;
  }

  // ── Screen: Start ────────────────────────────────────────────────────────

  Widget _buildStartScreen() {
    final quiz = _quiz!;
    final status = _attemptStatus;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (quiz.description != null) ...[
                  const SizedBox(height: 8),
                  Text(quiz.description!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Meta chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                Icons.help_outline,
                '${quiz.questions?.length ?? 0} câu hỏi',
              ),
              _buildMetaChip(
                Icons.check_circle_outline,
                'Cần ${quiz.passScore}% để đạt',
              ),
              if (status != null)
                _buildMetaChip(
                  Icons.history,
                  '${status.attemptsUsed}/${status.maxAttempts} lần',
                ),
              if (status != null && status.hasPassed)
                _buildMetaChip(
                  Icons.star,
                  'Điểm cao nhất: ${status.bestScore}%',
                  color: AppTheme.accentGold,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Passed banner
          if (status != null && status.hasPassed) _buildPassedBanner(status),

          // Error/Cooldown states
          if (status != null && !status.canRetry && !status.hasPassed)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.block,
                        color: AppTheme.errorColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hết lượt làm bài',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn đã sử dụng hết lượt làm bài. Hệ thống sẽ cấp lại lượt làm bài sau 8 giờ kể từ lần làm đầu tiên.',
                  ),
                  const SizedBox(height: 8),
                  if (status.secondsUntilRetry > 0)
                    Text(
                      '• Thời gian chờ: ${_formatCooldown(status.secondsUntilRetry)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (status.nextRetryAt != null)
                    Text(
                      '• Có thể làm lại vào: ${DateTimeHelper.tryParseIso8601(status.nextRetryAt!) != null ? DateTimeHelper.formatSmart(DateTimeHelper.tryParseIso8601(status.nextRetryAt!)!) : status.nextRetryAt}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: widget.isInline
                        ? const SizedBox.shrink() // No exit button in inline mode — prevents popping course flow
                        : OutlinedButton.icon(
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Quay lại khóa học'),
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Attempt history
          if (status != null &&
              status.recentAttempts != null &&
              status.recentAttempts!.isNotEmpty) ...[
            Text(
              'Lịch sử làm bài',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...status.recentAttempts!.take(5).map(_buildAttemptItem),
            const SizedBox(height: 24),
          ],

          // Start / Retry button
          if (status != null && status.hasPassed)
            _buildStartButton('Đã thi đạt ✅', null, isDisabled: true)
          else if (status != null && !status.canRetry)
            _buildStartButton('Đã hết lượt', null, isDisabled: true)
          else
            _buildStartButton(
              status!.attemptsUsed > 0 ? 'Làm lại' : 'Bắt đầu làm bài',
              _beginQuiz,
            ),
        ],
      ),
    );
  }

  Widget _buildStartButton(
    String label,
    VoidCallback? onPressed, {
    bool isDisabled = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.themeBlueStart,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAttemptItem(QuizAttemptDto attempt) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            attempt.passed ? Icons.check_circle : Icons.cancel,
            color: attempt.passed ? AppTheme.successColor : AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${attempt.score}% — ${attempt.passed ? "Đạt" : "Chưa đạt"}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: attempt.passed ? AppTheme.successColor : null,
                  ),
                ),
                if (attempt.submittedAt != null)
                  Text(
                    DateTimeHelper.formatSmart(attempt.submittedAt!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            '${attempt.correctAnswers ?? 0}/${attempt.totalQuestions ?? 0}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.accentCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassedBanner(QuizAttemptStatusDto status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn đã hoàn thành quiz!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                Text(
                  'Điểm cao nhất: ${status.bestScore}%',
                  style: TextStyle(
                    color: AppTheme.successColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Screen: Taking ──────────────────────────────────────────────────────

  Widget _buildTakingScreen() {
    final quiz = _quiz!;
    final total = quiz.questions?.length ?? 0;
    final answered = _answeredCount;
    final progress = total > 0 ? answered / total : 0.0;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu $answered/$total',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        ),

        // Questions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: quiz.questions?.length ?? 0,
            itemBuilder: (context, index) {
              final q = quiz.questions![index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildQuestionCard(q, index),
              );
            },
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.all(16),
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
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themeOrangeStart,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? CommonLoading.button()
                    : const Text(
                        'Nộp bài',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(QuizQuestionDetailDto q, int index) {
    final isAnswered = _hasAnswer(q.id, q.questionType);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: isAnswered
          ? AppTheme.successColor.withValues(alpha: 0.3)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Câu ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.questionText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Options or text input
          if (q.questionType == QuestionType.shortAnswer)
            _buildTextAnswerField(q)
          else
            _buildOptionList(q),
        ],
      ),
    );
  }

  Widget _buildOptionList(QuizQuestionDetailDto q) {
    if (q.options == null || q.options!.isEmpty) return const SizedBox();

    return Column(
      children: q.options!.asMap().entries.map((entry) {
        final idx = entry.key;
        final option = entry.value;
        final label = idx < 26 ? String.fromCharCode(65 + idx) : '${idx + 1}';
        final isSelected = _selectedOptions[q.id]?.contains(option.id) ?? false;

        final isMulti =
            q.questionType == QuestionType.multipleChoice &&
            (q.correctOptionCount ?? 0) > 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: isMulti
              ? CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleOption(
                    q.id,
                    option.id,
                    q.questionType,
                    allowMultiple: true,
                  ),
                  title: Text('$label. ${option.optionText}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                )
              : RadioListTile<int>(
                  value: option.id,
                  groupValue: _selectedOptions[q.id]?.firstOrNull,
                  onChanged: (_) =>
                      _toggleOption(q.id, option.id, q.questionType),
                  title: Text('$label. ${option.optionText}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  dense: true,
                ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnswerField(QuizQuestionDetailDto q) {
    if (!_textControllers.containsKey(q.id)) {
      _textControllers[q.id] = TextEditingController(
        text: _textAnswers[q.id] ?? '',
      );
    }
    final controller = _textControllers[q.id]!;

    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Nhập câu trả lời...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(12),
      ),
      onChanged: (val) {
        // setState is called inside _setTextAnswer, but we don't recreate the controller
        _setTextAnswer(q.id, val);
      },
    );
  }

  // ── Screen: Result ──────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final result = _result!;
    final review = _review;
    final quiz = _quiz;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score circle
          _buildScoreCard(result),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.isInline
                      ? _retry // Stay inline, go back to start view
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (result.passed || (_attemptStatus?.canRetry ?? false))
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(result.passed ? 'Làm lại' : 'Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.themeBlueStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Answer review
          if (review != null && review.answers != null && quiz != null) ...[
            Text(
              'Đáp án chi tiết',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...review.answers!.asMap().entries.map((entry) {
              final idx = entry.key;
              final answer = entry.value;
              // Match question by questionId
              final question = quiz.questions
                  ?.where((q) => q.id == answer.questionId)
                  .firstOrNull;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildReviewCard(idx + 1, answer, question),
              );
            }),
          ] else if (!result.passed) ...[
            // Passed = show answers. Not passed + no review yet = show generic
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 32, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Điểm của bạn: ${result.score}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cần ${quiz?.passScore ?? 0}% để đạt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_attemptStatus != null && !_attemptStatus!.canRetry) ...[
                    const SizedBox(height: 8),
                    Text(
                      _attemptStatus!.secondsUntilRetry > 0
                          ? 'Chờ ${_formatCooldown(_attemptStatus!.secondsUntilRetry)} để thử lại'
                          : 'Đã hết lượt làm bài',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCard(QuizSubmitResponseDto result) {
    final passed = result.passed;
    final scoreColor = passed ? AppTheme.successColor : AppTheme.errorColor;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated score circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: result.score / 100,
                  strokeWidth: 10,
                  backgroundColor: scoreColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${result.score}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    passed ? 'Đạt' : 'Chưa đạt',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            passed
                ? 'Chúc mừng! Bạn đã vượt qua bài kiểm tra.'
                : 'Bạn chưa đạt điểm yêu cầu. Hãy thử lại nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: passed ? AppTheme.successColor : null),
          ),
          if (_quiz != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Điểm yêu cầu: ${_quiz!.passScore}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    int index,
    QuizAttemptAnswerReviewDto answer,
    QuizQuestionDetailDto? question,
  ) {
    final isCorrect = answer.correct ?? false;
    final color = isCorrect ? AppTheme.successColor : AppTheme.errorColor;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Câu $index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (answer.scoreEarned != null && question != null)
                Text(
                  '${answer.scoreEarned}/${question.score}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Question text
          if (question != null)
            Text(question.questionText, style: const TextStyle(fontSize: 15))
          else if (answer.questionText != null)
            Text(answer.questionText!, style: const TextStyle(fontSize: 15)),

          const SizedBox(height: 12),

          // MC/TF: Show options with tags + feedback
          if (answer.optionsSnapshot != null &&
              answer.optionsSnapshot!.isNotEmpty)
            ...answer.optionsSnapshot!.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final label = idx < 26
                  ? String.fromCharCode(65 + idx)
                  : '${idx + 1}';
              final isSelected = opt.selected == true;
              final isCorrectOpt = opt.correct == true;

              // Determine background color
              Color? bgColor;
              Color? borderColor;
              if (isCorrectOpt && isSelected) {
                bgColor = AppTheme.successColor.withValues(alpha: 0.1);
                borderColor = AppTheme.successColor.withValues(alpha: 0.4);
              } else if (isCorrectOpt && !isSelected) {
                bgColor = AppTheme.successColor.withValues(alpha: 0.05);
                borderColor = AppTheme.successColor.withValues(alpha: 0.3);
              } else if (isSelected && !isCorrectOpt) {
                bgColor = AppTheme.errorColor.withValues(alpha: 0.1);
                borderColor = AppTheme.errorColor.withValues(alpha: 0.4);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor ?? Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option row with tags
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(opt.optionText ?? '')),
                        const SizedBox(width: 6),
                        // Tags
                        Wrap(
                          spacing: 4,
                          children: [
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Bạn chọn',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.accentCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isCorrectOpt)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Đáp án đúng',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Per-option feedback (show for selected OR correct options)
                    if (isSelected || isCorrectOpt)
                      if (opt.feedback != null && opt.feedback!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4, left: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            opt.feedback!,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isCorrectOpt
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                        ),
                  ],
                ),
              );
            })
          // SHORT_ANSWER: show submitted answer + correct answer
          else ...[
            // Submitted answer
            if (answer.submittedAnswerText != null &&
                answer.submittedAnswerText!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppTheme.successColor.withValues(alpha: 0.1)
                      : AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect
                        ? AppTheme.successColor.withValues(alpha: 0.3)
                        : AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu trả lời của bạn:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(answer.submittedAnswerText!),
                  ],
                ),
              ),

            // Correct answer (only if passed)
            if (answer.correctAnswerText != null &&
                answer.correctAnswerText!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đáp án đúng:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                    Text(
                      answer.correctAnswerText!,
                      style: const TextStyle(color: AppTheme.successColor),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Inline Timer Bar ─────────────────────────────────────────────────────

  Widget _buildInlineTimerBar() {
    if (_viewMode != 'taking' || _secondsRemaining <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isTimerUrgent
          ? AppTheme.errorColor.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: _isTimerUrgent
                ? AppTheme.errorColor
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Thời gian còn lại: ${_formatTimerDisplay()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _isTimerUrgent
                  ? AppTheme.errorColor
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '$_answeredCount/${_quiz?.questions?.length ?? 0} câu',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ── Main Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Inline mode: no Scaffold, embed directly in parent
    if (widget.isInline) {
      return Column(
        children: [
          _buildInlineTimerBar(),
          Expanded(child: _buildBody()),
        ],
      );
    }

    // Full-screen mode (standalone)
    String title;
    switch (_viewMode) {
      case 'taking':
        title = _quiz?.title ?? 'Bài kiểm tra';
        break;
      case 'result':
        title = 'Kết quả bài kiểm tra';
        break;
      default:
        title = 'Bài kiểm tra';
    }

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: title,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          // Timer display (only in taking mode)
          if (_viewMode == 'taking' && _secondsRemaining > 0)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isTimerUrgent
                    ? AppTheme.errorColor.withValues(alpha: 0.15)
                    : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _isTimerUrgent
                        ? AppTheme.errorColor
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimerDisplay(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isTimerUrgent
                          ? AppTheme.errorColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return CommonLoading.center();
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(message: _errorMessage!, onRetry: _loadQuizData);
    }

    if (_quiz == null) {
      return const Center(child: Text('Không tìm thấy bài kiểm tra'));
    }

    switch (_viewMode) {
      case 'taking':
        return _buildTakingScreen();
      case 'result':
        return _buildResultScreen();
      default:
        return _buildStartScreen();
    }
  }
}
