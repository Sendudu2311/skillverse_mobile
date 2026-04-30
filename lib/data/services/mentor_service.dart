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
  // NOTE: PayOS-based booking (/intent) was removed from the backend.
  // Only wallet-based payment (/wallet) is currently supported.

  /// Create booking with wallet payment
  Future<MentorBooking> createBookingWithWallet(
    CreateBookingRequest request,
  ) async {
    try {
      final json = request.toJson();
      // Ensure paymentMethod is WALLET
      json['paymentMethod'] = 'WALLET';
      // Backend expects ZonedDateTime (ISO-8601 with timezone offset).
      // Dart's DateTime.toIso8601String() omits the offset, causing 400.
      // Convert to UTC so the 'Z' suffix is appended.
      json['startTime'] = request.startTime.toUtc().toIso8601String();
      final response = await _apiClient.post(
        '/mentor-bookings/wallet',
        data: json,
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
    required int stars,
    String? comment,
    String? skillEndorsed,
  }) async {
    try {
      await _apiClient.post(
        '/mentor-bookings/$bookingId/rating',
        data: BookingRatingRequest(
          stars: stars,
          comment: comment,
          skillEndorsed: skillEndorsed,
        ).toJson(),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Learner confirms session completion → releases payment to mentor
  Future<MentorBooking> confirmComplete(int bookingId) async {
    try {
      final response = await _apiClient.put(
        '/mentor-bookings/$bookingId/confirm-complete',
      );
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single booking detail
  Future<MentorBooking> getBookingDetail(int bookingId) async {
    try {
      final response = await _apiClient.get('/mentor-bookings/$bookingId');
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get mentor's active bookings for a date range (to detect slot conflicts)
  Future<List<MentorBooking>> getMentorActiveBookings(
    int mentorId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _apiClient.get(
        '/mentor-bookings/mentor/$mentorId/bookings',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      final List<dynamic> data = response.data;
      return data
          .map((json) => MentorBooking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Start meeting — generates Jitsi link and transitions to ONGOING
  Future<MentorBooking> startMeeting(int bookingId) async {
    try {
      final response = await _apiClient.put(
        '/mentor-bookings/$bookingId/start',
      );
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mentor marks booking as complete (PENDING_COMPLETION)
  Future<MentorBooking> completeBooking(int bookingId) async {
    try {
      final response = await _apiClient.put(
        '/mentor-bookings/$bookingId/complete',
      );
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mentor approves a PENDING booking
  Future<MentorBooking> approveBooking(int bookingId) async {
    try {
      final response = await _apiClient.put(
        '/mentor-bookings/$bookingId/approve',
      );
      return MentorBooking.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mentor rejects a PENDING booking
  Future<MentorBooking> rejectBooking(int bookingId, {String? reason}) async {
    try {
      final response = await _apiClient.put(
        '/mentor-bookings/$bookingId/reject',
        queryParameters: reason != null ? {'reason': reason} : null,
      );
      return MentorBooking.fromJson(response.data);
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

  /// Send pre-chat message (requires bookingId)
  Future<PreChatMessage> sendPreChatMessage({
    required int bookingId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/prechat/send',
        data: PreChatMessageRequest(
          bookingId: bookingId,
          content: content,
        ).toJson(),
      );
      return PreChatMessage.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get chat history by booking
  Future<PageResponse<PreChatMessage>> getChatHistory({
    required int bookingId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/prechat/conversation',
        queryParameters: {'bookingId': bookingId, 'page': page, 'size': size},
      );
      return PageResponse.fromJson(
        response.data,
        (json) => PreChatMessage.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get conversation by booking (alias for getChatHistory)
  Future<PageResponse<PreChatMessage>> getConversation({
    required int bookingId,
    int page = 0,
    int size = 50,
  }) async {
    return getChatHistory(bookingId: bookingId, page: page, size: size);
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

  /// Get unread count for a booking conversation
  Future<int> getUnreadCount(int bookingId) async {
    try {
      final response = await _apiClient.get(
        '/prechat/unread-count',
        queryParameters: {'bookingId': bookingId},
      );
      return response.data as int;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark booking conversation as read
  Future<void> markAsRead(int bookingId) async {
    try {
      await _apiClient.put(
        '/prechat/mark-read',
        queryParameters: {'bookingId': bookingId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // hideThread is no longer needed — threads are per-booking

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
