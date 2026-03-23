import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/journey_models.dart';

void main() {
  // ============================================================
  // JourneyType Enum Tests
  // ============================================================
  group('JourneyType enum', () {
    test('contains all expected values', () {
      expect(JourneyType.values.length, 2);
      expect(JourneyType.values, contains(JourneyType.career));
      expect(JourneyType.values, contains(JourneyType.skill));
    });
  });

  // ============================================================
  // JourneyStatus Enum Tests
  // ============================================================
  group('JourneyStatus enum', () {
    test('contains all 10 expected values', () {
      expect(JourneyStatus.values.length, 10);
    });

    test('contains all lifecycle states', () {
      expect(JourneyStatus.values, contains(JourneyStatus.notStarted));
      expect(JourneyStatus.values, contains(JourneyStatus.assessmentPending));
      expect(JourneyStatus.values, contains(JourneyStatus.testInProgress));
      expect(JourneyStatus.values, contains(JourneyStatus.evaluationPending));
      expect(JourneyStatus.values, contains(JourneyStatus.roadmapGenerated));
      expect(
          JourneyStatus.values, contains(JourneyStatus.studyPlanInProgress));
      expect(JourneyStatus.values, contains(JourneyStatus.active));
      expect(JourneyStatus.values, contains(JourneyStatus.completed));
      expect(JourneyStatus.values, contains(JourneyStatus.paused));
      expect(JourneyStatus.values, contains(JourneyStatus.cancelled));
    });
  });

  // ============================================================
  // SkillLevel Enum Tests
  // ============================================================
  group('SkillLevel enum', () {
    test('contains all 5 levels', () {
      expect(SkillLevel.values.length, 5);
      expect(SkillLevel.values, contains(SkillLevel.beginner));
      expect(SkillLevel.values, contains(SkillLevel.elementary));
      expect(SkillLevel.values, contains(SkillLevel.intermediate));
      expect(SkillLevel.values, contains(SkillLevel.advanced));
      expect(SkillLevel.values, contains(SkillLevel.expert));
    });
  });

  // ============================================================
  // TestStatus Enum Tests
  // ============================================================
  group('TestStatus enum', () {
    test('contains all 4 values', () {
      expect(TestStatus.values.length, 4);
      expect(TestStatus.values, contains(TestStatus.pending));
      expect(TestStatus.values, contains(TestStatus.inProgress));
      expect(TestStatus.values, contains(TestStatus.completed));
      expect(TestStatus.values, contains(TestStatus.expired));
    });
  });

  // ============================================================
  // JourneyMilestone Enum Tests
  // ============================================================
  group('JourneyMilestone enum', () {
    test('contains all 8 milestones', () {
      expect(JourneyMilestone.values.length, 8);
      expect(JourneyMilestone.values,
          contains(JourneyMilestone.assessmentCompleted));
      expect(
          JourneyMilestone.values, contains(JourneyMilestone.testGenerated));
      expect(
          JourneyMilestone.values, contains(JourneyMilestone.testCompleted));
      expect(JourneyMilestone.values,
          contains(JourneyMilestone.evaluationCompleted));
      expect(
          JourneyMilestone.values, contains(JourneyMilestone.roadmapCreated));
      expect(JourneyMilestone.values,
          contains(JourneyMilestone.studyPlanCreated));
      expect(JourneyMilestone.values,
          contains(JourneyMilestone.firstNodeCompleted));
      expect(JourneyMilestone.values,
          contains(JourneyMilestone.journeyCompleted));
    });
  });

  // ============================================================
  // StartJourneyRequest Tests
  // ============================================================
  group('StartJourneyRequest', () {
    test('toJson() with all fields', () {
      final request = StartJourneyRequest(
        type: JourneyType.career,
        domain: 'IT',
        goal: 'INTERNSHIP',
        level: 'BEGINNER',
        jobRole: 'FRONTEND',
        subCategory: 'WEB_DEV',
        skills: ['React', 'JavaScript'],
        focusAreas: ['PRACTICAL_CODING'],
        language: 'VI',
        duration: 'STANDARD',
      );
      final json = request.toJson();

      expect(json['type'], 'CAREER');
      expect(json['domain'], 'IT');
      expect(json['goal'], 'INTERNSHIP');
      expect(json['level'], 'BEGINNER');
      expect(json['jobRole'], 'FRONTEND');
      expect(json['subCategory'], 'WEB_DEV');
      expect(json['skills'], ['React', 'JavaScript']);
      expect(json['focusAreas'], ['PRACTICAL_CODING']);
      expect(json['language'], 'VI');
      expect(json['duration'], 'STANDARD');
    });

    test('toJson() with required fields only', () {
      final request = StartJourneyRequest(
        domain: 'DESIGN',
        goal: 'EXPLORE',
        level: 'INTERMEDIATE',
      );
      final json = request.toJson();

      expect(json['domain'], 'DESIGN');
      expect(json['goal'], 'EXPLORE');
      expect(json['level'], 'INTERMEDIATE');
      expect(json['type'], isNull);
      expect(json['jobRole'], isNull);
      expect(json['skills'], isNull);
    });

    test('fromJson() round-trip preserves data', () {
      final original = {
        'type': 'SKILL',
        'domain': 'BUSINESS',
        'goal': 'CAREER_CHANGE',
        'level': 'ADVANCED',
        'skills': ['Marketing', 'SEO'],
      };
      final roundTrip = StartJourneyRequest.fromJson(original).toJson();

      expect(roundTrip['type'], 'SKILL');
      expect(roundTrip['domain'], 'BUSINESS');
      expect(roundTrip['goal'], 'CAREER_CHANGE');
      expect(roundTrip['level'], 'ADVANCED');
      expect(roundTrip['skills'], ['Marketing', 'SEO']);
    });
  });

  // ============================================================
  // SubmitTestRequest Tests
  // ============================================================
  group('SubmitTestRequest', () {
    test('toJson() with answers and time', () {
      final request = SubmitTestRequest(
        testId: 42,
        answers: {'1': 'A', '2': 'C', '3': 'B'},
        timeSpentSeconds: 300,
      );
      final json = request.toJson();

      expect(json['testId'], 42);
      expect(json['answers'], {'1': 'A', '2': 'C', '3': 'B'});
      expect(json['timeSpentSeconds'], 300);
    });

    test('fromJson() round-trip preserves data', () {
      final original = {
        'testId': 10,
        'answers': {'1': 'B'},
      };
      final roundTrip = SubmitTestRequest.fromJson(original).toJson();

      expect(roundTrip['testId'], 10);
      expect(roundTrip['answers'], {'1': 'B'});
      expect(roundTrip['timeSpentSeconds'], isNull);
    });
  });

  // ============================================================
  // MilestoneDto Tests
  // ============================================================
  group('MilestoneDto', () {
    test('fromJson() completed milestone', () {
      final json = {
        'milestone': 'TEST_COMPLETED',
        'isCompleted': true,
        'completedAt': '2026-03-17T10:00:00Z',
      };
      final milestone = MilestoneDto.fromJson(json);

      expect(milestone.milestone, 'TEST_COMPLETED');
      expect(milestone.isCompleted, true);
      expect(milestone.completedAt, '2026-03-17T10:00:00Z');
    });

    test('fromJson() incomplete milestone', () {
      final json = {
        'milestone': 'ROADMAP_CREATED',
        'isCompleted': false,
      };
      final milestone = MilestoneDto.fromJson(json);

      expect(milestone.isCompleted, false);
      expect(milestone.completedAt, isNull);
    });
  });

  // ============================================================
  // TestResultSummaryDto Tests
  // ============================================================
  group('TestResultSummaryDto', () {
    test('fromJson() with all fields', () {
      final json = {
        'resultId': 1,
        'scorePercentage': 78,
        'evaluatedLevel': 'INTERMEDIATE',
        'skillGapsCount': 3,
        'strengthsCount': 5,
        'evaluatedAt': '2026-03-17T12:00:00Z',
      };
      final summary = TestResultSummaryDto.fromJson(json);

      expect(summary.resultId, 1);
      expect(summary.scorePercentage, 78);
      expect(summary.evaluatedLevel, SkillLevel.intermediate);
      expect(summary.skillGapsCount, 3);
      expect(summary.strengthsCount, 5);
      expect(summary.evaluatedAt, '2026-03-17T12:00:00Z');
    });

    test('fromJson() with unknown level defaults to beginner', () {
      final json = {
        'scorePercentage': 50,
        'evaluatedLevel': 'UNKNOWN_LEVEL',
        'skillGapsCount': 0,
        'strengthsCount': 0,
      };
      final summary = TestResultSummaryDto.fromJson(json);

      expect(summary.evaluatedLevel, SkillLevel.beginner);
      expect(summary.resultId, isNull);
    });
  });

  // ============================================================
  // JourneySummaryDto Tests
  // ============================================================
  group('JourneySummaryDto', () {
    test('fromJson() with full data', () {
      final json = {
        'id': 1,
        'type': 'CAREER',
        'domain': 'IT',
        'subCategory': 'WEB_DEV',
        'jobRole': 'FRONTEND',
        'goal': 'INTERNSHIP',
        'status': 'TEST_IN_PROGRESS',
        'currentLevel': 'BEGINNER',
        'progressPercentage': 25,
        'roadmapSessionId': 10,
        'totalNodesCompleted': 3,
        'assessmentTestId': 42,
        'assessmentTestTitle': 'Frontend Test',
        'assessmentTestQuestionCount': 20,
        'assessmentTestStatus': 'IN_PROGRESS',
        'assessmentAttemptCount': 1,
        'maxAssessmentAttempts': 3,
        'remainingAssessmentRetakes': 2,
      };
      final journey = JourneySummaryDto.fromJson(json);

      expect(journey.id, 1);
      expect(journey.type, 'CAREER');
      expect(journey.domain, 'IT');
      expect(journey.subCategory, 'WEB_DEV');
      expect(journey.jobRole, 'FRONTEND');
      expect(journey.goal, 'INTERNSHIP');
      expect(journey.status, JourneyStatus.testInProgress);
      expect(journey.currentLevel, SkillLevel.beginner);
      expect(journey.progressPercentage, 25);
      expect(journey.roadmapSessionId, 10);
      expect(journey.assessmentTestId, 42);
      expect(journey.remainingAssessmentRetakes, 2);
    });

    test('fromJson() with optional fields null', () {
      final json = {
        'id': 2,
        'domain': 'DESIGN',
        'goal': 'EXPLORE',
        'status': 'NOT_STARTED',
        'progressPercentage': 0,
      };
      final journey = JourneySummaryDto.fromJson(json);

      expect(journey.id, 2);
      expect(journey.type, isNull);
      expect(journey.currentLevel, isNull);
      expect(journey.roadmapSessionId, isNull);
      expect(journey.milestones, isNull);
      expect(journey.latestTestResult, isNull);
      expect(journey.assessmentTestId, isNull);
    });

    test('fromJson() with milestones list', () {
      final json = {
        'id': 3,
        'domain': 'IT',
        'goal': 'FROM_SCRATCH',
        'status': 'ACTIVE',
        'progressPercentage': 60,
        'milestones': [
          {
            'milestone': 'ASSESSMENT_COMPLETED',
            'isCompleted': true,
            'completedAt': '2026-03-16T10:00:00Z',
          },
          {
            'milestone': 'ROADMAP_CREATED',
            'isCompleted': true,
            'completedAt': '2026-03-16T11:00:00Z',
          },
          {
            'milestone': 'FIRST_NODE_COMPLETED',
            'isCompleted': false,
          },
        ],
      };
      final journey = JourneySummaryDto.fromJson(json);

      expect(journey.milestones?.length, 3);
      expect(journey.milestones![0].milestone, 'ASSESSMENT_COMPLETED');
      expect(journey.milestones![0].isCompleted, true);
      expect(journey.milestones![2].isCompleted, false);
      expect(journey.milestones![2].completedAt, isNull);
    });

    test('fromJson() with nested latestTestResult', () {
      final json = {
        'id': 4,
        'domain': 'BUSINESS',
        'goal': 'CAREER_CHANGE',
        'status': 'ROADMAP_GENERATED',
        'progressPercentage': 40,
        'latestTestResult': {
          'resultId': 7,
          'scorePercentage': 82,
          'evaluatedLevel': 'ADVANCED',
          'skillGapsCount': 2,
          'strengthsCount': 6,
          'evaluatedAt': '2026-03-17T08:00:00Z',
        },
      };
      final journey = JourneySummaryDto.fromJson(json);

      expect(journey.latestTestResult, isNotNull);
      expect(journey.latestTestResult!.resultId, 7);
      expect(journey.latestTestResult!.scorePercentage, 82);
      expect(journey.latestTestResult!.evaluatedLevel, SkillLevel.advanced);
      expect(journey.latestTestResult!.skillGapsCount, 2);
    });

    test('fromJson() with unknown status defaults to notStarted', () {
      final json = {
        'id': 5,
        'domain': 'IT',
        'goal': 'TEST',
        'status': 'SOME_FUTURE_STATUS',
        'progressPercentage': 0,
      };
      final journey = JourneySummaryDto.fromJson(json);

      expect(journey.status, JourneyStatus.notStarted);
    });
  });

  // ============================================================
  // GenerateTestResponseDto Tests
  // ============================================================
  group('GenerateTestResponseDto', () {
    test('fromJson() with full data', () {
      final json = {
        'journeyId': 1,
        'testId': 42,
        'title': 'Frontend Assessment',
        'description': 'Evaluate your frontend skills',
        'targetField': 'IT',
        'questionCount': 15,
        'timeLimitMinutes': 20,
        'difficultyLevel': 'INTERMEDIATE',
        'questionsJson': '[{"questionId":1,"question":"What is HTML?"}]',
        'message': 'Test generated successfully',
      };
      final response = GenerateTestResponseDto.fromJson(json);

      expect(response.journeyId, 1);
      expect(response.testId, 42);
      expect(response.title, 'Frontend Assessment');
      expect(response.questionCount, 15);
      expect(response.timeLimitMinutes, 20);
      expect(response.questionsJson, isNotNull);
      expect(response.message, 'Test generated successfully');
    });

    test('fromJson() with optional fields null', () {
      final json = <String, dynamic>{};
      final response = GenerateTestResponseDto.fromJson(json);

      expect(response.journeyId, isNull);
      expect(response.testId, isNull);
      expect(response.title, isNull);
      expect(response.questionsJson, isNull);
    });
  });

  // ============================================================
  // AssessmentTestDto Tests
  // ============================================================
  group('AssessmentTestDto', () {
    test('fromJson() with full data', () {
      final json = {
        'id': 42,
        'title': 'Frontend Assessment',
        'description': 'Test your frontend knowledge',
        'targetField': 'IT',
        'status': 'IN_PROGRESS',
        'questionCount': 15,
        'timeLimitMinutes': 20,
        'difficultyLevel': 'INTERMEDIATE',
        'questionsJson': '[{"questionId":1}]',
        'createdAt': '2026-03-17T10:00:00Z',
        'showResults': true,
      };
      final test = AssessmentTestDto.fromJson(json);

      expect(test.id, 42);
      expect(test.title, 'Frontend Assessment');
      expect(test.status, TestStatus.inProgress);
      expect(test.questionCount, 15);
      expect(test.timeLimitMinutes, 20);
      expect(test.showResults, true);
    });

    test('fromJson() without optional fields', () {
      final json = {
        'id': 1,
        'title': 'Basic Test',
        'status': 'PENDING',
      };
      final test = AssessmentTestDto.fromJson(json);

      expect(test.id, 1);
      expect(test.status, TestStatus.pending);
      expect(test.description, isNull);
      expect(test.questionsJson, isNull);
      expect(test.showResults, isNull);
    });

    test('fromJson() with unknown status defaults to pending', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'status': 'UNKNOWN',
      };
      final test = AssessmentTestDto.fromJson(json);

      expect(test.status, TestStatus.pending);
    });
  });

  // ============================================================
  // TestResultDto Tests
  // ============================================================
  group('TestResultDto', () {
    test('fromJson() with full AI evaluation data', () {
      final json = {
        'id': 1,
        'journeyId': 5,
        'assessmentTestId': 42,
        'scorePercentage': 72,
        'evaluatedLevel': 'INTERMEDIATE',
        'skillGapsJson': '[{"skill":"CSS","description":"Need flexbox"}]',
        'strengthsJson': '[{"skill":"HTML","description":"Solid"}]',
        'evaluationSummary': 'Good overall understanding',
        'userAnswersJson': '{"1":"A","2":"C"}',
        'correctAnswersJson': '[{"questionId":1,"correctAnswer":"A"}]',
        'evaluatedAt': '2026-03-17T12:00:00Z',
        'createdAt': '2026-03-17T12:00:00Z',
        'totalQuestions': 15,
        'correctAnswers': 11,
        'incorrectAnswers': 4,
        'answeredQuestions': 15,
        'scoreBand': 'CORE',
        'recommendationMode': 'STANDARD',
        'assessmentConfidence': 85,
        'reassessmentRecommended': false,
      };
      final result = TestResultDto.fromJson(json);

      expect(result.id, 1);
      expect(result.journeyId, 5);
      expect(result.scorePercentage, 72);
      expect(result.evaluatedLevel, SkillLevel.intermediate);
      expect(result.skillGapsJson, isNotNull);
      expect(result.strengthsJson, isNotNull);
      expect(result.totalQuestions, 15);
      expect(result.correctAnswers, 11);
      expect(result.scoreBand, 'CORE');
      expect(result.assessmentConfidence, 85);
      expect(result.reassessmentRecommended, false);
    });

    test('fromJson() with optional fields null', () {
      final json = {
        'id': 2,
        'scorePercentage': 30,
        'evaluatedLevel': 'BEGINNER',
      };
      final result = TestResultDto.fromJson(json);

      expect(result.id, 2);
      expect(result.scorePercentage, 30);
      expect(result.evaluatedLevel, SkillLevel.beginner);
      expect(result.journeyId, isNull);
      expect(result.skillGapsJson, isNull);
      expect(result.totalQuestions, isNull);
      expect(result.scoreBand, isNull);
      expect(result.reassessmentRecommended, isNull);
    });

    test('fromJson() with score boundary values', () {
      // Zero score
      final zeroJson = {
        'id': 3,
        'scorePercentage': 0,
        'evaluatedLevel': 'BEGINNER',
      };
      final zeroResult = TestResultDto.fromJson(zeroJson);
      expect(zeroResult.scorePercentage, 0);

      // Perfect score
      final perfectJson = {
        'id': 4,
        'scorePercentage': 100,
        'evaluatedLevel': 'EXPERT',
      };
      final perfectResult = TestResultDto.fromJson(perfectJson);
      expect(perfectResult.scorePercentage, 100);
      expect(perfectResult.evaluatedLevel, SkillLevel.expert);
    });

    test('toJson() round-trip preserves data', () {
      final original = {
        'id': 10,
        'scorePercentage': 65,
        'evaluatedLevel': 'INTERMEDIATE',
        'totalQuestions': 20,
        'correctAnswers': 13,
        'scoreBand': 'CORE',
      };
      final roundTrip = TestResultDto.fromJson(original).toJson();

      expect(roundTrip['id'], 10);
      expect(roundTrip['scorePercentage'], 65);
      expect(roundTrip['evaluatedLevel'], 'INTERMEDIATE');
      expect(roundTrip['totalQuestions'], 20);
    });
  });
}
