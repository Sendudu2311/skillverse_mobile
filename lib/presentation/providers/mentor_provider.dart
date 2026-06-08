import 'package:flutter/material.dart';
import '../../data/models/mentor_models.dart';
import '../../data/models/mentor_eligibility_models.dart';
import '../../data/services/mentor_eligibility_service.dart';
import '../../data/services/mentor_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/string_helper.dart';

/// Manages mentor discovery, detail, availability, and favorites.
///
/// For booking and pre-chat operations use [MentorBookingProvider].
class MentorProvider with ChangeNotifier, LoadingStateProviderMixin {
  final MentorService _mentorService = MentorService();
  final MentorEligibilityService _eligibilityService =
      MentorEligibilityService();

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
  String? _contextSkillName;
  bool _showVerifiedOnly = true;

  bool _isLoadingMentors = false;
  bool _isLoadingDetail = false;
  bool _isLoadingAvailability = false;
  bool _isEnrichingVerifiedSkills = false;
  bool _isLoadingEligibility = false;
  bool _roadmapContextMode = false;
  int? _contextJourneyId;
  int? _contextRoadmapSessionId;
  String? _contextNodeId;
  Map<int, MentorTeachingEligibilityResponse> _eligibilityByMentorId = {};

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
  bool get showVerifiedOnly => _showVerifiedOnly;
  bool get isEnrichingVerifiedSkills => _isEnrichingVerifiedSkills;
  bool get isLoadingEligibility => _isLoadingEligibility;
  String? get contextSkillName => _contextSkillName;
  Map<int, MentorTeachingEligibilityResponse> get eligibilityByMentorId =>
      _eligibilityByMentorId;

  MentorTeachingEligibilityResponse? eligibilityFor(int mentorId) =>
      _eligibilityByMentorId[mentorId];

