import '../models/booking_dispute_models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

/// Service for Booking Dispute API endpoints.
/// Endpoints: POST /booking-disputes, GET /booking-disputes/{id}, etc.
class BookingDisputeService {
  final ApiClient _apiClient = ApiClient();

  // ==================== User Endpoints ====================

  /// Open a dispute for a booking
  /// POST /api/booking-disputes?bookingId={id}&reason={reason}
  Future<BookingDisputeDto> openDispute({
    required int bookingId,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '/booking-disputes',
        queryParameters: {'bookingId': bookingId, 'reason': reason},
      );
      return BookingDisputeDto.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get dispute by ID
  /// GET /api/booking-disputes/{disputeId}
  Future<BookingDisputeDto> getDispute(int disputeId) async {
    try {
      final response = await _apiClient.get('/booking-disputes/$disputeId');
      return BookingDisputeDto.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get dispute by booking ID
  /// GET /api/booking-disputes/booking/{bookingId}
  Future<BookingDisputeDto?> getDisputeByBooking(int bookingId) async {
    try {
      final response = await _apiClient.get(
        '/booking-disputes/booking/$bookingId',
      );
      return BookingDisputeDto.fromJson(response.data);
    } catch (e) {
      // 404 means no dispute exists for this booking
      if (e.toString().contains('404')) return null;
      throw _handleError(e);
    }
  }

  /// Submit evidence for a dispute
  /// POST /api/booking-disputes/{disputeId}/evidence
  Future<BookingDisputeEvidenceDto> submitEvidence({
    required int disputeId,
    required EvidenceType type,
    String? content,
    String? fileUrl,
    String? fileName,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '/booking-disputes/$disputeId/evidence',
        queryParameters: {
          'type': type.toValue(),
          if (content != null) 'content': content,
          if (fileUrl != null) 'fileUrl': fileUrl,
          if (fileName != null) 'fileName': fileName,
          if (description != null) 'description': description,
        },
      );
      return BookingDisputeEvidenceDto.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get evidence for a dispute
  /// GET /api/booking-disputes/{disputeId}/evidence
  Future<List<BookingDisputeEvidenceDto>> getEvidence(int disputeId) async {
    try {
      final response = await _apiClient.get(
        '/booking-disputes/$disputeId/evidence',
      );
      final List<dynamic> data = response.data;
      return data
          .map(
            (json) => BookingDisputeEvidenceDto.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Respond to evidence
  /// POST /api/booking-disputes/{disputeId}/respond?evidenceId={id}&content={content}
  Future<BookingDisputeResponseDto> respondToEvidence({
    required int disputeId,
    required int evidenceId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/booking-disputes/$disputeId/respond',
        queryParameters: {'evidenceId': evidenceId, 'content': content},
      );
      return BookingDisputeResponseDto.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
