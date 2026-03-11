import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/quiz_models.dart';

void main() {
  // ============================================================
  // QuestionType Enum Tests
  // ============================================================
  group('QuestionType enum', () {
    test('contains all expected values', () {
      expect(QuestionType.values.length, 3);
      expect(QuestionType.values, contains(QuestionType.multipleChoice));
      expect(QuestionType.values, contains(QuestionType.trueFalse));
      expect(QuestionType.values, contains(QuestionType.shortAnswer));
    });
  });

  // ============================================================
  // QuizSummaryDto Tests
  // ============================================================
  group('QuizSummaryDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'title': 'Flutter Basics Quiz',
        'description': 'Test your Flutter knowledge',
        'passScore': 70,
        'questionCount': 10,
        'moduleId': 5,
      };
      final summary = QuizSummaryDto.fromJson(json);

      expect(summary.id, 1);
      expect(summary.title, 'Flutter Basics Quiz');
      expect(summary.description, 'Test your Flutter knowledge');
      expect(summary.passScore, 70);
      expect(summary.questionCount, 10);
      expect(summary.moduleId, 5);
    });

    test('fromJson() with optional fields null', () {
      final json = {'id': 2, 'title': 'Minimal Quiz', 'passScore': 50};
      final summary = QuizSummaryDto.fromJson(json);

      expect(summary.id, 2);
      expect(summary.description, isNull);
      expect(summary.questionCount, isNull);
      expect(summary.moduleId, isNull);
    });

    test('toJson() round-trip preserves data', () {
      final original = {
        'id': 1,
        'title': 'Test Quiz',
        'description': 'Desc',
        'passScore': 80,
        'questionCount': 5,
        'moduleId': 3,
      };
      final result = QuizSummaryDto.fromJson(original).toJson();

      expect(result['id'], original['id']);
      expect(result['title'], original['title']);
      expect(result['passScore'], original['passScore']);
    });
  });

  // ============================================================
  // QuizDetailDto Tests
  // ============================================================
  group('QuizDetailDto', () {
    test('fromJson() with questions', () {
      final json = {
        'id': 1,
        'title': 'Dart Quiz',
        'description': 'Test Dart skills',
        'passScore': 60,
        'moduleId': 2,
        'questions': [
          {
            'id': 1,
            'questionText': 'What is Dart?',
            'questionType': 'MULTIPLE_CHOICE',
            'score': 10,
            'orderIndex': 0,
            'options': [
              {
                'id': 1,
                'optionText': 'A programming language',
                'correct': true,
                'feedback': 'Correct!',
                'orderIndex': 0,
              },
              {
                'id': 2,
                'optionText': 'A database',
                'correct': false,
                'feedback': 'Incorrect',
                'orderIndex': 1,
              },
            ],
          },
        ],
      };
      final detail = QuizDetailDto.fromJson(json);

      expect(detail.id, 1);
      expect(detail.title, 'Dart Quiz');
      expect(detail.passScore, 60);
      expect(detail.questions?.length, 1);
      expect(detail.questions![0].questionText, 'What is Dart?');
      expect(detail.questions![0].questionType, QuestionType.multipleChoice);
      expect(detail.questions![0].options?.length, 2);
      expect(detail.questions![0].options![0].correct, true);
    });

    test('fromJson() without questions', () {
      final json = {'id': 2, 'title': 'Empty Quiz', 'passScore': 50};
      final detail = QuizDetailDto.fromJson(json);

      expect(detail.questions, isNull);
      expect(detail.moduleId, isNull);
    });
  });

  // ============================================================
  // QuizQuestionDetailDto Tests
  // ============================================================
  group('QuizQuestionDetailDto', () {
    test('fromJson() with MULTIPLE_CHOICE type', () {
      final json = {
        'id': 1,
        'questionText': 'Choose the correct answer',
        'questionType': 'MULTIPLE_CHOICE',
        'score': 10,
        'orderIndex': 0,
      };
      final question = QuizQuestionDetailDto.fromJson(json);

      expect(question.questionType, QuestionType.multipleChoice);
      expect(question.score, 10);
    });

    test('fromJson() with TRUE_FALSE type', () {
      final json = {
        'id': 2,
        'questionText': 'Dart is a programming language',
        'questionType': 'TRUE_FALSE',
        'score': 5,
        'orderIndex': 1,
      };
      final question = QuizQuestionDetailDto.fromJson(json);

      expect(question.questionType, QuestionType.trueFalse);
    });

    test('fromJson() with SHORT_ANSWER type', () {
      final json = {
        'id': 3,
        'questionText': 'Explain polymorphism',
        'questionType': 'SHORT_ANSWER',
        'score': 20,
        'orderIndex': 2,
      };
      final question = QuizQuestionDetailDto.fromJson(json);

      expect(question.questionType, QuestionType.shortAnswer);
    });
  });

  // ============================================================
  // QuizOptionDto Tests
  // ============================================================
  group('QuizOptionDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'optionText': 'Option A',
        'correct': true,
        'feedback': 'Great choice!',
        'orderIndex': 0,
      };
      final option = QuizOptionDto.fromJson(json);

      expect(option.id, 1);
      expect(option.optionText, 'Option A');
      expect(option.correct, true);
      expect(option.feedback, 'Great choice!');
      expect(option.orderIndex, 0);
    });

    test('fromJson() correct=false', () {
      final json = {'id': 2, 'optionText': 'Wrong answer', 'correct': false};
      final option = QuizOptionDto.fromJson(json);

      expect(option.correct, false);
      expect(option.feedback, isNull);
    });
  });

  // ============================================================
  // QuizAnswerDto Tests
  // ============================================================
  group('QuizAnswerDto', () {
    test('fromJson() with selectedOptionIds', () {
      final json = {
        'questionId': 1,
        'selectedOptionIds': [1, 3],
      };
      final answer = QuizAnswerDto.fromJson(json);

      expect(answer.questionId, 1);
      expect(answer.selectedOptionIds, [1, 3]);
      expect(answer.textAnswer, isNull);
    });

    test('fromJson() with textAnswer', () {
      final json = {'questionId': 2, 'textAnswer': 'My written answer'};
      final answer = QuizAnswerDto.fromJson(json);

      expect(answer.questionId, 2);
      expect(answer.selectedOptionIds, isNull);
      expect(answer.textAnswer, 'My written answer');
    });

    test('toJson() produces correct map', () {
      final answer = QuizAnswerDto(questionId: 5, selectedOptionIds: [10]);
      final json = answer.toJson();

      expect(json['questionId'], 5);
      expect(json['selectedOptionIds'], [10]);
    });
  });

  // ============================================================
  // SubmitQuizDto Tests
  // ============================================================
  group('SubmitQuizDto', () {
    test('toJson() serializes answers correctly', () {
      final submit = SubmitQuizDto(
        quizId: 1,
        answers: [
          QuizAnswerDto(questionId: 1, selectedOptionIds: [1]),
          QuizAnswerDto(questionId: 2, textAnswer: 'Answer'),
        ],
      );
      final json = submit.toJson();

      expect(json['quizId'], 1);
      expect(json['answers'], isA<List>());
      expect((json['answers'] as List).length, 2);
    });
  });

  // ============================================================
  // QuizAttemptDto Tests
  // ============================================================
  group('QuizAttemptDto', () {
    test('fromJson() maps userId to studentId', () {
      final json = {
        'id': 1,
        'quizId': 10,
        'quizTitle': 'Test Quiz',
        'userId': 42,
        'score': 85,
        'passed': true,
        'correctAnswers': 8,
        'totalQuestions': 10,
      };
      final attempt = QuizAttemptDto.fromJson(json);

      expect(attempt.id, 1);
      expect(attempt.quizId, 10);
      expect(attempt.quizTitle, 'Test Quiz');
      expect(attempt.studentId, 42); // mapped from 'userId'
      expect(attempt.score, 85);
      expect(attempt.passed, true);
      expect(attempt.correctAnswers, 8);
      expect(attempt.totalQuestions, 10);
    });

    test('fromJson() with passed=false', () {
      final json = {'quizId': 5, 'userId': 1, 'score': 30, 'passed': false};
      final attempt = QuizAttemptDto.fromJson(json);

      expect(attempt.passed, false);
      expect(attempt.score, 30);
    });

    test('toJson() maps studentId back to userId', () {
      final attempt = QuizAttemptDto(
        quizId: 1,
        studentId: 42,
        score: 90,
        passed: true,
      );
      final json = attempt.toJson();

      expect(json['userId'], 42);
      expect(json['quizId'], 1);
    });
  });

  // ============================================================
  // QuizSubmitResponseDto Tests
  // ============================================================
  group('QuizSubmitResponseDto', () {
    test('fromJson() creates correct response', () {
      final json = {
        'score': 85,
        'passed': true,
        'attempt': {
          'id': 1,
          'quizId': 10,
          'userId': 42,
          'score': 85,
          'passed': true,
        },
      };
      final response = QuizSubmitResponseDto.fromJson(json);

      expect(response.score, 85);
      expect(response.passed, true);
      expect(response.attempt.quizId, 10);
      expect(response.attempt.studentId, 42);
    });
  });

  // ============================================================
  // QuizAttemptStatusDto Tests
  // ============================================================
  group('QuizAttemptStatusDto', () {
    test('fromJson() with full status data', () {
      final json = {
        'quizId': 1,
        'userId': 42,
        'attemptsUsed': 2,
        'maxAttempts': 3,
        'canRetry': true,
        'hasPassed': false,
        'bestScore': 65,
        'secondsUntilRetry': 3600,
        'nextRetryAt': '2024-06-01T10:00:00',
        'recentAttempts': [
          {'id': 1, 'quizId': 1, 'userId': 42, 'score': 65, 'passed': false},
        ],
      };
      final status = QuizAttemptStatusDto.fromJson(json);

      expect(status.quizId, 1);
      expect(status.userId, 42);
      expect(status.attemptsUsed, 2);
      expect(status.maxAttempts, 3);
      expect(status.canRetry, true);
      expect(status.hasPassed, false);
      expect(status.bestScore, 65);
      expect(status.secondsUntilRetry, 3600);
      expect(status.nextRetryAt, '2024-06-01T10:00:00');
      expect(status.recentAttempts?.length, 1);
    });

    test('fromJson() with canRetry=false (max attempts reached)', () {
      final json = {
        'quizId': 1,
        'userId': 42,
        'attemptsUsed': 3,
        'maxAttempts': 3,
        'canRetry': false,
        'hasPassed': false,
        'bestScore': 50,
        'secondsUntilRetry': 0,
      };
      final status = QuizAttemptStatusDto.fromJson(json);

      expect(status.canRetry, false);
      expect(status.attemptsUsed, status.maxAttempts);
      expect(status.recentAttempts, isNull);
    });

    test('fromJson() with hasPassed=true', () {
      final json = {
        'quizId': 1,
        'userId': 42,
        'attemptsUsed': 1,
        'maxAttempts': 3,
        'canRetry': true,
        'hasPassed': true,
        'bestScore': 95,
        'secondsUntilRetry': 0,
      };
      final status = QuizAttemptStatusDto.fromJson(json);

      expect(status.hasPassed, true);
      expect(status.bestScore, 95);
    });
  });

  // ============================================================
  // QuizAnswerResultDto Tests
  // ============================================================
  group('QuizAnswerResultDto', () {
    test('fromJson() with correct answer', () {
      final json = {
        'questionId': 1,
        'selectedOptionIds': [2],
        'isCorrect': true,
        'scoreEarned': 10,
      };
      final result = QuizAnswerResultDto.fromJson(json);

      expect(result.questionId, 1);
      expect(result.selectedOptionIds, [2]);
      expect(result.isCorrect, true);
      expect(result.scoreEarned, 10);
    });

    test('fromJson() with incorrect text answer', () {
      final json = {
        'questionId': 3,
        'textAnswer': 'Wrong answer',
        'isCorrect': false,
        'scoreEarned': 0,
      };
      final result = QuizAnswerResultDto.fromJson(json);

      expect(result.isCorrect, false);
      expect(result.scoreEarned, 0);
      expect(result.textAnswer, 'Wrong answer');
    });
  });
}
