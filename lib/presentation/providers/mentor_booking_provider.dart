import 'package:flutter/material.dart';
import '../../data/models/mentor_models.dart';
import '../../data/services/mentor_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Manages booking operations and pre-chat messaging with mentors.
/// Use alongside [MentorProvider] for discovery and availability.
class MentorBookingProvider with ChangeNotifier, LoadingStateProviderMixin {
  final MentorService _mentorService = MentorService();

  // Bookings
  List<MentorBooking> _bookings = [];
  int _bookingsPage = 0;
  bool _hasMoreBookings = true;
  bool _isLoadingBookings = false;

  // Pre-chat
  List<PreChatThread> _chatThreads = [];
  List<PreChatMessage> _currentChatMessages = [];
  int _currentChatMentorId = 0;
  bool _isLoadingChat = false;

  // ==================== Getters ====================

  List<MentorBooking> get bookings => _bookings;
  bool get hasMoreBookings => _hasMoreBookings;
  bool get isLoadingBookings => _isLoadingBookings;

  List<PreChatThread> get chatThreads => _chatThreads;
  List<PreChatMessage> get currentChatMessages => _currentChatMessages;
  int get currentChatMentorId => _currentChatMentorId;
  bool get isLoadingChat => _isLoadingChat;

  // ==================== Booking ====================

  Future<void> loadBookings({bool refresh = false}) async {
    if (_isLoadingBookings) return;

    if (refresh) {
      _bookingsPage = 0;
      _bookings = [];
      _hasMoreBookings = true;
    }

    if (!_hasMoreBookings) return;

    _isLoadingBookings = true;
    notifyListeners();

    try {
      final response = await _mentorService.getMyBookings(
        page: _bookingsPage,
        size: 20,
      );
      _bookings.addAll(response.content);
      _hasMoreBookings = !response.last;
      _bookingsPage++;
    } catch (e) {
      setError('Lỗi tải danh sách booking: ${e.toString()}');
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<MentorBooking?> createBookingWithWallet({
    required int mentorId,
    required DateTime startTime,
    required int durationMinutes,
    required double priceVnd,
  }) async {
    return await executeAsync(() async {
      final request = CreateBookingRequest(
        mentorId: mentorId,
        startTime: startTime,
        durationMinutes: durationMinutes,
        priceVnd: priceVnd,
        paymentMethod: 'WALLET',
      );
      final booking = await _mentorService.createBookingWithWallet(request);
      _bookings.insert(0, booking);
      notifyListeners();
      return booking;
    }, errorMessageBuilder: (e) => 'Lỗi đặt lịch: ${e.toString()}');
  }

  // NOTE: createBookingIntent (PayOS) was removed — backend only supports
  // wallet-based booking via POST /mentor-bookings/wallet.

  Future<void> cancelBooking(int bookingId) async {
    await executeAsync(() async {
      final updatedBooking = await _mentorService.cancelBooking(bookingId);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi hủy booking: ${e.toString()}');
  }

  Future<void> rateBooking(
    int bookingId,
    int stars, {
    String? comment,
    String? skillEndorsed,
  }) async {
    await executeAsync(() async {
      await _mentorService.rateBooking(
        bookingId,
        stars: stars,
        comment: comment,
        skillEndorsed: skillEndorsed,
      );
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: BookingStatus.completed,
        );
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi đánh giá: ${e.toString()}');
  }

  Future<void> confirmComplete(int bookingId) async {
    await executeAsync(() async {
      final updatedBooking = await _mentorService.confirmComplete(bookingId);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi xác nhận hoàn thành: ${e.toString()}');
  }

  Future<void> refreshBookingDetail(int bookingId) async {
    try {
      final updated = await _mentorService.getBookingDetail(bookingId);
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing booking detail: $e');
    }
  }

  // ==================== Pre-Chat ====================

  Future<void> loadChatThreads() async {
    try {
      _chatThreads = await _mentorService.getThreads();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat threads: $e');
    }
  }

  Future<void> loadChatHistory(int mentorId, {bool refresh = false}) async {
    if (refresh || _currentChatMentorId != mentorId) {
      _currentChatMessages = [];
      _currentChatMentorId = mentorId;
    }

    _isLoadingChat = true;
    notifyListeners();

    try {
      final response = await _mentorService.getConversation(
        counterpartId: mentorId,
        page: 0,
        size: 50,
      );
      _currentChatMessages = response.content.reversed.toList();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      _isLoadingChat = false;
      notifyListeners();
    }
  }

  Future<bool> sendPreChatMessage(int mentorId, String content) async {
    try {
      final message = await _mentorService.sendPreChatMessage(
        mentorId: mentorId,
        content: content,
      );
      _currentChatMessages.add(message);
      notifyListeners();
      return true;
    } catch (e) {
      setError('Lỗi gửi tin nhắn: ${e.toString()}');
      return false;
    }
  }

  Future<void> markChatAsRead(int counterpartId) async {
    try {
      await _mentorService.markAsRead(counterpartId, false);
      await loadChatThreads();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ==================== Reset ====================

  void reset() {
    _bookings = [];
    _bookingsPage = 0;
    _hasMoreBookings = true;
    _chatThreads = [];
    _currentChatMessages = [];
    _currentChatMentorId = 0;
    _isLoadingBookings = false;
    _isLoadingChat = false;
    resetState();
    notifyListeners();
  }
}
