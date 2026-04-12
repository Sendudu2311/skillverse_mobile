import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/learning_report_model.dart';

/// Premium Branded PDF generator for Learning Reports.
/// Creates a high-end A4 PDF with a Galaxy/Glassmorphism theme reflecting the Super App aesthetic.
class PdfGeneratorWidget {
  PdfGeneratorWidget._();

  // ----- Brand Colors (Aligned with AppTheme) -----
  static const _galaxyDarkest = PdfColor.fromInt(0xFF050510);
  static const _galaxyDark = PdfColor.fromInt(0xFF0A0A14);
  static const _primaryBlue = PdfColor.fromInt(0xFF4F46E5);
  static const _accentCyan = PdfColor.fromInt(0xFF00D4FF);
  static const _secondaryPurple = PdfColor.fromInt(0xFF8B5CF6);
  static const _successColor = PdfColor.fromInt(0xFF10B981);
  static const _warningColor = PdfColor.fromInt(0xFFF59E0B);
  static const _errorColor = PdfColor.fromInt(0xFFDC2626);
  
  static const _textPrimary = PdfColor.fromInt(0xFF1E293B);
  static const _textSecondary = PdfColor.fromInt(0xFF64748B);
  static const _borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const _cardBgLight = PdfColor.fromInt(0xFFF8FAFC);

  /// Generate full PDF bytes from a report.
  static Future<Uint8List> generateReportPdf({
    required StudentLearningReportResponse report,
    required ({int value, String emoji, String description}) streakDisplay,
    String? trend,
  }) async {
    // Load Vietnamese-compatible font
    final fontData = await rootBundle.load('assets/fonts/Roboto-Variable.ttf');
    final roboto = pw.Font.ttf(fontData);

    // Load Avatar
    Uint8List? avatarImageBytes;
    try {
      final byteData = await rootBundle.load('assets/meowl_bg_clear.png');
      avatarImageBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: roboto, bold: roboto),
    );

    // Page 1 — Premium Cover & Overview
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => _buildCoverPage(report, streakDisplay, avatarImageBytes),
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
          footer: _buildFooter,
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
        footer: _buildFooter,
        build: (ctx) => _buildMetricsContent(report, streakDisplay),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SkillVerse · Super App · Báo Cáo Phân Tích AI',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.Text(
            'Trang ${ctx.pageNumber}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Cover page with deep Galaxy theme and sleek UI elements
  static pw.Widget _buildCoverPage(
    StudentLearningReportResponse report,
    ({int value, String emoji, String description}) streakDisplay,
    Uint8List? avatarBytes,
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
      'improving': (_successColor, 'Đang tiến bộ mạnh mẽ'),
      'stable': (_primaryBlue, 'Phong độ ổn định'),
      'declining': (_errorColor, 'Cần tập trung thêm'),
    };
    final (trendColor, trendLabel) = trendConfig[trendKey] ?? (_primaryBlue, 'Ổn định');

