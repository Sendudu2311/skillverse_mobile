import '../../data/models/job_models.dart';
import '../../data/models/interview_models.dart';

/// Extensions that return the backend-style UPPER_SNAKE_CASE string
/// matching each enum's @JsonValue annotation.
///
/// Use these instead of `.name` when passing to StatusBadge or timeline
/// widgets, which expect backend format (e.g. 'INTERVIEW_SCHEDULED',
/// not 'interviewScheduled').
extension JobApplicationStatusX on JobApplicationStatus {
  String toApiString() => switch (this) {
        JobApplicationStatus.pending => 'PENDING',
        JobApplicationStatus.reviewed => 'REVIEWED',
        JobApplicationStatus.interviewScheduled => 'INTERVIEW_SCHEDULED',
        JobApplicationStatus.interviewed => 'INTERVIEWED',
        JobApplicationStatus.offerSent => 'OFFER_SENT',
        JobApplicationStatus.offerAccepted => 'OFFER_ACCEPTED',
        JobApplicationStatus.offerRejected => 'OFFER_REJECTED',
        JobApplicationStatus.accepted => 'ACCEPTED',
        JobApplicationStatus.contractSigned => 'CONTRACT_SIGNED',
        JobApplicationStatus.rejected => 'REJECTED',
      };
}

extension ShortTermApplicationStatusX on ShortTermApplicationStatus {
  String toApiString() => switch (this) {
        ShortTermApplicationStatus.pending => 'PENDING',
        ShortTermApplicationStatus.accepted => 'ACCEPTED',
        ShortTermApplicationStatus.rejected => 'REJECTED',
        ShortTermApplicationStatus.working => 'WORKING',
        ShortTermApplicationStatus.inProgress => 'IN_PROGRESS',
        ShortTermApplicationStatus.submitted => 'SUBMITTED',
        ShortTermApplicationStatus.underReview => 'UNDER_REVIEW',
        ShortTermApplicationStatus.submittedOverdue => 'SUBMITTED_OVERDUE',
        ShortTermApplicationStatus.revisionRequired => 'REVISION_REQUIRED',
        ShortTermApplicationStatus.revisionResponseOverdue =>
          'REVISION_RESPONSE_OVERDUE',
        ShortTermApplicationStatus.cancellationRequested =>
          'CANCELLATION_REQUESTED',
        ShortTermApplicationStatus.autoCancelled => 'AUTO_CANCELLED',
        ShortTermApplicationStatus.disputeOpened => 'DISPUTE_OPENED',
        ShortTermApplicationStatus.approved => 'APPROVED',
        ShortTermApplicationStatus.completed => 'COMPLETED',
        ShortTermApplicationStatus.paid => 'PAID',
        ShortTermApplicationStatus.cancelled => 'CANCELLED',
        ShortTermApplicationStatus.withdrawn => 'WITHDRAWN',
      };
}

extension InterviewStatusX on InterviewStatus {
  String toApiString() => switch (this) {
        InterviewStatus.pending => 'PENDING',
        InterviewStatus.confirmed => 'CONFIRMED',
        InterviewStatus.cancelled => 'CANCELLED',
        InterviewStatus.completed => 'COMPLETED',
        InterviewStatus.noShow => 'NO_SHOW',
      };
}
