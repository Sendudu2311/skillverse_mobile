import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/learning_report_model.dart';

/// Branded PDF generator for Learning Reports.
/// Creates professional A4 PDF with gradient cover, all sections, and metrics.
class PdfGeneratorWidget {
  PdfGeneratorWidget._();

  // Brand colors
  static const _primaryColor = PdfColor.fromInt(0xFF4F46E5);
  static const _secondaryColor = PdfColor.fromInt(0xFF8B5CF6);
  static const _accentColor = PdfColor.fromInt(0xFF06B6D4);
  static const _successColor = PdfColor.fromInt(0xFF22C55E);
  static const _warningColor = PdfColor.fromInt(0xFFFBBF24);
  static const _errorColor = PdfColor.fromInt(0xFFEF4444);
  static const _textPrimary = PdfColor.fromInt(0xFF1F2937);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const _borderColor = PdfColor.fromInt(0xFFE5E7EB);

  /// Generate full PDF bytes from a report.
  static Future<Uint8List> generateReportPdf({
    required StudentLearningReportResponse report,
    required ({int value, String emoji, String description}) streakDisplay,
    String? trend,
  }) async {
    // Load Vietnamese-compatible font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Variable.ttf');
    final roboto = pw.Font.ttf(fontData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: roboto, bold: roboto),
    );