    return pw.Container(
      width: double.infinity,
      height: double.infinity,
      color: PdfColors.white,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // --- Minimalist Header ---
          pw.Container(
          height: 160,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(color: _borderColor, width: 1),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _accentCyan.shade(.1),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'BÁO CÁO $typeLabel',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryBlue.shade(.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'AI LEARNING REPORT',
                    style: pw.TextStyle(
                      color: _galaxyDarkest,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${report.studentName ?? "Học viên"} · #${report.id ?? "N/A"} · ${report.generatedAt != null ? _formatDate(report.generatedAt!) : "N/A"}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              if (avatarBytes != null)
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    boxShadow: [
                      pw.BoxShadow(
                        color: PdfColors.grey200,
                        blurRadius: 8,
                        offset: const PdfPoint(0, 4),
                      ),
                    ],
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(
                      pw.MemoryImage(avatarBytes),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                )
              else
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: _galaxyDark.shade(.05),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'SV',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: _galaxyDarkest,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        pw.SizedBox(height: 32),

        // --- Bento Grid Layout ---
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(horizontal: 40),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side: Overall Progress
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  height: 220,
                  padding: const pw.EdgeInsets.all(24),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(16),
                    border: pw.Border.all(color: _borderColor, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'TIẾN ĐỘ TỔNG THỂ',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Text(
                        '${report.overallProgress ?? 0}%',
                        style: pw.TextStyle(
                          fontSize: 56,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      ),
                      pw.Spacer(),
                      pw.Stack(
                        children: [
                          pw.Container(
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey100,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                          pw.Container(
                            width: (report.overallProgress ?? 0) / 100 * 180,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: _accentCyan,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: trendColor.shade(.1),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          trendLabel,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: trendColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              // Right side: Quick Stats 2x2 Grid
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  height: 220,
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Expanded(child: _eliteStatCard('Giờ Học', '${metrics?.studyHours ?? 0}h', _accentCyan)),
                            pw.SizedBox(width: 16),
                            pw.Expanded(child: _eliteStatCard('Chuỗi', '${streakDisplay.value} ngày', _warningColor)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Expanded(child: _eliteStatCard('Nhiệm vụ', '${metrics?.tasksCompleted ?? 0}', _successColor)),
                            pw.SizedBox(width: 16),
                            pw.Expanded(child: _eliteStatCard('Khóa học', '${metrics?.totalEnrolledCourses ?? 0}', _secondaryPurple)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 32),

        // --- Recommended Focus (AI Highlight) ---
        if (report.recommendedFocus != null && report.recommendedFocus!.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 40),
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(16),
              border: pw.Border.all(color: _primaryBlue.shade(.3), width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: _primaryBlue,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'AI KHUYẾN NGHỊ TRỌNG TÂM',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryBlue,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  report.recommendedFocus!,
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: _textPrimary,
                    lineSpacing: 5,
                  ),
                ),
              ],
            ),
          ),

        pw.Spacer(),
      ],
    ),
    );
  }

  /// Elite style smaller stat card
  static pw.Widget _eliteStatCard(String label, String value, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardBgLight,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 32,
            height: 4,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  /// Build all section content pages.
  static List<pw.Widget> _buildSectionsContent(
    Map<String, String> sections,
    StudentLearningReportResponse report,
  ) {
    final widgets = <pw.Widget>[];

    // Premium Section Title
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primaryBlue, width: 2)),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'PHÂN TÍCH CHUYÊN SÂU',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _galaxyDarkest,
                letterSpacing: 1.5,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'SKILLVERSE AI',
              style: pw.TextStyle(
                fontSize: 10,
                color: _accentCyan,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 24));

    for (final entry in sections.entries) {
      widgets.addAll(_buildSectionBlock(entry.key, entry.value));
      widgets.add(pw.SizedBox(height: 24));
    }

    return widgets;
  }

  /// Premium Section Block (Sleek cards with deep side borders)
  static List<pw.Widget> _buildSectionBlock(String title, String content) {
    final cleaned = _sanitizePdfContent(content);
    final segments = _splitContentByTables(cleaned);
    final result = <pw.Widget>[];

    // Section header
    result.add(
      pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _primaryBlue,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
    result.add(pw.SizedBox(height: 12));

    // Each content segment as separate widget, wrapped in a subtle left-bordered container
    for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isLast = i == segments.length - 1;
        result.add(
          pw.Container(
            padding: pw.EdgeInsets.only(left: 16, bottom: isLast ? 0 : 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: _borderColor, width: 3)),
            ),
            child: seg.isTable ? _buildPdfTable(seg.content) : _buildPdfText(seg.content),
          ),
        );
    }

