import '../models/booking_review_model.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

class BookingReviewService {
  final ApiClient _apiClient = ApiClient();

  /// Create a review for a booking
  Future<BookingReview> createReview(
    int bookingId, {
    required int rating,
    required String comment,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/reviews/booking/$bookingId',
        data: CreateBookingReviewRequest(
          rating: rating,
          comment: comment,
          isAnonymous: isAnonymous,
        ).toJson(),
      );
      return BookingReview.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get review for a specific booking
  Future<BookingReview?> getReviewByBookingId(int bookingId) async {
    try {
      final response = await _apiClient.get('/reviews/booking/$bookingId');
      return BookingReview.fromJson(response.data);
    } catch (e) {
      // 404 = no review yet
      if (e.toString().contains('404')) return null;
      throw _handleError(e);
    }
  }

  /// Get all reviews written by the student
  Future<List<BookingReview>> getMyStudentReviews() async {
    try {
      final response = await _apiClient.get('/reviews/student/me');
      final List<dynamic> data = response.data;
      return data
          .map((json) => BookingReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get public reviews for a mentor
  Future<List<BookingReview>> getMentorReviews(int mentorId) async {
    try {
      final response = await _apiClient.get('/reviews/mentor/$mentorId');
      final List<dynamic> data = response.data;
      return data
          .map((json) => BookingReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
