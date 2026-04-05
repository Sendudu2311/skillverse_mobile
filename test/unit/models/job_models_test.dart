import 'package:flutter_test/flutter_test.dart';
import 'package:skillverse_mobile/data/models/job_models.dart';

void main() {
  // ============================================================
  // Enum Tests
  // ============================================================

  group('JobStatus enum', () {
    test('values contain all expected statuses', () {
      expect(JobStatus.values.length, 5);
      expect(JobStatus.values, contains(JobStatus.inProgress));
      expect(JobStatus.values, contains(JobStatus.pendingApproval));
      expect(JobStatus.values, contains(JobStatus.open));
      expect(JobStatus.values, contains(JobStatus.rejected));
      expect(JobStatus.values, contains(JobStatus.closed));
    });
  });

  group('ShortTermJobStatus enum', () {
    test('values contain all expected statuses', () {
      expect(ShortTermJobStatus.values.length, 15);
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.draft));
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.published));
      expect(
        ShortTermJobStatus.values,
        contains(ShortTermJobStatus.inProgress),
      );
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.completed));
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.paid));
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.cancelled));
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.disputed));
      expect(ShortTermJobStatus.values, contains(ShortTermJobStatus.escalated));
    });
  });

  group('JobApplicationStatus enum', () {
    test('values contain all expected statuses', () {
      expect(JobApplicationStatus.values.length, 4);
      expect(
        JobApplicationStatus.values,
        contains(JobApplicationStatus.pending),
      );
      expect(
        JobApplicationStatus.values,
        contains(JobApplicationStatus.reviewed),
      );
      expect(
        JobApplicationStatus.values,
        contains(JobApplicationStatus.accepted),
      );
      expect(
        JobApplicationStatus.values,
        contains(JobApplicationStatus.rejected),
      );
    });
  });

  group('JobUrgency enum', () {
    test('values contain all expected urgency levels', () {
      expect(JobUrgency.values.length, 4);
      expect(JobUrgency.values, contains(JobUrgency.normal));
      expect(JobUrgency.values, contains(JobUrgency.urgent));
      expect(JobUrgency.values, contains(JobUrgency.veryUrgent));
      expect(JobUrgency.values, contains(JobUrgency.asap));
    });
  });

  // ============================================================
  // JobPostingResponse Tests
  // ============================================================

  group('JobPostingResponse', () {
    Map<String, dynamic> fullJobJson() => {
      'id': 1,
      'title': 'Flutter Developer',
      'description': 'Build amazing mobile apps',
      'requiredSkills': ['Flutter', 'Dart', 'Firebase'],
      'minBudget': 5000000.0,
      'maxBudget': 10000000.0,
      'deadline': '2026-04-01',
      'isRemote': true,
      'location': 'Ho Chi Minh',
      'status': 'OPEN',
      'applicantCount': 5,
      'experienceLevel': 'Senior',
      'jobType': 'Full-time',
      'hiringQuantity': 2,
      'benefits': 'Flexible hours, 13th month salary',
      'genderRequirement': null,
      'isNegotiable': true,
      'isHighlighted': false,
      'recruiterCompanyName': 'TechViet',
      'recruiterEmail': 'hr@techviet.com',
      'recruiterUserId': 10,
      'createdAt': '2026-03-01T10:00:00',
      'updatedAt': '2026-03-10T14:00:00',
    };

    test('fromJson() with full data', () {
      final job = JobPostingResponse.fromJson(fullJobJson());

      expect(job.id, 1);
      expect(job.title, 'Flutter Developer');
      expect(job.description, 'Build amazing mobile apps');
      expect(job.requiredSkills, ['Flutter', 'Dart', 'Firebase']);
      expect(job.minBudget, 5000000.0);
      expect(job.maxBudget, 10000000.0);
      expect(job.deadline, '2026-04-01');
      expect(job.remote, true);
      expect(job.location, 'Ho Chi Minh');
      expect(job.status, JobStatus.open);
      expect(job.applicantCount, 5);
      expect(job.experienceLevel, 'Senior');
      expect(job.recruiterCompanyName, 'TechViet');
      expect(job.negotiable, true);
      expect(job.highlighted, false);
    });

    test('fromJson() with minimal data (nulls)', () {
      final json = <String, dynamic>{'id': 2, 'title': 'Backend Dev'};
      final job = JobPostingResponse.fromJson(json);

      expect(job.id, 2);
      expect(job.title, 'Backend Dev');
      expect(job.description, isNull);
      expect(job.requiredSkills, isNull);
      expect(job.minBudget, isNull);
      expect(job.maxBudget, isNull);
      expect(job.status, isNull);
      expect(job.recruiterCompanyName, isNull);
    });

    test('fromJson() with unknown status falls back to open', () {
      final json = fullJobJson();
      json['status'] = 'UNKNOWN_STATUS';
      final job = JobPostingResponse.fromJson(json);

      expect(job.status, JobStatus.open);
    });

    test('toJson() round-trip preserves data', () {
      final original = JobPostingResponse.fromJson(fullJobJson());
      final json = original.toJson();
      final restored = JobPostingResponse.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.minBudget, original.minBudget);
      expect(restored.maxBudget, original.maxBudget);
      expect(restored.status, original.status);
      expect(restored.recruiterCompanyName, original.recruiterCompanyName);
    });
  });

  // ============================================================
  // ShortTermJobResponse Tests
  // ============================================================

  group('ShortTermJobResponse', () {
    Map<String, dynamic> fullShortTermJson() => {
      'id': 10,
      'title': 'Logo Design',
      'description': 'Design a logo for startup',
      'requiredSkills': ['Illustrator', 'Photoshop'],
      'budget': 3000000.0,
      'isNegotiable': true,
      'paymentMethod': 'BANK_TRANSFER',
      'deadline': '2026-04-15T23:59:59',
      'estimatedDuration': '3 ngày',
      'urgency': 'URGENT',
      'startTime': null,
      'isRemote': true,
      'location': null,
      'isHighlighted': true,
      'status': 'PUBLISHED',
      'applicantCount': 3,
      'selectedApplicantId': null,
      'maxApplicants': 10,
      'minRating': 4.0,
      'recruiterId': 5,
      'recruiterInfo': {
        'id': 5,
        'companyName': 'DesignCo',
        'rating': 4.8,
        'totalJobsPosted': 15,
        'completionRate': 0.95,
      },
      'milestones': [
        {
          'id': 1,
          'title': 'Concept',
          'description': 'Initial concepts',
          'amount': 500000.0,
          'order': 1,
        },
        {
          'id': 2,
          'title': 'Final',
          'description': 'Final delivery',
          'amount': 2500000.0,
          'order': 2,
        },
      ],
      'createdAt': '2026-03-01T08:00:00',
      'isExpired': false,
      'canApply': true,
    };

    test('fromJson() with full data', () {
      final job = ShortTermJobResponse.fromJson(fullShortTermJson());

      expect(job.id, 10);
      expect(job.title, 'Logo Design');
      expect(job.budget, 3000000.0);
      expect(job.negotiable, true);
      expect(job.urgency, JobUrgency.urgent);
      expect(job.status, ShortTermJobStatus.published);
      expect(job.remote, true);
      expect(job.highlighted, true);
      expect(job.canApply, true);
      expect(job.expired, false);
      expect(job.applicantCount, 3);
      expect(job.maxApplicants, 10);
      expect(job.minRating, 4.0);
    });

    test('fromJson() parses recruiterInfo correctly', () {
      final job = ShortTermJobResponse.fromJson(fullShortTermJson());

      expect(job.recruiterInfo, isNotNull);
      expect(job.recruiterInfo!.id, 5);
      expect(job.recruiterInfo!.companyName, 'DesignCo');
      expect(job.recruiterInfo!.rating, 4.8);
      expect(job.recruiterInfo!.totalJobsPosted, 15);
      expect(job.recruiterInfo!.completionRate, 0.95);
    });

    test('fromJson() parses milestones correctly', () {
      final job = ShortTermJobResponse.fromJson(fullShortTermJson());

      expect(job.milestones, isNotNull);
      expect(job.milestones!.length, 2);
      expect(job.milestones![0].title, 'Concept');
      expect(job.milestones![0].amount, 500000.0);
      expect(job.milestones![0].order, 1);
      expect(job.milestones![1].title, 'Final');
    });

    test('fromJson() with unknown urgency falls back to normal', () {
      final json = fullShortTermJson();
      json['urgency'] = 'SUPER_URGENT';
      final job = ShortTermJobResponse.fromJson(json);

      expect(job.urgency, JobUrgency.normal);
    });

    test('fromJson() with minimal data (nulls)', () {
      final json = <String, dynamic>{'id': 99};
      final job = ShortTermJobResponse.fromJson(json);

      expect(job.id, 99);
      expect(job.title, isNull);
      expect(job.budget, isNull);
      expect(job.recruiterInfo, isNull);
      expect(job.milestones, isNull);
    });

    test('toJson() round-trip preserves data', () {
      final original = ShortTermJobResponse.fromJson(fullShortTermJson());
      final json = original.toJson();

      // Verify key fields are preserved in toJson output
      expect(json['id'], original.id);
      expect(json['title'], original.title);
      expect(json['budget'], original.budget);
    });
  });

  // ============================================================
  // JobApplicationResponse Tests
  // ============================================================

  group('JobApplicationResponse', () {
    test('fromJson() with full data', () {
      final json = {
        'id': 100,
        'jobId': 1,
        'jobTitle': 'Flutter Developer',
        'userId': 50,
        'userFullName': 'Nguyen Van A',
        'userEmail': 'a@test.com',
        'coverLetter': 'I am a great developer...',
        'appliedAt': '2026-03-05T10:00:00',
        'status': 'PENDING',
        'acceptanceMessage': null,
        'rejectionReason': null,
        'recruiterCompanyName': 'TechViet',
        'minBudget': 5000000.0,
        'maxBudget': 10000000.0,
        'isRemote': true,
        'location': 'Remote',
      };
      final app = JobApplicationResponse.fromJson(json);

      expect(app.id, 100);
      expect(app.jobId, 1);
      expect(app.jobTitle, 'Flutter Developer');
      expect(app.userFullName, 'Nguyen Van A');
      expect(app.status, JobApplicationStatus.pending);
      expect(app.coverLetter, 'I am a great developer...');
      expect(app.minBudget, 5000000.0);
      expect(app.remote, true);
    });

    test('fromJson() accepted application with message', () {
      final json = {
        'id': 101,
        'status': 'ACCEPTED',
        'acceptanceMessage': 'Welcome aboard!',
      };
      final app = JobApplicationResponse.fromJson(json);

      expect(app.status, JobApplicationStatus.accepted);
      expect(app.acceptanceMessage, 'Welcome aboard!');
    });

    test('fromJson() rejected application with reason', () {
      final json = {
        'id': 102,
        'status': 'REJECTED',
        'rejectionReason': 'Not enough experience',
      };
      final app = JobApplicationResponse.fromJson(json);

      expect(app.status, JobApplicationStatus.rejected);
      expect(app.rejectionReason, 'Not enough experience');
    });

    test('fromJson() unknown status falls back to pending', () {
      final json = {'id': 103, 'status': 'BLAH'};
      final app = JobApplicationResponse.fromJson(json);

      expect(app.status, JobApplicationStatus.pending);
    });
  });

  // ============================================================
  // ShortTermApplicationResponse Tests
  // ============================================================

  group('ShortTermApplicationResponse', () {
    test('fromJson() with full data', () {
      final json = {
        'id': 200,
        'jobId': 10,
        'jobTitle': 'Logo Design',
        'jobBudget': 3000000.0,
        'userId': 50,
        'userFullName': 'Nguyen Van B',
        'userEmail': 'b@test.com',
        'userAvatar': 'https://avatar.url',
        'userRating': 4.5,
        'userCompletedJobs': 8,
        'coverLetter': 'I have 3 years experience...',
        'proposedPrice': 2500000.0,
        'proposedDuration': '3 ngày',
        'portfolio': ['https://portfolio1.com', 'https://portfolio2.com'],
        'status': 'APPLIED',
        'appliedAt': '2026-03-05T10:00:00',
        'deliverables': [],
        'revisionCount': 0,
        'jobDetails': {
          'title': 'Logo Design',
          'budget': 3000000.0,
          'deadline': '2026-04-15T23:59:59',
          'recruiterCompanyName': 'DesignCo',
        },
      };
      final app = ShortTermApplicationResponse.fromJson(json);

      expect(app.id, 200);
      expect(app.jobTitle, 'Logo Design');
      expect(app.proposedPrice, 2500000.0);
      expect(app.proposedDuration, '3 ngày');
      expect(app.portfolio, [
        'https://portfolio1.com',
        'https://portfolio2.com',
      ]);
      // APPLIED is not in ShortTermApplicationStatus enum, so it falls back to pending (unknownEnumValue)
      expect(app.status, ShortTermApplicationStatus.pending);
      expect(app.userRating, 4.5);
      expect(app.userCompletedJobs, 8);
    });

    test('fromJson() parses jobDetails correctly', () {
      final json = {
        'id': 201,
        'jobDetails': {
          'title': 'Test Job',
          'budget': 1000000.0,
          'recruiterCompanyName': 'TestCo',
        },
      };
      final app = ShortTermApplicationResponse.fromJson(json);

      expect(app.jobDetails, isNotNull);
      expect(app.jobDetails!.title, 'Test Job');
      expect(app.jobDetails!.budget, 1000000.0);
      expect(app.jobDetails!.recruiterCompanyName, 'TestCo');
    });

    test('fromJson() with minimal data', () {
      final json = <String, dynamic>{'id': 202};
      final app = ShortTermApplicationResponse.fromJson(json);

      expect(app.id, 202);
      expect(app.proposedPrice, isNull);
      expect(app.portfolio, isNull);
      expect(app.jobDetails, isNull);
    });
  });

  // ============================================================
  // Request DTO Tests
  // ============================================================

  group('ApplyJobRequest', () {
    test('fromJson() parses correctly', () {
      final json = {'coverLetter': 'Hello world'};
      final req = ApplyJobRequest.fromJson(json);
      expect(req.coverLetter, 'Hello world');
    });

    test('toJson() includes coverLetter', () {
      final req = ApplyJobRequest(coverLetter: 'My cover letter');
      final json = req.toJson();
      expect(json['coverLetter'], 'My cover letter');
    });

    test('toJson() with null coverLetter', () {
      final req = ApplyJobRequest();
      final json = req.toJson();
      expect(json['coverLetter'], isNull);
    });
  });

  group('ApplyShortTermJobRequest', () {
    test('fromJson() with full data', () {
      final json = {
        'coverLetter': 'I can do this',
        'proposedPrice': 5000000.0,
        'proposedDuration': '1 week',
        'portfolio': ['https://link1.com', 'https://link2.com'],
      };
      final req = ApplyShortTermJobRequest.fromJson(json);

      expect(req.coverLetter, 'I can do this');
      expect(req.proposedPrice, 5000000.0);
      expect(req.proposedDuration, '1 week');
      expect(req.portfolio, ['https://link1.com', 'https://link2.com']);
    });

    test('toJson() round-trip preserves data', () {
      final req = ApplyShortTermJobRequest(
        coverLetter: 'Test',
        proposedPrice: 3000000.0,
        proposedDuration: '5 days',
        portfolio: ['https://p.com'],
      );
      final json = req.toJson();

      expect(json['coverLetter'], 'Test');
      expect(json['proposedPrice'], 3000000.0);
      expect(json['proposedDuration'], '5 days');
      expect(json['portfolio'], ['https://p.com']);
    });
  });

  // ============================================================
  // JobPageResponse Tests
  // ============================================================

  group('JobPageResponse', () {
    test('fromJson() parses paginated short-term jobs', () {
      final json = {
        'content': [
          {'id': 1, 'title': 'Job 1', 'status': 'PUBLISHED'},
          {'id': 2, 'title': 'Job 2', 'status': 'PUBLISHED'},
        ],
        'page': 0,
        'size': 10,
        'totalElements': 2,
        'totalPages': 1,
        'first': true,
        'last': true,
        'empty': false,
      };

      final page = JobPageResponse<ShortTermJobResponse>.fromJson(
        json,
        (obj) => ShortTermJobResponse.fromJson(obj as Map<String, dynamic>),
      );

      expect(page.content?.length, 2);
      expect(page.page, 0);
      expect(page.totalElements, 2);
      expect(page.first, true);
      expect(page.last, true);
      expect(page.content![0].title, 'Job 1');
    });

    test('fromJson() with empty result', () {
      final json = {
        'content': [],
        'page': 0,
        'size': 10,
        'totalElements': 0,
        'totalPages': 0,
        'first': true,
        'last': true,
        'empty': true,
      };

      final page = JobPageResponse<ShortTermJobResponse>.fromJson(
        json,
        (obj) => ShortTermJobResponse.fromJson(obj as Map<String, dynamic>),
      );

      expect(page.content, isEmpty);
      expect(page.empty, true);
      expect(page.totalElements, 0);
    });

    test('fromJson() with missing fields uses defaults', () {
      final json = <String, dynamic>{
        'content': [
          {'id': 1},
        ],
      };

      final page = JobPageResponse<ShortTermJobResponse>.fromJson(
        json,
        (obj) => ShortTermJobResponse.fromJson(obj as Map<String, dynamic>),
      );

      expect(page.content?.length, 1);
      expect(page.page, 0); // default
      expect(page.size, 10); // default
      expect(page.totalPages, 1); // default
    });
  });

  // ============================================================
  // Nested Models Tests
  // ============================================================

  group('RecruiterInfo', () {
    test('fromJson() and toJson() round-trip', () {
      final json = {
        'id': 1,
        'companyName': 'TestCo',
        'rating': 4.5,
        'totalJobsPosted': 20,
        'completionRate': 0.9,
      };
      final info = RecruiterInfo.fromJson(json);

      expect(info.id, 1);
      expect(info.companyName, 'TestCo');
      expect(info.rating, 4.5);

      final output = info.toJson();
      expect(output['companyName'], 'TestCo');
    });
  });

  group('MilestoneResponse', () {
    test('fromJson() with deliverables', () {
      final json = {
        'id': 1,
        'title': 'Phase 1',
        'amount': 1000000.0,
        'order': 1,
        'deliverables': [
          {
            'id': 1,
            'type': 'FILE',
            'fileName': 'design.psd',
            'fileUrl': 'https://cdn.test.com/design.psd',
          },
        ],
      };
      final milestone = MilestoneResponse.fromJson(json);

      expect(milestone.id, 1);
      expect(milestone.title, 'Phase 1');
      expect(milestone.deliverables, isNotNull);
      expect(milestone.deliverables!.length, 1);
      expect(milestone.deliverables![0].fileName, 'design.psd');
    });
  });

  group('RevisionNoteResponse', () {
    test('fromJson() with all fields', () {
      final json = {
        'id': 1,
        'note': 'Please fix colors',
        'specificIssues': ['Wrong blue', 'Font too small'],
        'requestedById': 5,
        'requestedByName': 'Client',
        'requestedAt': '2026-03-10T10:00:00',
      };
      final note = RevisionNoteResponse.fromJson(json);

      expect(note.id, 1);
      expect(note.note, 'Please fix colors');
      expect(note.specificIssues, ['Wrong blue', 'Font too small']);
      expect(note.requestedByName, 'Client');
    });
  });
}