    return result;
  }

  /// Build plain text content (simplified markdown-like parsing).
  static pw.Widget _buildPdfText(String content) {
    final lines = content.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      // Check for bold headers
      if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Text(
              trimmed.substring(3),
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _galaxyDarkest,
              ),
            ),
          ),
        );
        continue;
      }
      if (trimmed.startsWith('### ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
            child: pw.Text(
              trimmed.substring(4),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _secondaryPurple,
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
            padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                   margin: const pw.EdgeInsets.only(top: 5, right: 8),
                   width: 5,
                   height: 5,
                   decoration: pw.BoxDecoration(
                     shape: pw.BoxShape.circle,
                     color: _primaryBlue,
                   )
                ),
                pw.Expanded(
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      lineSpacing: 4,
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
            padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                   margin: const pw.EdgeInsets.only(right: 8),
                   child: pw.Text(
                     '${numberedMatch.group(1)}.',
                     style: pw.TextStyle(
                       fontSize: 12,
                       fontWeight: pw.FontWeight.bold,
                       color: _primaryBlue,
                     ),
                   )
                ),
                pw.Expanded(
                  child: pw.Text(
                    numberedMatch.group(2)!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: _textPrimary,
                      lineSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            trimmed,
            style: pw.TextStyle(
              fontSize: 12,
              color: _textPrimary,
              lineSpacing: 4,
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

  /// Premium Markdown table in PDF
  static pw.Widget _buildPdfTable(String tableMarkdown) {
    final lines = tableMarkdown.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return pw.SizedBox.shrink();

    final rows = <pw.TableRow>[];
    bool isHeader = true;

    for (final line in lines) {
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
              ? pw.BoxDecoration(color: _primaryBlue.shade(.05))
              : null,
          children: cells.map((cell) {
            final style = isHeader
                ? pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryBlue,
                  )
                : pw.TextStyle(
                    fontSize: 11,
                    color: _textPrimary,
                  );
            return pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(cell, style: style),
            );
          }).toList(),
        ),
      );
      isHeader = false;
    }

    if (rows.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 8,
        verticalRadius: 8,
        child: pw.Table(
          border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(color: _borderColor, width: 0.5)),
          columnWidths: {
            for (int i = 0; i < rows.first.children.length; i++)
              i: const pw.FlexColumnWidth(1),
          },
          children: rows,
        ),
      ),
    );
  }

  /// Premium Metrics content pages
  static List<pw.Widget> _buildMetricsContent(
    StudentLearningReportResponse report,
    ({int value, String emoji, String description}) streakDisplay,
  ) {
    final metrics = report.metrics;
    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _primaryBlue, width: 2)),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'CHỈ SỐ HỌC TẬP',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _galaxyDarkest,
                letterSpacing: 1.5,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'SKILLVERSE MAPPING',
              style: pw.TextStyle(
                fontSize: 10,
                color: _accentCyan,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 24));

    // Top skills
    if (metrics?.topSkills != null && metrics!.topSkills!.isNotEmpty) {
      widgets.add(_metricsSectionTitle('BẢN ĐỒ KỸ NĂNG CỐT LÕI'));
      widgets.add(pw.SizedBox(height: 16));
      for (final skill in metrics.topSkills!.take(10)) {
        final pct = skill.progressPercent ?? 0;
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  skill.skillName ?? 'N/A',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  skill.level ?? "N/A",
                  style: pw.TextStyle(fontSize: 10, color: _textSecondary),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            height: 6,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                          pw.Container(
                            width: pct / 100 * 300, 
                            height: 6,
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                  colors: [_accentCyan, _primaryBlue]
                              ),
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      '$pct%',
                      style: pw.TextStyle(
                          fontSize: 11, 
                          fontWeight: pw.FontWeight.bold, 
                          color: _primaryBlue
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(pw.SizedBox(height: 32));
    }

    // Roadmap details
    if (metrics?.roadmapDetails != null && metrics!.roadmapDetails!.isNotEmpty) {
      widgets.add(_metricsSectionTitle('TIẾN ĐỘ THEO LỘ TRÌNH'));
      widgets.add(pw.SizedBox(height: 16));
      
      final roadmapWidgets = <pw.Widget>[];
      for (final r in metrics.roadmapDetails!.take(5)) {
        final pct = r.progressPercent ?? 0;
        final quests = '${r.completedQuests ?? 0}/${r.totalQuests ?? 0}';
        roadmapWidgets.add(
          pw.Wrap(
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: _borderColor, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            r.title ?? 'Lộ trình',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: _secondaryPurple.shade(.1),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            '$pct%',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: _secondaryPurple,
                            ),
                          ),
                        )
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Stack(
                      children: [
                        pw.Container(
                          height: 6,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                        pw.Container(
                          width: pct / 100 * 250,
                          height: 6,
                          decoration: pw.BoxDecoration(
                            gradient: pw.LinearGradient(
                              colors: [_secondaryPurple, _primaryBlue],
                            ),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                       children: [
                          pw.Text(
                            'Quests: $quests',
                            style: pw.TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                          pw.Text(
                            'Thời lượng: ${r.totalEstimatedHours?.toStringAsFixed(1) ?? "?"}h',
                            style: pw.TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                       ]
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }
      
      for (int i=0; i < roadmapWidgets.length; i++) {
          widgets.add(roadmapWidgets[i]);
          widgets.add(pw.SizedBox(height: 16));
      }
    }

    return widgets;
  }

  // ==================== Helpers ====================

  static pw.Widget _metricsSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 6,
          height: 18,
          decoration: pw.BoxDecoration(
             color: _primaryBlue,
             borderRadius: pw.BorderRadius.circular(3),
          )
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
            letterSpacing: 1,
          ),
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

  /// Strip emoji and other unsupported Unicode symbols from PDF text.
  static String _stripEmojis(String text) {
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
        .replaceAll('**', '')    // Clean up bold
        .replaceAll('---', '')   // Clean horizontal lines causing trailing lists
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
