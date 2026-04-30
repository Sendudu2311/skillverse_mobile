import 'package:flutter/material.dart';
import '../../data/models/mentor_models.dart';
import '../../data/services/mentor_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/pagination_helper.dart';

/// Manages booking operations and pre-chat messaging with mentors.
/// Use alongside [MentorProvider] for discovery and availability.
class MentorBookingProvider with ChangeNotifier, LoadingStateProviderMixin {
  final MentorService _mentorService = MentorService();

  // Bookings — using PaginationHelper
  late final PaginationHelper<MentorBooking> _bookingsPagination;

  // Pre-chat
  List<PreChatThread> _chatThreads = [];
  List<PreChatMessage> _currentChatMessages = [];
  int _currentChatBookingId = 0;
  bool _isLoadingChat = false;

  MentorBookingProvider() {
    _bookingsPagination = PaginationHelper<MentorBooking>(
      fetchPage: (page) async {
        // PaginationHelper uses 1-based pages; API uses 0-based
        final result = await _mentorService.getMyBookings(
          page: page - 1,
          size: 20,
        );
        return PaginatedResponse(
          data: result.content,
          currentPage:
              result.page + 1, // API is 0-based, PaginationHelper is 1-based
          totalPages: result.totalPages,
          totalItems: result.totalElements,
          hasMore: !result.last,
        );
      },
      onStateChanged: () => notifyListeners(),
    );
  }

  // ==================== Getters ====================

  List<MentorBooking> get bookings => _bookingsPagination.items;
  bool get hasMoreBookings => _bookingsPagination.hasMore;
  bool get isLoadingBookings => _bookingsPagination.isLoading;
  bool get isLoadingBookingsMore => _bookingsPagination.isLoadingMore;

  List<PreChatThread> get chatThreads => _chatThreads;
  List<PreChatMessage> get currentChatMessages => _currentChatMessages;
  int get currentChatBookingId => _currentChatBookingId;
  bool get isLoadingChat => _isLoadingChat;

  // ==================== Booking ====================

  Future<void> loadBookings({bool refresh = false}) async {
    final preservedRoadmapBookings = refresh
        ? bookings
              .where(
                (booking) =>
                    booking.isRoadmapMentoring &&
                    (booking.status == BookingStatus.pending ||
                        booking.status == BookingStatus.confirmed ||
                        booking.status == BookingStatus.mentoringActive),
              )
              .toList()
        : const <MentorBooking>[];

    if (refresh) {
      await _bookingsPagination.refresh();
    } else {
      await _bookingsPagination.loadFirstPage();
    }

    if (refresh && preservedRoadmapBookings.isNotEmpty) {
      final serverIds = bookings.map((booking) => booking.id).toSet();
      for (final booking in preservedRoadmapBookings.reversed) {
        if (!serverIds.contains(booking.id)) {
          _bookingsPagination.insertItem(booking);
          serverIds.add(booking.id);
        }
      }
    }
  }

  Future<void> loadMoreBookings() async {
    await _bookingsPagination.loadNextPage();
  }

  Future<MentorBooking?> createBookingWithWallet({
    required int mentorId,
    required DateTime startTime,
    required int durationMinutes,
    required double priceVnd,
    // V3 Phase 1: optional booking context
    int? journeyId,
    String? nodeId,
    int? nodeSkillId,
    String? bookingType,
  }) async {
    return await executeAsync(() async {
      final request = CreateBookingRequest(
        mentorId: mentorId,
        startTime: startTime,
        durationMinutes: durationMinutes,
        priceVnd: priceVnd,
        paymentMethod: 'WALLET',
        journeyId: journeyId,
        nodeId: nodeId,
        nodeSkillId: nodeSkillId,
        bookingType: bookingType,
      );
      final booking = await _mentorService.createBookingWithWallet(request);
      _bookingsPagination.insertItem(booking);
      notifyListeners();
      return booking;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  // NOTE: createBookingIntent (PayOS) was removed — backend only supports
  // wallet-based booking via POST /mentor-bookings/wallet.

  Future<void> cancelBooking(int bookingId) async {
    await executeAsync(() async {
      final updatedBooking = await _mentorService.cancelBooking(bookingId);
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(index, updatedBooking);
      }
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
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
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(
          index,
          bookings[index].copyWith(status: BookingStatus.completed),
        );
      }
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<void> confirmComplete(int bookingId) async {
    await executeAsync(() async {
      final updatedBooking = await _mentorService.confirmComplete(bookingId);
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(index, updatedBooking);
      }
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  Future<void> refreshBookingDetail(int bookingId) async {
    try {
      final updated = await _mentorService.getBookingDetail(bookingId);
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(index, updated);
      } else {
        // Booking not yet in list (e.g. fresh session / deep link) — insert it
        _bookingsPagination.insertItem(updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing booking detail: $e');
    }
  }

  /// Start the meeting — generates Jitsi link and transitions status to ONGOING
  Future<MentorBooking?> startMeeting(int bookingId) async {
    return await executeAsync(() async {
      final updated = await _mentorService.startMeeting(bookingId);
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(index, updated);
      }
      notifyListeners();
      return updated;
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
  }

  /// Mentor marks booking completed → PENDING_COMPLETION
  Future<void> completeBooking(int bookingId) async {
    await executeAsync(() async {
      final updated = await _mentorService.completeBooking(bookingId);
      final index = _bookingsPagination.findIndex((b) => b.id == bookingId);
      if (index != -1) {
        _bookingsPagination.updateItem(index, updated);
      }
    }, errorMessageBuilder: (e) => ErrorHandler.getErrorMessage(e));
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

  Future<void> loadChatHistory(int bookingId, {bool refresh = false}) async {
    if (refresh || _currentChatBookingId != bookingId) {
      _currentChatMessages = [];
      _currentChatBookingId = bookingId;
    }

    _isLoadingChat = true;
    notifyListeners();

    try {
      final response = await _mentorService.getConversation(
        bookingId: bookingId,
        page: 0,
        size: 50,
      );
      final messages = response.content.toList();
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _currentChatMessages = messages;
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    } finally {
      _isLoadingChat = false;
      notifyListeners();
    }
  }

  Future<bool> sendPreChatMessage(
    int bookingId,
    String content, {
    void Function(PreChatMessage message)? onSent,
  }) async {
    try {
      final message = await _mentorService.sendPreChatMessage(
        bookingId: bookingId,
        content: content,
      );
      _currentChatMessages.insert(0, message);
      notifyListeners();
      onSent?.call(message);
      return true;
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  Future<void> markChatAsRead(int bookingId) async {
    try {
      await _mentorService.markAsRead(bookingId);
      await loadChatThreads();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ==================== Reset ====================

  void reset() {
    _bookingsPagination.reset();
    _chatThreads = [];
    _currentChatMessages = [];
    _currentChatBookingId = 0;
    _isLoadingChat = false;
    resetState();
    notifyListeners();
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => reset();

  @override
  void dispose() {
    _bookingsPagination.dispose();
    super.dispose();
  }
}
