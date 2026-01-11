import '../models/mentor_models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

class MentorService {
  final ApiClient _apiClient = ApiClient();

  // ==================== Mentor Discovery ====================

  /// Get all approved mentors
  Future<List<MentorProfile>> getAllMentors() async {
    try {
      final response = await _apiClient.get('/mentors');
      final List<dynamic> data = response.data;
      return data.map((json) => MentorProfile.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get mentor profile by ID
  Future<MentorProfile> getMentorProfile(int mentorId) async {
    try {
      final response = await _apiClient.get('/mentors/$mentorId/profile');
      return MentorProfile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get mentor leaderboard
  Future<List<MentorProfile>> getLeaderboard({int size = 10}) async {
    try {
      final response = await _apiClient.get(
        '/mentors/leaderboard',
        queryParameters: {'size': size},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => MentorProfile.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all unique skills from approved mentors
  Future<List<String>> getAllSkills() async {
    try {
      final response = await _apiClient.get('/mentors/skills');
      final List<dynamic> data = response.data;
      return data.map((e) => e.toString()).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Favorites ====================

  /// Toggle favorite mentor
  Future<void> toggleFavorite(int mentorId) async {
    try {
      await _apiClient.post('/favorites/toggle/$mentorId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Check if mentor is favorite
  Future<bool> checkFavorite(int mentorId) async {
    try {
      final response = await _apiClient.get('/favorites/check/$mentorId');
      return response.data as bool;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get favorite mentors
  Future<List<MentorProfile>> getFavorites() async {
    try {
      final response = await _apiClient.get('/favorites');
      final List<dynamic> data = response.data;
      return data.map((json) => MentorProfile.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Availability ====================

  /// Get mentor availability
  Future<List<MentorAvailability>> getAvailability(
    int mentorId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) {
        queryParams['from'] = from.toIso8601String();
      }
      if (to != null) {
        queryParams['to'] = to.toIso8601String();
      }

      final response = await _apiClient.get(
        '/mentor-availability/$mentorId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => MentorAvailability.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Booking ====================

  /// Create booking intent (for PayOS payment)
  Future<Map<String, dynamic>> createBookingIntent(
    CreateBookingRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        '/mentor-bookings/intent',
        data: request.toJson(),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create booking with wallet payment
  Future<MentorBooking> createBookingWithWallet(
    CreateBookingRequest request,
  ) async {
    try {
      final walletRequest = CreateBookingRequest(
        mentorId: request.mentorId,
        startTime: request.startTime,
        durationMinutes: request.durationMinutes,
        priceVnd: request.priceVnd,
        paymentMethod: 'WALLET',
      );
      final response = await _apiClient.post(
        '/mentor-bookings/wallet',
        data: walletRequest.toJson(),
      );
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my bookings (as learner)
  Future<PageResponse<MentorBooking>> getMyBookings({
    bool mentorView = false,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/mentor-bookings/me',
        queryParameters: {'mentorView': mentorView, 'page': page, 'size': size},
      );
      return PageResponse.fromJson(
        response.data,
        (json) => MentorBooking.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cancel booking
  Future<MentorBooking> cancelBooking(int bookingId) async {
    try {
      final response = await _apiClient.delete('/mentor-bookings/$bookingId');
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Rate booking
  Future<void> rateBooking(
    int bookingId, {
    required int rating,
    String? review,
  }) async {
    try {
      await _apiClient.post(
        '/mentor-bookings/$bookingId/rating',
        data: BookingRatingRequest(rating: rating, review: review).toJson(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download booking invoice
  Future<List<int>> downloadInvoice(int bookingId) async {
    try {
      final response = await _apiClient.get(
        '/mentor-bookings/$bookingId/invoice',
      );
      // Response is base64 encoded PDF
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Pre-Chat ====================

  /// Send pre-chat message
  Future<PreChatMessage> sendPreChatMessage({
    required int mentorId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/prechat/send',
        data: PreChatMessageRequest(
          mentorId: mentorId,
          content: content,
        ).toJson(),
      );
      return PreChatMessage.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat history with mentor
  Future<PageResponse<PreChatMessage>> getChatHistory({
    required int mentorId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/prechat/history',
        queryParameters: {'mentorId': mentorId, 'page': page, 'size': size},
      );
      return PageResponse.fromJson(
        response.data,
        (json) => PreChatMessage.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get conversation with counterpart (2-way)
  Future<PageResponse<PreChatMessage>> getConversation({
    required int counterpartId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/prechat/conversation',
        queryParameters: {
          'counterpartId': counterpartId,
          'page': page,
          'size': size,
        },
      );
      return PageResponse.fromJson(
        response.data,
        (json) => PreChatMessage.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat threads
  Future<List<PreChatThread>> getThreads({int page = 0, int size = 20}) async {
    try {
      final response = await _apiClient.get(
        '/prechat/threads',
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => PreChatThread.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get unread count for a mentor conversation
  Future<int> getUnreadCount(int mentorId) async {
    try {
      final response = await _apiClient.get(
        '/prechat/unread-count',
        queryParameters: {'mentorId': mentorId},
      );
      return response.data as int;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark conversation as read
  Future<void> markAsRead(int counterpartId, bool asMentor) async {
    try {
      await _apiClient.put(
        '/prechat/threads/$counterpartId/mark-read',
        queryParameters: {'asMentor': asMentor},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Hide/delete thread
  Future<void> hideThread(int counterpartId) async {
    try {
      await _apiClient.delete('/prechat/threads/$counterpartId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
