import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/learning_report_model.dart';
import '../../data/services/learning_report_service.dart';
import '../../data/services/streak_service.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../core/utils/date_time_helper.dart';
import '../widgets/learning_report/pdf_generator_widget.dart';

class LearningReportProvider with ChangeNotifier, LoadingStateProviderMixin {
  final LearningReportService _service = LearningReportService();
  final StreakService _streakService = StreakService();
  Timer? _generatingStepTimer;

  // ==================== State ====================

  StudentLearningReportResponse? _latestReport;
  List<StudentLearningReportResponse> _reportHistory = [];
  CanGenerateResponse? _canGenerate;
  StreakInfo? _streakInfo;
  bool _isGenerating = false;
  bool _isLoadingHistory = false;
  String _generatingStatus = '';

  // --- New state for full parity ---
  ReportType _selectedReportType = ReportType.comprehensive;
  String _meowlSpeech = '';
  int _generatingStep = 0;
  String _activeSection = 'overview';
  bool _isDownloadingPDF = false;
  int _historyPage = 0;
  bool _hasMoreHistory = true;

  // ==================== Getters ====================

  StudentLearningReportResponse? get latestReport => _latestReport;
  List<StudentLearningReportResponse> get reportHistory => _reportHistory;
  CanGenerateResponse? get canGenerate => _canGenerate;
  StreakInfo? get streakInfo => _streakInfo;
  bool get isGenerating => _isGenerating;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasReport => _latestReport != null;
  String get generatingStatus => _generatingStatus;
  bool get isDownloadingPDF => _isDownloadingPDF;
  int get historyPage => _historyPage;
  bool get hasMoreHistory => _hasMoreHistory;

  ReportType get selectedReportType => _selectedReportType;
  String get meowlSpeech => _meowlSpeech;
  int get generatingStep => _generatingStep;
  String get activeSection => _activeSection;

  /// Whether history has more pages to load
  bool get canLoadMoreHistory =>
      _hasMoreHistory && !_isLoadingHistory && _reportHistory.isNotEmpty;

  // ==================== Report Type ====================

  void setReportType(ReportType type) {
    _selectedReportType = type;
    notifyListeners();
  }

  void setActiveSection(String section) {
    _activeSection = section;
    notifyListeners();
  }

  void setGeneratingStep(int step) {
    _generatingStep = step;
    notifyListeners();
  }

  // ==================== Meowl Speech ====================

  static final _random = Random();

  String getMeowlSpeech(String state, String? trend) {
    final speeches = <String, List<String>>{
      'loading': [
        'Meowl đang xem dữ liệu của bạn... 📚',
        'Chờ chút nha, Meowl đang tìm hiểu! 🔍',
      ],
      'generating': [
        'Meowl đang phân tích rất chăm chỉ! 🧠',
        'AI đang làm việc, đợi Meowl tí nha~ ⚡',
        'Báo cáo sắp xong rồi! 🎯',
        'Đang thu thập thông tin học tập... 📊',
        'Meowl đang xử lý dữ liệu lớn! 💪',
      ],
      'error': [
        'Ôi không! Có lỗi gì đó rồi... 😿',
        'Meowl gặp trục trặc, thử lại nha! 🔄',
      ],
      'no-report': [
        'Bạn chưa có báo cáo nào! Tạo ngay nha~ ✨',
        'Meowl sẵn sàng phân tích cho bạn! 📊',
      ],
    };

    final trendSpeeches = <String, List<String>>{
      'improving': [
        'Woww! Bạn đang tiến bộ tuyệt vời! 🚀',
        'Meowl rất tự hào về bạn! 🌟',
        'Cứ giữ phong độ này nha! 💪',
      ],
      'stable': ['Bạn đang học đều đặn đó! 📈', 'Ổn định là tốt, cố lên! 🎯'],
      'declining': [
        'Meowl thấy bạn hơi chùng... 😔',
        'Đừng lo, Meowl sẽ giúp bạn! 💖',
        'Cùng lập kế hoạch mới nha! 📝',
      ],
    };

    if (state == 'report' && trend != null) {
      final list =
          trendSpeeches[trend.toLowerCase()] ?? trendSpeeches['stable']!;
      return list[_random.nextInt(list.length)];
    }

    final list = speeches[state] ?? speeches['no-report']!;
    return list[_random.nextInt(list.length)];
  }

  void _updateMeowlSpeech() {
    if (isLoading) {
      _meowlSpeech = getMeowlSpeech('loading', null);
    } else if (_isGenerating) {
      _meowlSpeech = getMeowlSpeech('generating', null);
    } else if (hasError) {
      _meowlSpeech = getMeowlSpeech('error', null);
    } else if (_latestReport == null) {
      _meowlSpeech = getMeowlSpeech('no-report', null);
    } else {
      _meowlSpeech = getMeowlSpeech('report', _latestReport!.learningTrend);
    }
  }

