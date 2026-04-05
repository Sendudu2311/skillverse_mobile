import 'package:flutter/material.dart';
import '../../data/models/mentor_models.dart';
import '../../data/services/mentor_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class MentorProvider with ChangeNotifier, LoadingStateProviderMixin {
  final MentorService _mentorService = MentorService();

  // ==================== State ====================

  // Mentor list
  List<MentorProfile> _mentors = [];
  List<MentorProfile> _filteredMentors = [];
  List<MentorProfile> _leaderboard = [];
  List<String> _availableSkills = [];

  // Selected mentor
  MentorProfile? _selectedMentor;
  List<MentorAvailability> _availability = [];
  bool _isFavorite = false;

  // Bookings
  List<MentorBooking> _bookings = [];
  int _bookingsPage = 0;
  bool _hasMoreBookings = true;
  bool _isLoadingBookings = false;

  // Pre-chat
  List<PreChatThread> _chatThreads = [];
  List<PreChatMessage> _currentChatMessages = [];
  int _currentChatMentorId = 0;

  // Favorites
  Set<int> _favoriteMentorIds = {};

  // Filters
  String? _searchQuery;
  String? _skillFilter;

  // Loading states
  bool _isLoadingMentors = false;
  bool _isLoadingDetail = false;
  bool _isLoadingAvailability = false;
  bool _isLoadingChat = false;

  // ==================== Getters ====================

  List<MentorProfile> get mentors =>
      _filteredMentors.isNotEmpty ||
          _searchQuery != null ||
          _skillFilter != null
      ? _filteredMentors
      : _mentors;
  List<MentorProfile> get leaderboard => _leaderboard;
  List<String> get availableSkills => _availableSkills;

  MentorProfile? get selectedMentor => _selectedMentor;
  List<MentorAvailability> get availability => _availability;
  bool get isFavorite => _isFavorite;

  List<MentorBooking> get bookings => _bookings;
  bool get hasMoreBookings => _hasMoreBookings;
  bool get isLoadingBookings => _isLoadingBookings;

  List<PreChatThread> get chatThreads => _chatThreads;
  List<PreChatMessage> get currentChatMessages => _currentChatMessages;
  int get currentChatMentorId => _currentChatMentorId;

  Set<int> get favoriteMentorIds => _favoriteMentorIds;

  String? get searchQuery => _searchQuery;
  String? get skillFilter => _skillFilter;

  bool get isLoadingMentors => _isLoadingMentors;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingAvailability => _isLoadingAvailability;
  bool get isLoadingChat => _isLoadingChat;

  // ==================== Mentor Discovery ====================

  /// Load all mentors
  Future<void> loadMentors({bool refresh = false}) async {
    if (_isLoadingMentors) return;

    if (!refresh && _mentors.isNotEmpty) return;

    _isLoadingMentors = true;
    notifyListeners();

    try {
      _mentors = await _mentorService.getAllMentors();
      _applyFilters();
    } catch (e) {
      setError('Lỗi tải danh sách mentor: ${e.toString()}');
    } finally {
      _isLoadingMentors = false;
      notifyListeners();
    }
  }

  /// Load mentor leaderboard
  Future<void> loadLeaderboard({int size = 10}) async {
    try {
      _leaderboard = await _mentorService.getLeaderboard(size: size);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
  }

  /// Load available skills
  Future<void> loadAvailableSkills() async {
    try {
      _availableSkills = await _mentorService.getAllSkills();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading skills: $e');
    }
  }

  /// Search mentors
  void searchMentors(String query) {
    _searchQuery = query.isEmpty ? null : query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Filter by skill
  void filterBySkill(String? skill) {
    _skillFilter = skill;
    _applyFilters();
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = null;
    _skillFilter = null;
    _filteredMentors = [];
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = List<MentorProfile>.from(_mentors);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = m.fullName.toLowerCase();
        final spec = (m.specialization ?? '').toLowerCase();
        final skills = m.skills?.join(' ').toLowerCase() ?? '';
        return name.contains(_searchQuery!) ||
            spec.contains(_searchQuery!) ||
            skills.contains(_searchQuery!);
      }).toList();
    }

    if (_skillFilter != null && _skillFilter!.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.skills?.any(
              (s) => s.toLowerCase().contains(_skillFilter!.toLowerCase()),
            ) ??
            false;
      }).toList();
    }

    _filteredMentors = filtered;
  }

  // ==================== Mentor Detail ====================

  /// Load mentor detail
  Future<void> loadMentorDetail(int mentorId) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      _selectedMentor = await _mentorService.getMentorProfile(mentorId);
      // Check if favorite
      _isFavorite = await _mentorService.checkFavorite(mentorId);
    } catch (e) {
      setError('Lỗi tải thông tin mentor: ${e.toString()}');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Load mentor availability for a date range
  Future<void> loadAvailability(
    int mentorId, {
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoadingAvailability = true;
    notifyListeners();

    try {
      // Default to next 7 days if not specified
      final startDate = from ?? DateTime.now();
      final endDate = to ?? startDate.add(const Duration(days: 7));

      _availability = await _mentorService.getAvailability(
        mentorId,
        from: startDate,
        to: endDate,
      );
    } catch (e) {
      debugPrint('Error loading availability: $e');
      _availability = [];
    } finally {
      _isLoadingAvailability = false;
      notifyListeners();
    }
  }

  /// Get availability for a specific date
  List<MentorAvailability> getAvailabilityForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _availability.where((a) {
      final availDate = DateTime(
        a.startTime.year,
        a.startTime.month,
        a.startTime.day,
      );
      return availDate == dateOnly;
    }).toList();
  }

  // ==================== Favorites ====================

  /// Toggle favorite
  Future<void> toggleFavorite(int mentorId) async {
    try {
      await _mentorService.toggleFavorite(mentorId);

      if (_favoriteMentorIds.contains(mentorId)) {
        _favoriteMentorIds.remove(mentorId);
        _isFavorite = false;
      } else {
        _favoriteMentorIds.add(mentorId);
        _isFavorite = true;
      }
      notifyListeners();
    } catch (e) {
      setError('Lỗi cập nhật yêu thích: ${e.toString()}');
    }
  }

  /// Load favorites
  Future<void> loadFavorites() async {
    try {
      final favorites = await _mentorService.getFavorites();
      _favoriteMentorIds = favorites.map((m) => m.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  /// Check if mentor is favorite
  bool isMentorFavorite(int mentorId) => _favoriteMentorIds.contains(mentorId);

  // ==================== Booking ====================

  /// Load user's bookings
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

  /// Create booking with wallet
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

  /// Create booking intent for PayOS
  Future<String?> createBookingIntent({
    required int mentorId,
    required DateTime startTime,
    required int durationMinutes,
    required double priceVnd,
    String? successUrl,
    String? cancelUrl,
  }) async {
    return await executeAsync(() async {
      final request = CreateBookingRequest(
        mentorId: mentorId,
        startTime: startTime,
        durationMinutes: durationMinutes,
        priceVnd: priceVnd,
        paymentMethod: 'PAYOS',
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      final response = await _mentorService.createBookingIntent(request);
      // Return checkout URL
      return response['checkoutUrl'] as String? ?? '';
    }, errorMessageBuilder: (e) => 'Lỗi tạo thanh toán: ${e.toString()}');
  }

  /// Cancel booking
  Future<void> cancelBooking(int bookingId) async {
    await executeAsync(() async {
      final updatedBooking = await _mentorService.cancelBooking(bookingId);

      // Update in list
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi hủy booking: ${e.toString()}');
  }

  /// Rate booking
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

      // Update booking status
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: BookingStatus.completed,
        );
        notifyListeners();
      }
    }, errorMessageBuilder: (e) => 'Lỗi đánh giá: ${e.toString()}');
  }

  /// Learner confirms session completion → releases payment
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

  /// Refresh single booking detail from server
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

  /// Load chat threads
  Future<void> loadChatThreads() async {
    try {
      _chatThreads = await _mentorService.getThreads();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat threads: $e');
    }
  }

  /// Load chat history with mentor
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

  /// Send pre-chat message
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

  /// Mark conversation as read
  Future<void> markChatAsRead(int counterpartId) async {
    try {
      await _mentorService.markAsRead(counterpartId, false);

      // Update thread unread count
      final index = _chatThreads.indexWhere(
        (t) => t.counterpartId == counterpartId,
      );
      if (index != -1) {
        // Thread doesn't have copyWith, so we reload
        await loadChatThreads();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ==================== Reset ====================

  /// Reset all state
  void reset() {
    _mentors = [];
    _filteredMentors = [];
    _leaderboard = [];
    _availableSkills = [];
    _selectedMentor = null;
    _availability = [];
    _isFavorite = false;
    _bookings = [];
    _bookingsPage = 0;
    _hasMoreBookings = true;
    _chatThreads = [];
    _currentChatMessages = [];
    _currentChatMentorId = 0;
    _favoriteMentorIds = {};
    _searchQuery = null;
    _skillFilter = null;
    _isLoadingMentors = false;
    _isLoadingDetail = false;
    _isLoadingAvailability = false;
    _isLoadingChat = false;
    resetState();
    notifyListeners();
  }

  /// Clear selected mentor
  void clearSelectedMentor() {
    _selectedMentor = null;
    _availability = [];
    _isFavorite = false;
    notifyListeners();
  }
}
