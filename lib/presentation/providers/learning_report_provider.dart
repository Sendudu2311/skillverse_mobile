import 'package:flutter/material.dart';
import '../../data/models/learning_report_model.dart';
import '../../data/services/learning_report_service.dart';
import '../../data/services/streak_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';

class LearningReportProvider with ChangeNotifier, LoadingStateProviderMixin {
  final LearningReportService _service = LearningReportService();
  final StreakService _streakService = StreakService();

  // ==================== State ====================

  StudentLearningReportResponse? _latestReport;
  List<StudentLearningReportResponse> _reportHistory = [];
  CanGenerateResponse? _canGenerate;
  StreakInfo? _streakInfo;
  bool _isGenerating = false;
  bool _isLoadingHistory = false;
  String _generatingStatus = '';

  // ==================== Getters ====================

  StudentLearningReportResponse? get latestReport => _latestReport;
  List<StudentLearningReportResponse> get reportHistory => _reportHistory;
  CanGenerateResponse? get canGenerate => _canGenerate;
  StreakInfo? get streakInfo => _streakInfo;
  bool get isGenerating => _isGenerating;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasReport => _latestReport != null;
  String get generatingStatus => _generatingStatus;

  // ==================== Actions ====================

  /// Load latest report + check can-generate + streak in parallel
  Future<void> loadLatestReport() async {
    await executeAsync(() async {
      final results = await Future.wait([
        _service.getLatestReport(),
        _service.canGenerateReport(),
        _streakService.getStreakInfo(),
      ]);
      _latestReport = results[0] as StudentLearningReportResponse?;
      _canGenerate = results[1] as CanGenerateResponse;
      _streakInfo = results[2] as StreakInfo?;
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải báo cáo: ${e.toString()}');
  }

  /// Check if user can generate a new report
  Future<void> checkCanGenerate() async {
    try {
      _canGenerate = await _service.canGenerateReport();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking can-generate: $e');
    }
  }

  /// Load report history
  Future<void> loadReportHistory({int page = 0, int size = 10}) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _reportHistory = await _service.getReportHistory(page: page, size: size);
    } catch (e) {
      debugPrint('Error loading report history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Generate a new quick report with fire-and-recover pattern.
  Future<void> generateQuickReport() async {
    _isGenerating = true;
    _generatingStatus = 'AI đang phân tích dữ liệu...';
    final beforeGenerate = DateTime.now();
    notifyListeners();

    try {
      _latestReport = await _service.generateQuickReport();
      await Future.wait([
        loadReportHistory(),
        checkCanGenerate(),
        _syncStreak(),
      ]);
    } catch (e) {
      final isTimeout = _isTimeoutError(e);

      if (isTimeout) {
        debugPrint('⏱️ Generate timed out, starting recovery poll...');
        final recovered = await _pollForNewReport(beforeGenerate);
        if (recovered) {
          await Future.wait([
            loadReportHistory(),
            checkCanGenerate(),
            _syncStreak(),
          ]);
          return;
        }
        setError(
          'AI vẫn đang xử lý báo cáo. Nhấn nút "Kiểm tra lại" sau vài phút.',
        );
      } else {
        setError('Lỗi tạo báo cáo: ${e.toString()}');
      }
    } finally {
      _isGenerating = false;
      _generatingStatus = '';
      notifyListeners();
    }
  }

  Future<void> _syncStreak() async {
    try {
      _streakInfo = await _streakService.getStreakInfo();
    } catch (e) {
      debugPrint('Error syncing streak: $e');
    }
  }

  /// Check if the latest report was generated after [since].
  /// Polls up to [maxAttempts] times with [interval] delay.
  Future<bool> _pollForNewReport(
    DateTime since, {
    int maxAttempts = 3,
    Duration interval = const Duration(seconds: 10),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      _generatingStatus = 'Đang kiểm tra kết quả (${i + 1}/$maxAttempts)...';
      notifyListeners();

      await Future.delayed(interval);

      try {
        final latest = await _service.getLatestReport();
        if (latest != null && _isNewerReport(latest, since)) {
          debugPrint('✅ Recovery: found new report generated after timeout');
          _latestReport = latest;
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Recovery poll #${i + 1} failed: $e');
      }
    }
    return false;
  }

  /// Manual re-check for users who see "try again later" message
  Future<void> recheckLatestReport() async {
    _isGenerating = true;
    _generatingStatus = 'Đang kiểm tra...';
    notifyListeners();

    try {
      final latest = await _service.getLatestReport();
      if (latest != null) {
        _latestReport = latest;
        clearError();
        await Future.wait([loadReportHistory(), _syncStreak()]);
      } else {
        setError('Chưa có báo cáo mới. Thử lại sau vài phút.');
      }
    } catch (e) {
      setError('Lỗi kiểm tra: ${e.toString()}');
    } finally {
      _isGenerating = false;
      _generatingStatus = '';
      notifyListeners();
    }
  }

  /// View a specific report by ID
  Future<void> viewReport(int reportId) async {
    await executeAsync(() async {
      _latestReport = await _service.getReportById(reportId);
      notifyListeners();
    }, errorMessageBuilder: (e) => 'Lỗi tải báo cáo: ${e.toString()}');
  }

  /// Reset state
  void reset() {
    _latestReport = null;
    _reportHistory = [];
    _canGenerate = null;
    _streakInfo = null;
    _isGenerating = false;
    _isLoadingHistory = false;
    _generatingStatus = '';
    resetState();
    notifyListeners();
  }

  // ==================== Helpers ====================

  bool _isTimeoutError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('timeout') || msg.contains('timed out');
  }

  bool _isNewerReport(StudentLearningReportResponse report, DateTime since) {
    if (report.generatedAt == null) return false;
    try {
      final reportTime = DateTime.parse(report.generatedAt!);
      // Allow 5 second tolerance for clock drift
      return reportTime.isAfter(since.subtract(const Duration(seconds: 5)));
    } catch (_) {
      return false;
    }
  }
}
