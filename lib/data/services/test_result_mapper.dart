import 'dart:convert';

/// Replicates Web's `mapTestResult()` logic.
/// Backend returns raw JSON strings; this mapper enriches the response map
/// with computed structured fields before [TestResultDto.fromJson] is called.
class TestResultMapper {
  static const int _defaultPassingScore = 60;

  /// Enrich raw backend JSON with computed fields (skillAnalysis,
  /// questionReviews, labels, passed, etc.) so that TestResultDto.fromJson
  /// can populate all UI-facing lists.
  static Map<String, dynamic> enrich(Map<String, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);

    final score = _toInt(json['scorePercentage']);
    final evaluatedLevel = json['evaluatedLevel']?.toString() ?? 'BEGINNER';

    // --- Parse legacy JSON strings ---
    final strengths = _parseSkillInsights(json['strengthsJson']);
    final skillGaps = _parseSkillInsights(json['skillGapsJson']);
    final questionReviews = _buildQuestionReviews(
      json['correctAnswersJson'],
      json['userAnswersJson'],
    );

    // --- Build skillAnalysis map (merge strengths + gaps) ---
    final analysisBySkill = <String, Map<String, dynamic>>{};

    for (final item in strengths) {
      final skill = item['skill'] as String;
      analysisBySkill[skill] = {
        'skillName': skill,
        'currentLevel': evaluatedLevel,
        'gap': 0.0,
        'strengths': [item['description'] ?? skill],
        'weaknesses': <String>[],
        'recommendations': <String>[],
      };
    }

    for (final item in skillGaps) {
      final skill = item['skill'] as String;
      final existing = analysisBySkill[skill];
      if (existing != null) {
        existing['gap'] = -1.0;
        (existing['weaknesses'] as List).add(item['description'] ?? skill);
        if (item['howToImprove'] != null) {
          (existing['recommendations'] as List).add(item['howToImprove']);
        }
      } else {
        analysisBySkill[skill] = {
          'skillName': skill,
          'currentLevel': evaluatedLevel,
          'gap': -1.0,
          'strengths': <String>[],
          'weaknesses': [item['description'] ?? skill],
          'recommendations': item['howToImprove'] != null
              ? [item['howToImprove']]
              : <String>[],
        };
      }
    }

    // --- Labels ---
    final scoreBand = json['scoreBand']?.toString() ?? '';
    final recMode = json['recommendationMode']?.toString() ?? '';

    // --- Overall strengths/weaknesses (formatted) ---
    final overallStrengths = strengths.map((s) {
      final desc = s['description']?.toString() ?? '';
      return desc.isNotEmpty ? '${s['skill']}: $desc' : s['skill'] as String;
    }).toList();

    final overallWeaknesses = skillGaps.map((g) {
      final desc = g['description']?.toString() ?? '';
      return desc.isNotEmpty ? '${g['skill']}: $desc' : g['skill'] as String;
    }).toList();

    // --- Improvement tips ---
    final improvementTips = skillGaps
        .where((g) =>
            g['howToImprove'] != null &&
            (g['howToImprove'] as String).trim().isNotEmpty)
        .map((g) => g['howToImprove'] as String)
        .toList();

    // --- Highlight keywords ---
    final parsedKeywords = _parseStringArray(json['highlightKeywordsJson']);
    final highlightKeywords = parsedKeywords.isNotEmpty
        ? parsedKeywords
        : <String>{
            ...strengths.map((s) => s['skill'] as String),
            ...skillGaps.map((g) => g['skill'] as String),
            evaluatedLevel,
          }.where((s) => s.trim().isNotEmpty).toList();

    // --- Infer totalQuestions if missing ---
    var totalQ = _toInt(json['totalQuestions']);
    if (totalQ == 0 && questionReviews.isNotEmpty) {
      totalQ = questionReviews.length;
      json['totalQuestions'] = totalQ;
    }

    // --- Inject computed fields ---
    json['skillAnalysis'] = analysisBySkill.values.toList();
    json['questionReviews'] = questionReviews;
    json['overallStrengths'] = overallStrengths;
    json['overallWeaknesses'] = overallWeaknesses;
    json['skillGaps'] = skillGaps.map((g) => g['skill'] as String).toList();
    json['highlightKeywords'] = highlightKeywords;
    json['improvementTips'] = improvementTips.isNotEmpty
        ? improvementTips
        : ['Tiếp tục luyện tập theo các kỹ năng còn thiếu.'];
    json['passed'] = score >= _defaultPassingScore;
    json['passingScore'] = _defaultPassingScore;
    json['scoreBandLabel'] = _getScoreBandLabel(scoreBand, score);
    json['recommendationLabel'] = _getRecommendationLabel(recMode, score);