  // ==================== Generating Step Cycle ====================

  void _startGeneratingStepCycle() {
    _generatingStepTimer?.cancel();
    _generatingStepTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isGenerating) {
        _generatingStep = (_generatingStep + 1) % 4;
        notifyListeners();
      }
    });
  }

  void _stopGeneratingStepCycle() {
    _generatingStepTimer?.cancel();
    _generatingStepTimer = null;
    _generatingStep = 0;
  }

  // ==================== Actions ====================

  /// Load latest report + check can-generate + streak in parallel
  Future<void> loadLatestReport() async {
    _updateMeowlSpeech();
    await executeAsync(() async {
      final results = await Future.wait([
        _service.getLatestReport(),
        _service.canGenerateReport(),
        _streakService.getStreakInfo(),
      ]);
      _latestReport = results[0] as StudentLearningReportResponse?;
      _canGenerate = results[1] as CanGenerateResponse;
      _streakInfo = results[2] as StreakInfo?;
      _activeSection = 'overview';
      _updateMeowlSpeech();
    }, errorMessageBuilder: (e) => 'Lỗi tải báo cáo: ${e.toString()}');
    notifyListeners();
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

  /// Load report history with pagination
  Future<void> loadReportHistory({bool loadMore = false}) async {
    if (_isLoadingHistory) return;

    if (loadMore) {
      if (!_hasMoreHistory) return;
      _historyPage++;
    } else {
      _historyPage = 0;
      _reportHistory = [];
      _hasMoreHistory = true;
    }

    _isLoadingHistory = true;
    notifyListeners();

    try {
      final page = loadMore ? _historyPage : 0;
      final newReports = await _service.getReportHistory(page: page, size: 10);

      if (loadMore) {
        _reportHistory = [..._reportHistory, ...newReports];
      } else {
        _reportHistory = newReports;
      }

      _hasMoreHistory = newReports.length >= 10;
    } catch (e) {
      debugPrint('Error loading report history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Load more history (convenience method)
  Future<void> loadMoreHistory() => loadReportHistory(loadMore: true);

  /// Generate a new report with selected type
  Future<void> generateReport() async {
    if (_isGenerating) return;

    _isGenerating = true;
    _generatingStatus = 'AI đang phân tích dữ liệu...';
    _generatingStep = 0;
    _startGeneratingStepCycle();
    _updateMeowlSpeech();
    notifyListeners();

    final beforeGenerate = DateTime.now();

    try {
      _latestReport = await _service.generateReportFull(
        reportType: _selectedReportType.name.toUpperCase(),
        includeChatHistory: true,
        includeDetailedSkills: true,
      );
      _activeSection = 'overview';
      _updateMeowlSpeech();

      await Future.wait([
        loadReportHistory(),
        checkCanGenerate(),
        _syncStreak(),
      ]);
    } catch (e) {
      final isTimeout = _isTimeoutError(e);

      if (isTimeout) {
        debugPrint('⏱️ Generate timed out, starting recovery poll...');
        _generatingStatus = 'AI vẫn đang xử lý, kiểm tra kết quả...';
        notifyListeners();

        final recovered = await _pollForNewReport(beforeGenerate);
        if (recovered) {
          _activeSection = 'overview';
          _updateMeowlSpeech();
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
      _updateMeowlSpeech();
    } finally {
      _isGenerating = false;
      _generatingStatus = '';
      _stopGeneratingStepCycle();
      notifyListeners();
    }
  }

  /// Generate a quick report (convenience method, uses default type)
  Future<void> generateQuickReport() async {
    if (_isGenerating) return;

    _isGenerating = true;
    _generatingStatus = 'AI đang phân tích dữ liệu...';
    _generatingStep = 0;
    _startGeneratingStepCycle();
    _updateMeowlSpeech();
    notifyListeners();

    final beforeGenerate = DateTime.now();

    try {
      _latestReport = await _service.generateQuickReport();
      _activeSection = 'overview';
      _updateMeowlSpeech();

      await Future.wait([
        loadReportHistory(),
        checkCanGenerate(),
        _syncStreak(),
      ]);
    } catch (e) {
      final isTimeout = _isTimeoutError(e);

      if (isTimeout) {
        debugPrint('⏱️ Generate timed out, starting recovery poll...');
        _generatingStatus = 'AI vẫn đang xử lý, kiểm tra kết quả...';
        notifyListeners();

        final recovered = await _pollForNewReport(beforeGenerate);
        if (recovered) {
          _activeSection = 'overview';
          _updateMeowlSpeech();
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
      _updateMeowlSpeech();
    } finally {
      _isGenerating = false;
      _generatingStatus = '';
      _stopGeneratingStepCycle();
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
          _updateMeowlSpeech();
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
    _updateMeowlSpeech();
    notifyListeners();

    try {
      final latest = await _service.getLatestReport();
      if (latest != null) {
        _latestReport = latest;
        clearError();
        _updateMeowlSpeech();
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
    _isGenerating = true;
    _generatingStatus = 'Đang tải báo cáo...';
    _updateMeowlSpeech();
    notifyListeners();

    try {
      _latestReport = await _service.getReportById(reportId);
      _activeSection = 'overview';
      clearError();
      _updateMeowlSpeech();
    } catch (e) {
      setError('Lỗi tải báo cáo: ${e.toString()}');
    } finally {
      _isGenerating = false;
      _generatingStatus = '';
      notifyListeners();
    }
  }

  /// Generates PDF bytes and filename helper.
  Future<(Uint8List, String)?> _generatePdfBytes() async {
    if (_latestReport == null) return null;
    final streakDisplay = getStreakDisplay();
    final pdfBytes = await PdfGeneratorWidget.generateReportPdf(
      report: _latestReport!,
      streakDisplay: streakDisplay,
    );
    final typeKey = (_latestReport!.reportType ?? 'COMPREHENSIVE')
        .toUpperCase();
    final typeFilename = typeKey.toLowerCase().replaceAll('_', '_');
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final filename = 'skillverse_report_${typeFilename}_$date.pdf';
    return (pdfBytes, filename);
  }

  /// Save PDF to device Downloads folder.
  String? lastSavedPdfPath;

  Future<void> downloadPDF() async {
    _isDownloadingPDF = true;
    notifyListeners();

    try {
      final result = await _generatePdfBytes();
      if (result == null) return;
      final (pdfBytes, filename) = result;

      // Save to public Downloads folder
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getDownloadsDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      lastSavedPdfPath = file.path;
      debugPrint('PDF saved to: ${file.path}');
    } catch (e, stack) {
      debugPrint('PDF save error: $e\n$stack');
      lastSavedPdfPath = null;
    } finally {
      _isDownloadingPDF = false;
      notifyListeners();
    }
  }

  /// Share PDF via system share sheet.
  bool _isShareingPDF = false;
  bool get isSharingPDF => _isShareingPDF;

  Future<void> sharePDF() async {
    _isShareingPDF = true;
    notifyListeners();

    try {
      final result = await _generatePdfBytes();
      if (result == null) return;
      final (pdfBytes, filename) = result;

      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e, stack) {
      debugPrint('PDF share error: $e\n$stack');
    } finally {
      _isShareingPDF = false;
      notifyListeners();
    }
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
    _selectedReportType = ReportType.comprehensive;
    _meowlSpeech = '';
    _generatingStep = 0;
    _activeSection = 'overview';
    _isDownloadingPDF = false;
    _historyPage = 0;
    _hasMoreHistory = true;
    _stopGeneratingStepCycle();
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
      final reportTime = DateTimeHelper.tryParseIso8601(report.generatedAt);
      if (reportTime == null) return false;
      // Allow 5 second tolerance for clock drift
      return reportTime.isAfter(since.subtract(const Duration(seconds: 5)));
    } catch (_) {
      return false;
    }
  }

  /// Get streak display info with emoji intensity
  ({int value, String emoji, String description}) getStreakDisplay() {
    final streak = _streakInfo?.currentStreak ?? 0;
    if (streak == 0) {
      return (value: streak, emoji: '💤', description: 'Bắt đầu streak!');
    } else if (streak >= 30) {
      return (value: streak, emoji: '🔥🔥🔥', description: 'Streak cháy!');
    } else if (streak >= 14) {
      return (value: streak, emoji: '🔥🔥', description: 'Streak mạnh!');
    } else {
      return (value: streak, emoji: '🔥', description: 'Streak tốt!');
    }
  }

  /// Get available sections from current report
  List<String> getAvailableSections() {
    if (_latestReport?.sections == null) return [];
    final sections = <String>[];
    final map = _latestReport!.sections!.displaySections;
    for (final key in map.keys) {
      // Map display keys to internal keys
      if (key == 'Kỹ năng hiện có') sections.add('currentSkills');
      if (key == 'Mục tiêu học tập') sections.add('learningGoals');
      if (key == 'Tổng kết tiến độ') sections.add('progressSummary');
      if (key == 'Điểm mạnh') sections.add('strengths');
      if (key == 'Cần cải thiện') sections.add('areasToImprove');
      if (key == 'Khuyến nghị') sections.add('recommendations');
      if (key == 'Khoảng trống kỹ năng') sections.add('skillGaps');
      if (key == 'Bước tiếp theo') sections.add('nextSteps');
      if (key == 'Động lực') sections.add('motivation');
    }
    return sections;
  }

  @override
  void dispose() {
    _stopGeneratingStepCycle();
    super.dispose();
  }
}