  /// Normalize skill name to match backend SkillNameUtils logic.
  /// Strips non-alphanumeric → collapses → UPPERCASE.
  static String _normalizeSkill(String raw) {
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  // ==================== Mentor Discovery ====================

  Future<void> loadMentors({bool refresh = false}) async {
    if (_isLoadingMentors) return;
    if (!refresh && _mentors.isNotEmpty) return;

    _isLoadingMentors = true;
    notifyListeners();

    try {
      _mentors = await _mentorService.getAllMentors();
      _applyFilters();
      _enrichVerifiedSkills(); // fire-and-forget parallel enrichment
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
    } finally {
      _isLoadingMentors = false;
      notifyListeners();
    }
  }

  Future<void> loadRoadmapMentors({
    required int? journeyId,
    required int? roadmapSessionId,
    required String? skillName,
    String? nodeId,
    bool refresh = false,
  }) async {
    if (_isLoadingMentors) return;
    if (!refresh &&
        _roadmapContextMode &&
        _mentors.isNotEmpty &&
        _contextJourneyId == journeyId &&
        _contextRoadmapSessionId == roadmapSessionId &&
        _contextSkillName == skillName &&
        _contextNodeId == nodeId) {
      return;
    }

    _roadmapContextMode = true;
    _contextJourneyId = journeyId;
    _contextRoadmapSessionId = roadmapSessionId;
    _contextNodeId = nodeId;
    _contextSkillName = skillName?.trim();
    _showVerifiedOnly = false;
    _isLoadingMentors = true;
    _isLoadingEligibility = true;
    _eligibilityByMentorId = {};
    notifyListeners();

    try {
      List<MentorProfile> candidates = [];
      if (skillName != null && skillName.trim().isNotEmpty) {
        try {
          candidates = await _mentorService.getMentorsByVerifiedSkill(
            skillName.trim(),
          );
        } catch (e) {
          debugPrint('Verified-skill mentor lookup failed: $e');
        }
      }

      if (candidates.isEmpty) {
        final allMentors = await _mentorService.getAllMentors();
        candidates = allMentors
            .where((m) => m.canOfferRoadmapMentoring)
            .toList();
      } else {
        candidates = candidates
            .where((m) => m.canOfferRoadmapMentoring)
            .toList();
      }

      _mentors = _dedupeMentors(candidates);
      _applyFilters();
      notifyListeners();

      await _loadEligibilityForCurrentMentors();
      _enrichVerifiedSkills();
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
    } finally {
      _isLoadingMentors = false;
      _isLoadingEligibility = false;
      _applyFilters();
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
    _showVerifiedOnly = true;
    _filteredMentors = [];
    notifyListeners();
  }

  void toggleVerifiedFilter() {
    _showVerifiedOnly = !_showVerifiedOnly;
    _applyFilters();
    notifyListeners();
  }

  /// Set context skill from roadmap/journey navigation.
  /// Mentors with this verified skill will be sorted to the top.
  void setContextSkill(String skillName) {
    _contextSkillName = skillName.trim();
  }

  void clearContextSkill() {
    _contextSkillName = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = List<MentorProfile>.from(_mentors);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = StringHelper.removeDiacritics(_searchQuery!.toLowerCase());
      filtered = filtered.where((m) {
        normalize(String s) => StringHelper.removeDiacritics(s.toLowerCase());
        return normalize(m.fullName).contains(q) ||
            normalize(m.specialization ?? '').contains(q) ||
            normalize(m.skills?.join(' ') ?? '').contains(q);
      }).toList();
    }

    if (_skillFilter != null && _skillFilter!.isNotEmpty) {
      final f = StringHelper.removeDiacritics(_skillFilter!.toLowerCase());
      filtered = filtered.where((m) {
        return m.skills?.any(
              (s) => StringHelper.removeDiacritics(s.toLowerCase()).contains(f),
            ) ??
            false;
      }).toList();
    }

    // Verified skills filter — only apply when enrichment has completed
    if (_showVerifiedOnly && !_isEnrichingVerifiedSkills) {
      filtered = filtered.where((m) => m.hasVerifiedSkills).toList();
    }

    if (_roadmapContextMode) {
      filtered = filtered.where((m) {
        final eligibility = _eligibilityByMentorId[m.id];
        return eligibility?.summaryStatus !=
            TeachingEligibilityStatus.notEligible;
      }).toList();
    }

    _filteredMentors = filtered;

    // Sort: mentors with context skill match first
    if (_contextSkillName != null && _contextSkillName!.isNotEmpty) {
      final normalizedContext = _normalizeSkill(_contextSkillName!);
      _filteredMentors.sort((a, b) {
        final aMatch =
            a.verifiedSkills?.any(
              (s) => _normalizeSkill(s) == normalizedContext,
            ) ??
            false;
        final bMatch =
            b.verifiedSkills?.any(
              (s) => _normalizeSkill(s) == normalizedContext,
            ) ??
            false;
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0; // keep original order within same group
      });
    }

    if (_roadmapContextMode) {
      _filteredMentors.sort((a, b) {
        final aEligibility = _eligibilityByMentorId[a.id];
        final bEligibility = _eligibilityByMentorId[b.id];
        final statusCompare = (bEligibility?.summaryStatus.sortWeight ?? 1)
            .compareTo(aEligibility?.summaryStatus.sortWeight ?? 1);
        if (statusCompare != 0) return statusCompare;
        return (bEligibility?.overallMatchPercent ?? 0).compareTo(
          aEligibility?.overallMatchPercent ?? 0,
        );
      });
    }
  }

  List<MentorProfile> _dedupeMentors(List<MentorProfile> mentors) {
    final byId = <int, MentorProfile>{};
    for (final mentor in mentors) {
      byId[mentor.id] = mentor;
    }
    return byId.values.toList();
  }

  Future<void> _loadEligibilityForCurrentMentors() async {
    if (!_roadmapContextMode || _mentors.isEmpty) return;
    if (_contextJourneyId == null && _contextRoadmapSessionId == null) return;

    final futures = _mentors.take(8).map((mentor) async {
      try {
        final eligibility = _contextJourneyId != null
            ? await _eligibilityService.evaluateJourney(
                journeyId: _contextJourneyId!,
                mentorId: mentor.id,
                nodeId: _contextNodeId,
              )
            : await _eligibilityService.evaluateRoadmap(
                roadmapSessionId: _contextRoadmapSessionId!,
                mentorId: mentor.id,
                nodeId: _contextNodeId,
              );
        return MapEntry(mentor.id, eligibility);
      } catch (e) {
        debugPrint('Mentor eligibility check failed for ${mentor.id}: $e');
        return MapEntry(
          mentor.id,
          MentorTeachingEligibilityResponse.needsReview(mentor.id),
        );
      }
    });

    final entries = await Future.wait(futures);
    _eligibilityByMentorId =
        Map<int, MentorTeachingEligibilityResponse>.fromEntries(entries);
  }

  /// Enrich all mentors with verified skills data in parallel.
  /// Called fire-and-forget after loadMentors() completes.
  Future<void> _enrichVerifiedSkills() async {
    if (_mentors.isEmpty) return;
    _isEnrichingVerifiedSkills = true;
    notifyListeners();

    try {
      final futures = _mentors.map((m) async {
        try {
          final skills = await _mentorService.getVerifiedSkillsByMentorId(m.id);
          return m.copyWith(verifiedSkills: skills);
        } catch (_) {
          return m.copyWith(verifiedSkills: []);
        }
      });
      _mentors = await Future.wait(futures);
    } finally {
      _isEnrichingVerifiedSkills = false;
      _applyFilters();
      notifyListeners();
    }
  }

  // ==================== Mentor Detail ====================

  Future<void> loadMentorDetail(int mentorId) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      _selectedMentor = await _mentorService.getMentorProfile(mentorId);
      _isFavorite = await _mentorService.checkFavorite(mentorId);
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
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

      final results = await Future.wait([
        _mentorService.getAvailability(mentorId, from: startDate, to: endDate),
        _mentorService.getMentorActiveBookings(
          mentorId,
          from: startDate,
          to: endDate,
        ),
      ]);

      final rawAvailability = results[0] as List<MentorAvailability>;
      final activeBookings = results[1] as List<MentorBooking>;

      final now = DateTime.now();
      _availability = rawAvailability.where((slot) {
        // Exclude slots that are already in the past
        if (slot.startTime.isBefore(now)) return false;

        // Exclude slots that overlap with any active booking
        final hasOverlap = activeBookings.any((booking) {
          return slot.startTime.isBefore(booking.endTime) &&
              slot.endTime.isAfter(booking.startTime);
        });

        return !hasOverlap;
      }).toList();
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
      setError(ErrorHandler.getErrorMessage(e));
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
    _contextSkillName = null;
    _contextJourneyId = null;
    _contextRoadmapSessionId = null;
    _contextNodeId = null;
    _roadmapContextMode = false;
    _eligibilityByMentorId = {};
    _showVerifiedOnly = true;
    _isLoadingMentors = false;
    _isLoadingDetail = false;
    _isLoadingAvailability = false;
    _isEnrichingVerifiedSkills = false;
    _isLoadingEligibility = false;
    resetState();
    notifyListeners();
  }

  void clearSelectedMentor() {
    _selectedMentor = null;
    _availability = [];
    _isFavorite = false;
    notifyListeners();
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() => reset();
}
