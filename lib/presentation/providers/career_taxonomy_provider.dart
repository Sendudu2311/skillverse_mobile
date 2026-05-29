import 'package:flutter/foundation.dart';
import '../../data/models/career_taxonomy_models.dart';
import '../../data/services/career_taxonomy_service.dart';

/// State management for the Career Taxonomy drill-down selection.
/// Follows the prototype SkillForm.tsx cascade pattern:
///   Domain → JobPosition → Track → auto-loaded Skills.
class CareerTaxonomyProvider with ChangeNotifier {
  final CareerTaxonomyService _service = CareerTaxonomyService();

  // ── Data lists ───────────────────────────────────────────────────────────
  List<DomainDto> _domains = [];
  List<JobPositionDto> _jobPositions = [];
  List<JobPositionTrackDto> _tracks = [];
  List<JobPositionTrackSkillDto> _trackSkills = [];

  // ── Selection state ──────────────────────────────────────────────────────
  int? _selectedDomainId;
  int? _selectedJobPositionId;
  int? _selectedTrackId;

  // ── Loading / Error ──────────────────────────────────────────────────────
  bool _loadingDomains = false;
  bool _loadingJobs = false;
  bool _loadingTracks = false;
  bool _loadingSkills = false;
  String? _error;

  // ── Public getters ───────────────────────────────────────────────────────
  List<DomainDto> get domains => _domains;
  List<JobPositionDto> get jobPositions => _jobPositions;
  List<JobPositionTrackDto> get tracks => _tracks;
  List<JobPositionTrackSkillDto> get trackSkills => _trackSkills;

  int? get selectedDomainId => _selectedDomainId;
  int? get selectedJobPositionId => _selectedJobPositionId;
  int? get selectedTrackId => _selectedTrackId;

  DomainDto? get selectedDomain =>
      _selectedDomainId == null
          ? null
          : _domains.cast<DomainDto?>().firstWhere(
                (d) => d?.id == _selectedDomainId,
                orElse: () => null,
              );

  JobPositionDto? get selectedJobPosition =>
      _selectedJobPositionId == null
          ? null
          : _jobPositions.cast<JobPositionDto?>().firstWhere(
                (j) => j?.id == _selectedJobPositionId,
                orElse: () => null,
              );

  JobPositionTrackDto? get selectedTrack =>
      _selectedTrackId == null
          ? null
          : _tracks.cast<JobPositionTrackDto?>().firstWhere(
                (t) => t?.id == _selectedTrackId,
                orElse: () => null,
              );

  List<String> get selectedSkillNames =>
      _trackSkills.map((s) => s.displayName).where((n) => n.isNotEmpty).toList();

  bool get isLoading =>
      _loadingDomains || _loadingJobs || _loadingTracks || _loadingSkills;
  bool get loadingDomains => _loadingDomains;
  bool get loadingJobs => _loadingJobs;
  bool get loadingTracks => _loadingTracks;
  bool get loadingSkills => _loadingSkills;
  String? get error => _error;

  /// Whether enough data is selected to proceed to step 2.
  bool get canProceed =>
      selectedDomain != null &&
      selectedJobPosition != null &&
      selectedTrack != null &&
      selectedSkillNames.isNotEmpty;

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Load active domains (first step).
  Future<void> loadDomains() async {
    _loadingDomains = true;
    _error = null;
    notifyListeners();
    try {
      _domains = await _service.getActiveDomains();
    } catch (e) {
      _error = 'Không thể tải danh sách lĩnh vực. Vui lòng thử lại.';
      debugPrint('CareerTaxonomyProvider.loadDomains error: $e');
    } finally {
      _loadingDomains = false;
      notifyListeners();
    }
  }

  /// Select a domain → cascade-reset downstream selections and load job positions.
  Future<void> selectDomain(int domainId) async {
    _selectedDomainId = domainId;
    _selectedJobPositionId = null;
    _selectedTrackId = null;
    _jobPositions = [];
    _tracks = [];
    _trackSkills = [];
    _loadingJobs = true;
    _error = null;
    notifyListeners();

    try {
      _jobPositions = await _service.getActiveJobPositions(domainId);
    } catch (e) {
      _error = 'Không thể tải danh sách vị trí công việc.';
      debugPrint('CareerTaxonomyProvider.selectDomain error: $e');
    } finally {
      _loadingJobs = false;
      notifyListeners();
    }
  }

  /// Select a job position → cascade-reset downstream and load tracks.
  Future<void> selectJobPosition(int jobPositionId) async {
    _selectedJobPositionId = jobPositionId;
    _selectedTrackId = null;
    _tracks = [];
    _trackSkills = [];
    _loadingTracks = true;
    _error = null;
    notifyListeners();

    try {
      _tracks = await _service.getActiveTracks(jobPositionId);
    } catch (e) {
      _error = 'Không thể tải lộ trình mục tiêu.';
      debugPrint('CareerTaxonomyProvider.selectJobPosition error: $e');
    } finally {
      _loadingTracks = false;
      notifyListeners();
    }
  }

  /// Select a track → load its skills automatically.
  Future<void> selectTrack(int trackId) async {
    _selectedTrackId = trackId;
    _trackSkills = [];
    _loadingSkills = true;
    _error = null;
    notifyListeners();

    try {
      _trackSkills = await _service.getTrackSkills(trackId);
    } catch (e) {
      _error = 'Không thể tải kỹ năng của lộ trình mục tiêu.';
      debugPrint('CareerTaxonomyProvider.selectTrack error: $e');
    } finally {
      _loadingSkills = false;
      notifyListeners();
    }
  }

  /// Reset all selections (e.g. when navigating back to step 1).
  void reset() {
    _selectedDomainId = null;
    _selectedJobPositionId = null;
    _selectedTrackId = null;
    _domains = [];
    _jobPositions = [];
    _tracks = [];
    _trackSkills = [];
    _error = null;
    notifyListeners();
  }
}
