import 'package:flutter/material.dart';
import '../../data/models/mentor_models.dart';
import '../../data/services/mentor_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

/// Manages mentor discovery, detail, availability, and favorites.
///
/// For booking and pre-chat operations use [MentorBookingProvider].
class MentorProvider with ChangeNotifier, LoadingStateProviderMixin {
  final MentorService _mentorService = MentorService();

  // ==================== State ====================

  List<MentorProfile> _mentors = [];
  List<MentorProfile> _filteredMentors = [];
  List<MentorProfile> _leaderboard = [];
  List<String> _availableSkills = [];

  MentorProfile? _selectedMentor;
  List<MentorAvailability> _availability = [];
  bool _isFavorite = false;

  Set<int> _favoriteMentorIds = {};

  String? _searchQuery;
  String? _skillFilter;

  bool _isLoadingMentors = false;
  bool _isLoadingDetail = false;
  bool _isLoadingAvailability = false;

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

  Set<int> get favoriteMentorIds => _favoriteMentorIds;

  String? get searchQuery => _searchQuery;
  String? get skillFilter => _skillFilter;

  bool get isLoadingMentors => _isLoadingMentors;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingAvailability => _isLoadingAvailability;

  // ==================== Mentor Discovery ====================

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

  Future<void> loadLeaderboard({int size = 10}) async {
    try {
      _leaderboard = await _mentorService.getLeaderboard(size: size);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
  }

  Future<void> loadAvailableSkills() async {
    try {
      _availableSkills = await _mentorService.getAllSkills();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading skills: $e');
    }
  }

  void searchMentors(String query) {
    _searchQuery = query.isEmpty ? null : query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void filterBySkill(String? skill) {
    _skillFilter = skill;
    _applyFilters();
    notifyListeners();
  }

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

  Future<void> loadMentorDetail(int mentorId) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      _selectedMentor = await _mentorService.getMentorProfile(mentorId);
      _isFavorite = await _mentorService.checkFavorite(mentorId);
    } catch (e) {
      setError('Lỗi tải thông tin mentor: ${e.toString()}');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailability(
    int mentorId, {
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoadingAvailability = true;
    notifyListeners();

    try {
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

  Future<void> loadFavorites() async {
    try {
      final favorites = await _mentorService.getFavorites();
      _favoriteMentorIds = favorites.map((m) => m.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  bool isMentorFavorite(int mentorId) => _favoriteMentorIds.contains(mentorId);

  // ==================== Reset ====================

  void reset() {
    _mentors = [];
    _filteredMentors = [];
    _leaderboard = [];
    _availableSkills = [];
    _selectedMentor = null;
    _availability = [];
    _isFavorite = false;
    _favoriteMentorIds = {};
    _searchQuery = null;
    _skillFilter = null;
    _isLoadingMentors = false;
    _isLoadingDetail = false;
    _isLoadingAvailability = false;
    resetState();
    notifyListeners();
  }

  void clearSelectedMentor() {
    _selectedMentor = null;
    _availability = [];
    _isFavorite = false;
    notifyListeners();
  }
}