    return json;
  }

  // ====================================================================
  // Private helpers
  // ====================================================================

  static T _safeParseJson<T>(dynamic value, T fallback) {
    if (value == null) return fallback;
    if (value is T) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is T) return decoded;
      } catch (_) {}
    }
    return fallback;
  }

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Parse `[{skill, description, howToImprove?, level?}]` from JSON string.
  static List<Map<String, String>> _parseSkillInsights(dynamic jsonValue) {
    final parsed = _safeParseJson<List<dynamic>>(jsonValue, []);
    final result = <Map<String, String>>[];

    for (final item in parsed) {
      if (item is String) {
        result.add({'skill': item, 'description': ''});
        continue;
      }
      if (item is! Map) continue;
      final raw = Map<String, dynamic>.from(item);
      final skill = raw['skill']?.toString();
      if (skill == null || skill.isEmpty) continue;
      result.add({
        'skill': skill,
        'description': raw['description']?.toString() ?? '',
        if (raw['howToImprove'] != null)
          'howToImprove': raw['howToImprove'].toString(),
        if (raw['level'] != null) 'level': raw['level'].toString(),
      });
    }
    return result;
  }

  static List<String> _parseStringArray(dynamic jsonValue) {
    final parsed = _safeParseJson<List<dynamic>>(jsonValue, []);
    return parsed
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // --- Answer matching helpers (ported from Web) ---

  static String _extractOptionKey(String value) {
    final match = RegExp(r'^([A-D])(?:\s*[.):\-]|\s+|$)', caseSensitive: false)
        .firstMatch(value.trim());
    return match?.group(1)?.toUpperCase() ?? '';
  }

  static String _normalizeAnswerText(String value) {
    return value
        .replaceFirst(RegExp(r'^[A-D](?:\s*[.):\-]|\s+)', caseSensitive: false), '')
        .trim()
        .toLowerCase();
  }

  static String _resolveAnswerText(
      String answer, String optionKey, List<String> options) {
    if (optionKey.isNotEmpty) {
      final index = optionKey.codeUnitAt(0) - 65; // A=0, B=1, ...
      if (index >= 0 && index < options.length) {
        return options[index];
      }
    }
    return answer;
  }

  /// Build question reviews from `correctAnswersJson` + `userAnswersJson`.
  static List<Map<String, dynamic>> _buildQuestionReviews(
    dynamic correctAnswersRaw,
    dynamic userAnswersRaw,
  ) {
    final questions = _safeParseJson<List<dynamic>>(correctAnswersRaw, []);
    final answersMap =
        _safeParseJson<Map<String, dynamic>>(userAnswersRaw, {});
    if (questions.isEmpty) return [];

    final result = <Map<String, dynamic>>[];

    for (var i = 0; i < questions.length; i++) {
      final item = questions[i];
      if (item is! Map) continue;
      final q = Map<String, dynamic>.from(item);

      final questionId = _toInt(q['questionId'], i + 1);
      final questionText = q['question']?.toString() ?? 'Câu hỏi ${i + 1}';
      final skillArea = q['skillArea']?.toString() ?? 'GENERAL';
      final difficulty = q['difficulty']?.toString() ?? 'MEDIUM';
      final explanation = q['explanation']?.toString();
      final options = (q['options'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];

      final correctRaw = q['correctAnswer']?.toString() ?? '';
      final userRaw = (answersMap['$questionId'] ??
              answersMap['${i + 1}'] ??
              '')
          .toString();

      final correctKey = _extractOptionKey(correctRaw);
      final userKey = _extractOptionKey(userRaw);
      final correctText = _normalizeAnswerText(
          _resolveAnswerText(correctRaw, correctKey, options));
      final userText = _normalizeAnswerText(
          _resolveAnswerText(userRaw, userKey, options));

      final isCorrect = (correctKey.isNotEmpty && userKey.isNotEmpty)
          ? correctKey == userKey
          : (correctText.isNotEmpty &&
              userText.isNotEmpty &&
              correctText == userText);

      result.add({
        'questionId': questionId,
        'question': questionText,
        'skillArea': skillArea,
        'difficulty': difficulty,
        'options': options,
        'userAnswer': userRaw.isNotEmpty ? userRaw : 'Chưa trả lời',
        'correctAnswer': correctRaw.isNotEmpty ? correctRaw : 'N/A',
        'isCorrect': isCorrect,
        if (explanation != null && explanation.trim().isNotEmpty)
          'explanation': explanation,
      });
    }
    return result;
  }

  static String _getScoreBandLabel(String scoreBand, int score) {
    switch (scoreBand.toUpperCase()) {
      case 'ZERO_BASE':
        return 'Nền tảng 0';
      case 'FOUNDATION':
        return 'Nền tảng';
      case 'CORE':
        return 'Cốt lõi';
      case 'ADVANCED':
        return 'Nâng cao';
      case 'EXPERT':
        return 'Chuyên sâu';
      default:
        if (score <= 20) return 'Nền tảng 0';
        if (score <= 45) return 'Nền tảng';
        if (score <= 70) return 'Cốt lõi';
        if (score <= 85) return 'Nâng cao';
        return 'Chuyên sâu';
    }
  }

  static String _getRecommendationLabel(String mode, int score) {
    switch (mode.toUpperCase()) {
      case 'FROM_ZERO':
        return 'Lộ trình từ zero';
      case 'FOUNDATION':
        return 'Lộ trình nền tảng';
      case 'STANDARD':
        return 'Lộ trình tiêu chuẩn';
      case 'ADVANCED':
        return 'Lộ trình nâng cao';
      case 'FAST_TRACK':
        return 'Lộ trình tăng tốc';
      default:
        if (score <= 0) return 'Lộ trình từ zero';
        if (score <= 45) return 'Lộ trình nền tảng';
        if (score <= 70) return 'Lộ trình tiêu chuẩn';
        if (score <= 90) return 'Lộ trình nâng cao';
        return 'Lộ trình tăng tốc';
    }
  }
}