    // Page 1 — Cover & Overview
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => _buildCoverPage(report, streakDisplay),
      ),
    );

    // Pages 2+ — Sections
    final sections = report.sections?.displaySections ?? {};
    if (sections.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (ctx) => pw.SizedBox.shrink(),
          footer: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SkillVerse · skillverse.vn · Confidential',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Trang ${ctx.pageNumber}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ],
            ),
          ),
          build: (ctx) => _buildSectionsContent(sections, report),
        ),
      );
    }

    // Last pages — Metrics detail
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.SizedBox.shrink(),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SkillVerse · skillverse.vn · Confidential',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
              pw.Text(
                'Trang ${ctx.pageNumber}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (ctx) => _buildMetricsContent(report, streakDisplay),
      ),
    );

    return doc.save();
  }

  /// Cover page with gradient header and report overview.
  static pw.Widget _buildCoverPage(
    StudentLearningReportResponse report,
    ({int value, String emoji, String description}) streakDisplay,
  ) {
    final metrics = report.metrics;
    final typeKey = (report.reportType ?? 'COMPREHENSIVE').toUpperCase();
    final typeLabels = {
      'COMPREHENSIVE': 'TOÀN DIỆN',
      'WEEKLY_SUMMARY': 'TUẦN',
      'MONTHLY_SUMMARY': 'THÁNG',
      'SKILL_ASSESSMENT': 'KỸ NĂNG',
      'GOAL_TRACKING': 'MỤC TIÊU',
    };
    final typeLabel = typeLabels[typeKey] ?? typeKey;

    final trendKey = (report.learningTrend ?? 'stable').toLowerCase();
    final trendConfig = {
      'improving': (_successColor, 'Đang tiến bộ'),
      'stable': (_warningColor, 'Ổn định'),
      'declining': (_errorColor, 'Cần tập trung'),
    };
    final (trendColor, trendLabel) =
        trendConfig[trendKey] ?? (_warningColor, 'Ổn định');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Gradient header
        pw.Container(
          height: 200,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [_primaryColor, _secondaryColor, const PdfColor.fromInt(0xFF7C3AED)],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Brand row
              pw.Row(
                children: [
                  pw.Container(
                    width: 56,
                    height: 56,
                    decoration: const pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'M',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SKILLVERSE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        'AI Learning Report',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              // Report type badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0x334F46E5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  typeLabel,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Report meta card — Student name prominent
        pw.Container(
          margin: const pw.EdgeInsets.all(24),
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _borderColor, width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Học sinh',
                      style: pw.TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                    pw.Text(
                      report.studentName ?? 'Học sinh SkillVerse',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _metaRow('Mã báo cáo', '#${report.id ?? 'N/A'}'),
              if (report.generatedAt != null)
                _metaRow('Ngày tạo', _formatDate(report.generatedAt!)),
            ],
          ),
        ),

        // Overall progress
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Tiến độ tổng thể',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  pw.Text(
                    '${report.overallProgress ?? 0}%',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Stack(
                children: [
                  pw.Container(
                    height: 12,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                  ),
                  pw.Container(
                    width: (report.overallProgress ?? 0) / 100 *
                        (PdfPageFormat.a4.width - 80),
                    height: 12,
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [_primaryColor, _accentColor],
                      ),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: trendColor,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    trendLabel,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: trendColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 24),

        // Quick stats grid (2x2)
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24),
          child: pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfStatCard(
                    'Giờ học',
                    '${metrics?.studyHours ?? 0}h',
                  ),
                  _pdfStatCard(
                    'Streak',
                    '${streakDisplay.value} ngày',
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _pdfStatCard(
                    'Tasks hoàn thành',
                    '${metrics?.tasksCompleted ?? 0}',
                  ),
                  _pdfStatCard(
                    'Khóa học đã ghi danh',
                    '${metrics?.totalEnrolledCourses ?? 0}',
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 24),

        // Recommended focus
        if (report.recommendedFocus != null &&
            report.recommendedFocus!.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 24),
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0x14FBBF24),
              border: pw.Border(
                left: pw.BorderSide(color: _warningColor, width: 4),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ĐỀ XUẤT TẬP TRUNG',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _warningColor,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  report.recommendedFocus!,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: _textPrimary,
                    lineSpacing: 4,
                  ),
                ),
              ],
            ),
          ),

        pw.Spacer(),

        // Footer
        pw.Container(
          margin: const pw.EdgeInsets.all(24),
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SkillVerse · skillverse.vn · Báo cáo #${report.id ?? 'N/A'} · Confidential',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
              pw.Text(
                'Trang 1',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build all section content pages.
  static List<pw.Widget> _buildSectionsContent(
    Map<String, String> sections,
    StudentLearningReportResponse report,
  ) {
    final widgets = <pw.Widget>[];

    // Section title page
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'NỘI DUNG CHI TIẾT',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 16));

    final sectionIcons = {
      'Kỹ năng hiện có': '[KN]',
      'Mục tiêu học tập': '[MT]',
      'Tổng kết tiến độ': '[TD]',
      'Điểm mạnh': '[DM]',
      'Cần cải thiện': '[CT]',
      'Khuyến nghị': '[KN]',
      'Khoảng trống kỹ năng': '[KT]',
      'Bước tiếp theo': '[>>]',
      'Động lực': '[DL]',
    };

    for (final entry in sections.entries) {
      widgets.addAll(_buildSectionBlock(
        entry.key,
        entry.value,
        sectionIcons[entry.key] ?? '[*]',
      ));
      widgets.add(pw.SizedBox(height: 16));
    }

    return widgets;
  }

  /// Build a single section as multiple widgets so MultiPage can split them across pages.
  static List<pw.Widget> _buildSectionBlock(String title, String content, String icon) {
    final cleaned = _sanitizePdfContent(content);
    final segments = _splitContentByTables(cleaned);
    final result = <pw.Widget>[];

    // Section header (stays together)
    result.add(
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.only(
            topLeft: pw.Radius.circular(8),
            topRight: pw.Radius.circular(8),
          ),
          border: pw.Border.all(color: _borderColor, width: 0.5),
        ),
        child: pw.Row(
          children: [
            pw.Text(icon, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(width: 8),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    // Each content segment as separate widget
    for (final seg in segments) {
      result.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          color: PdfColors.grey50,
          child: seg.isTable ? _buildPdfTable(seg.content) : _buildPdfText(seg.content),
        ),
      );
    }

    // Bottom spacer with border
    result.add(
      pw.Container(
        height: 14,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.only(
            bottomLeft: pw.Radius.circular(8),
            bottomRight: pw.Radius.circular(8),
          ),
        ),
      ),
    );

    return result;
  }

  /// Build plain text content (simplified markdown-like parsing).
  static pw.Widget _buildPdfText(String content) {
    final lines = content.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Check for bold headers (lines starting with ## or ###)
      if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
            child: pw.Text(
              trimmed.substring(3),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ),
        );
        continue;
      }
      if (trimmed.startsWith('### ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(
              trimmed.substring(4),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _accentColor,
              ),
            ),
          ),
        );
        continue;
      }

      // Check for list items
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                pw.Expanded(
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      lineSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list
      final numberedMatch = RegExp(r'^(\d+)\.\s*(.*)').firstMatch(trimmed);
      if (numberedMatch != null) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${numberedMatch.group(1)}. ',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    numberedMatch.group(2)!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      lineSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph — wrap long lines
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
            trimmed,
            style: pw.TextStyle(
              fontSize: 12,
              color: _textPrimary,
              lineSpacing: 3,
            ),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// Build a markdown table in PDF.
  static pw.Widget _buildPdfTable(String tableMarkdown) {
    final lines = tableMarkdown.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return pw.SizedBox.shrink();

    final rows = <pw.TableRow>[];
    bool isHeader = true;

    for (final line in lines) {
      // Skip separator lines
      if (RegExp(r'^\|[\s:\-|]+\|$').hasMatch(line.trim())) continue;

      final cells = line
          .split('|')
          .where((c) => c.trim().isNotEmpty)
          .map((c) => c.trim())
          .toList();

      if (cells.isEmpty) continue;

      rows.add(
        pw.TableRow(
          decoration: isHeader
              ? pw.BoxDecoration(color: const PdfColor.fromInt(0x1A4F46E5))
              : null,
          children: cells.map((cell) {
            final style = isHeader
                ? pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  )
                : pw.TextStyle(
                    fontSize: 11,
                    color: _textPrimary,
                  );
            return pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(cell, style: style),
            );
          }).toList(),
        ),
      );
      isHeader = false;
    }

    if (rows.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6, bottom: 6),
      child: pw.Table(
        border: pw.TableBorder.all(color: _borderColor, width: 0.5),
        columnWidths: {
          for (int i = 0; i < rows.first.children.length; i++)
            i: const pw.FlexColumnWidth(1),
        },
        children: rows,
      ),
    );
  }

  /// Build metrics content as a list for MultiPage.
  static List<pw.Widget> _buildMetricsContent(
    StudentLearningReportResponse report,
    ({int value, String emoji, String description}) streakDisplay,
  ) {
    final metrics = report.metrics;
    final widgets = <pw.Widget>[];

    // Header
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'PHÂN TÍCH CHI TIẾT',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 20));

    // Top skills
    if (metrics?.topSkills != null && metrics!.topSkills!.isNotEmpty) {
      widgets.add(_metricsSectionTitle('Top Kỹ năng', '#'));
      widgets.add(pw.SizedBox(height: 10));
      for (final skill in metrics.topSkills!.take(10)) {
        final pct = skill.progressPercent ?? 0;
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      skill.skillName ?? 'N/A',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    pw.Text(
                      '${skill.level ?? 'N/A'} · $pct%',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Stack(
                  children: [
                    pw.Container(
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                    pw.Container(
                      width: pct / 100 * 200,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: _accentColor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 20));
    }

    // Roadmap details
    if (metrics?.roadmapDetails != null && metrics!.roadmapDetails!.isNotEmpty) {
      widgets.add(_metricsSectionTitle('Lộ trình học tập', '#'));
      widgets.add(pw.SizedBox(height: 10));
      for (final r in metrics.roadmapDetails!.take(5)) {
        final pct = r.progressPercent ?? 0;
        final quests = '${r.completedQuests ?? 0}/${r.totalQuests ?? 0}';
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _borderColor, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        r.title ?? 'Lộ trình',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    pw.Text(
                      '$quests Quests · ${r.totalEstimatedHours?.toStringAsFixed(1) ?? '?'}h',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Stack(
                  children: [
                    pw.Container(
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                    pw.Container(
                      width: pct / 100 * 200,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                        ),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$pct%',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 20));
    }

    // Study sessions summary
    widgets.add(_metricsSectionTitle('Phiên học tập', '#'));
    widgets.add(pw.SizedBox(height: 10));
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _borderColor, width: 0.5),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _miniMetric('Tổng phiên', '${metrics?.totalStudySessions ?? 0}'),
            _miniMetric(
              'TB/phiên',
              _formatDuration(metrics?.averageSessionDuration ?? 0),
            ),
            _miniMetric(
              'Streak hiện tại',
              '${streakDisplay.value} ngày',
            ),
            _miniMetric(
              'Streak dài nhất',
              '${metrics?.longestStreak ?? 0} ngày',
            ),
          ],
        ),
      ),
    );

    return widgets;
  }

  // ==================== Helpers ====================

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: _textSecondary),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfStatCard(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metricsSectionTitle(String title, String icon) {
    return pw.Row(
      children: [
        pw.Text(icon, style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(width: 6),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  static pw.Widget _miniMetric(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, color: _textSecondary),
        ),
      ],
    );
  }

  static String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  /// Strip emoji and other unsupported Unicode symbols from PDF text.
  static String _stripEmojis(String text) {
    // Remove emoji and miscellaneous symbols not in Roboto
    return text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{FE00}-\u{FE0F}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{200D}]|[\u{20E3}]|[\u{E0020}-\u{E007F}]',
        unicode: true,
      ),
      '',
    ).trim();
  }

  static String _sanitizePdfContent(String content) {
    var result = content
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll('\\n', '\n')
        .replaceAllMapped(
          RegExp(r'^-(\S)', multiLine: true),
          (m) => '- ${m.group(1)}',
        )
        .replaceAllMapped(
          RegExp(r'([.:!?])([A-Za-zÀ-ỹĐđ])', unicode: true),
          (m) => '${m.group(1)} ${m.group(2)}',
        );
    // Strip emoji from AI-generated content
    result = _stripEmojis(result);
    return result;
  }

  static List<_ContentSegment> _splitContentByTables(String content) {
    final lines = content.split('\n');
    final segments = <_ContentSegment>[];
    final buffer = StringBuffer();
    bool inTable = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final pipeCount = '|'.allMatches(trimmed).length;
      final isProperTableRow =
          trimmed.startsWith('|') && trimmed.endsWith('|') && pipeCount >= 2;
      final isSeparator = RegExp(r'^\|[\s:\-|]+\|$').hasMatch(trimmed);
      final isContinuation = inTable && trimmed.startsWith('|');
      final isTableLine = isProperTableRow || isSeparator || isContinuation;

      if (isTableLine && !inTable) {
        final text = buffer.toString();
        if (text.trim().isNotEmpty) {
          segments.add(_ContentSegment(text, isTable: false));
        }
        buffer.clear();
        inTable = true;
      } else if (!isTableLine && inTable) {
        final table = buffer.toString();
        if (table.trim().isNotEmpty) {
          segments.add(_ContentSegment(table, isTable: true));
        }
        buffer.clear();
        inTable = false;
      }

      buffer.writeln(line);
    }

    final remaining = buffer.toString();
    if (remaining.trim().isNotEmpty) {
      segments.add(_ContentSegment(remaining, isTable: inTable));
    }

    return segments;
  }
}

class _ContentSegment {
  final String content;
  final bool isTable;
  const _ContentSegment(this.content, {required this.isTable});
}
