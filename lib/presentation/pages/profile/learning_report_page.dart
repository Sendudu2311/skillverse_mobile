import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../../providers/learning_report_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../../data/models/learning_report_model.dart';

class LearningReportPage extends StatefulWidget {
  const LearningReportPage({super.key});

  @override
  State<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends State<LearningReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LearningReportProvider>();
      provider.loadLatestReport();
      provider.loadReportHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Báo cáo học tập AI',
        icon: Icons.analytics,
        useGradientTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Báo cáo mới nhất'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: Consumer<LearningReportProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildLatestTab(provider, isDark),
              _buildHistoryTab(provider, isDark),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<LearningReportProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton.extended(
            onPressed: provider.isGenerating
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.generateQuickReport();
                    if (!mounted) return;
                    if (provider.errorMessage == null) {
                      _tabController.animateTo(0);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Đã tạo báo cáo mới!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  },
            icon: provider.isGenerating
                ? CommonLoading.button()
                : const Icon(Icons.auto_awesome),
            label: Text(
              provider.isGenerating
                  ? (provider.generatingStatus.isNotEmpty
                        ? provider.generatingStatus
                        : 'Đang tạo...')
                  : 'Tạo báo cáo',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: AppTheme.primaryBlueDark,
          );
        },
      ),
    );
  }

  // ==================== Latest Report Tab ====================

  Widget _buildLatestTab(LearningReportProvider provider, bool isDark) {
    if (provider.isLoading) {
      return CommonLoading.center(message: 'Đang tải báo cáo...');
    }

    if (provider.errorMessage != null) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () {
          // If error was from timeout recovery, use recheck
          if (provider.errorMessage!.contains('Kiểm tra lại') ||
              provider.errorMessage!.contains('xử lý')) {
            provider.recheckLatestReport();
          } else {
            provider.loadLatestReport();
          }
        },
      );
    }

    final report = provider.latestReport;
    if (report == null) {
      return EmptyStateWidget(
        icon: Icons.analytics_outlined,
        title: 'Chưa có báo cáo nào',
        subtitle:
            'Nhấn nút "Tạo báo cáo" để AI phân tích tiến độ học tập của bạn',
      );
    }

    return _buildReportView(report, isDark);
  }

  Widget _buildReportView(StudentLearningReportResponse report, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Metrics overview ─────────────────────────
          if (report.metrics != null)
            _buildMetricsCard(report.metrics!, isDark),
          const SizedBox(height: 16),

          // ── Report header ───────────────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: AppTheme.accentCyan,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo ${report.reportType ?? "COMPREHENSIVE"}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        if (report.generatedAt != null)
                          Text(
                            'Tạo lúc: ${_formatDateTime(report.generatedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── AI sections (rendered as Markdown) ──────
          if (report.sections != null)
            ...report.sections!.displaySections.entries.map(
              (entry) => _buildSectionCard(entry.key, entry.value, isDark),
            ),

          // ── Raw report content (fallback) ───────────
          if (report.sections == null &&
              report.reportContent != null &&
              report.reportContent!.isNotEmpty)
            _buildMarkdownCard('Báo cáo', report.reportContent!, isDark),
        ],
      ),
    );
  }

  // ==================== Metrics Card ====================

  Widget _buildMetricsCard(StudentMetrics metrics, bool isDark) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TỔNG QUAN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentCyan,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildMetricTile(
                  Icons.local_fire_department,
                  '${metrics.streak}',
                  'Streak',
                  Colors.orange,
                  isDark,
                ),
                _buildMetricTile(
                  Icons.schedule,
                  '${metrics.studyHours}h',
                  'Giờ học',
                  AppTheme.accentCyan,
                  isDark,
                ),
                _buildMetricTile(
                  Icons.task_alt,
                  '${metrics.tasksCompleted}',
                  'Tasks',
                  AppTheme.successColor,
                  isDark,
                ),
                _buildMetricTile(
                  Icons.route,
                  '${metrics.completedRoadmaps ?? 0}/${metrics.totalRoadmaps ?? 0}',
                  'Roadmaps',
                  AppTheme.accentGold,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Section Card ====================

  Widget _buildSectionCard(String title, String content, bool isDark) {
    final iconMap = <String, IconData>{
      'Kỹ năng hiện có': Icons.build_circle_outlined,
      'Mục tiêu học tập': Icons.flag_outlined,
      'Tổng kết tiến độ': Icons.trending_up,
      'Điểm mạnh': Icons.star_outlined,
      'Cần cải thiện': Icons.lightbulb_outline,
      'Khuyến nghị': Icons.tips_and_updates_outlined,
      'Khoảng trống kỹ năng': Icons.warning_amber_outlined,
      'Bước tiếp theo': Icons.arrow_forward_outlined,
      'Động lực': Icons.favorite_outline,
    };

    // Absorb continuation title from content first line.
    // e.g., title="Điểm mạnh", content starts with "CỦA BẠN✨ ..." →
    //        title="Điểm mạnh của bạn", content starts with "Dù tiến..."
    var displayTitle = title;
    var displayContent = content;
    final titleContinuationMap = <String, String>{
      'Điểm mạnh': 'của bạn',
      'Cần cải thiện': '',
      'Động lực': '& khích lệ',
    };

    if (titleContinuationMap.containsKey(title)) {
      var continuation = titleContinuationMap[title]!;
      if (continuation.isNotEmpty) {
        displayTitle = '$title $continuation';
      }
      // Remove the leaked continuation from the content first line
      // Pattern: lines that start with all-caps continuation text
      displayContent = displayContent.replaceFirst(
        RegExp(r'^[A-ZÀ-Ỹ\s&*✨💪🎉🌟]+', unicode: true),
        '',
      );
      // Clean leading whitespace/newlines
      displayContent = displayContent.trimLeft();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildMarkdownCard(
        displayTitle,
        displayContent,
        isDark,
        icon: iconMap[title] ?? Icons.article_outlined,
      ),
    );
  }

  Widget _buildMarkdownCard(
    String title,
    String content,
    bool isDark, {
    IconData icon = Icons.article_outlined,
  }) {
    final sanitized = _sanitizeContent(content);
    final segments = _splitContentByTables(sanitized);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlueDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlueDark,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Render each segment: text normally, tables horizontally scrollable
            ...segments.map((seg) {
              if (seg.isTable) {
                return _buildScrollableTable(seg.content, isDark);
              }
              return _buildMarkdownText(seg.content, isDark);
            }),
          ],
        ),
      ),
    );
  }

  /// Renders normal markdown text (paragraphs, lists, headings)
  Widget _buildMarkdownText(String content, bool isDark) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    // Clean any remaining | pipe chars that leaked from AI table syntax
    final cleaned = _cleanPipesInText(content);
    if (cleaned.trim().isEmpty) return const SizedBox.shrink();
    return MarkdownBody(
      data: cleaned,
      extensionSet: md.ExtensionSet.gitHubWeb,
      shrinkWrap: true,
      styleSheet: _buildMarkdownStyle(isDark),
    );
  }

  /// Renders a markdown table inside horizontal scroll
  Widget _buildScrollableTable(String tableMarkdown, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: MarkdownBody(
          data: tableMarkdown,
          extensionSet: md.ExtensionSet.gitHubWeb,
          shrinkWrap: true,
          styleSheet: _buildMarkdownStyle(isDark).copyWith(
            tableColumnWidth: const IntrinsicColumnWidth(),
            tableCellsPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tableBorder: TableBorder.all(
              color: isDark
                  ? AppTheme.accentCyan.withValues(alpha: 0.25)
                  : AppTheme.primaryBlueDark.withValues(alpha: 0.15),
              width: 0.5,
            ),
            tableHead: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlueDark,
            ),
            tableBody: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Shared markdown style for consistent look
  MarkdownStyleSheet _buildMarkdownStyle(bool isDark) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      h1: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      h2: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlueDark,
        letterSpacing: 0.5,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlueDark,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: isDark
            ? AppTheme.darkTextSecondary
            : AppTheme.lightTextSecondary,
      ),
      listBullet: TextStyle(color: AppTheme.accentCyan),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isDark
                ? AppTheme.accentCyan.withValues(alpha: 0.5)
                : AppTheme.primaryBlueDark.withValues(alpha: 0.3),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    );
  }

  // ==================== History Tab ====================

  Widget _buildHistoryTab(LearningReportProvider provider, bool isDark) {
    if (provider.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.reportHistory.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lịch sử báo cáo',
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.reportHistory.length,
      itemBuilder: (context, index) {
        final report = provider.reportHistory[index];
        return _buildHistoryItem(report, provider, isDark);
      },
    );
  }

  Widget _buildHistoryItem(
    StudentLearningReportResponse report,
    LearningReportProvider provider,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          title: Text(
            report.reportType ?? 'COMPREHENSIVE',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            report.generatedAt != null
                ? _formatDateTime(report.generatedAt!)
                : 'N/A',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (report.id != null) {
              provider.viewReport(report.id!);
              _tabController.animateTo(0);
            }
          },
        ),
      ),
    );
  }

  /// Sanitize AI-generated content for proper markdown rendering.
  ///
  /// Fixes known issues from AI output:
  /// 1. HTML <br> tags → markdown newlines
  /// 2. Bold markers ** → stripped but preserving word spacing
  /// 3. -text (no space) → - text (proper list item)
  /// 4. Emoji directly touching text → add space
  /// 5. Missing spaces after punctuation
  String _sanitizeContent(String content) {
    var result = content
        // HTML line breaks → markdown newlines
        .replaceAll('<br>', '  \n')
        .replaceAll('<br/>', '  \n')
        .replaceAll('<br />', '  \n')
        .replaceAll('\\n', '\n');

    // Step 1 & 2: Legacy bold-stripping removed to support Backend Prompt Fix
    // Keep internal spacing cleanup

    // Step 4: Fix dash-lists without space: "-Text" → "- Text"
    result = result.replaceAllMapped(
      RegExp(r'^-(\S)', multiLine: true),
      (m) => '- ${m.group(1)}',
    );

    // Step 5: Clean stray pipe chars in non-table context
    // Single | at start/end of lines that aren't table rows
    result = result.replaceAllMapped(
      RegExp(r'^\s*\|\s*$', multiLine: true),
      (m) => '',
    );

    // Step 6: Fix missing space after colon/period when followed by letter
    result = result.replaceAllMapped(
      RegExp(r'([.:!?])([A-Za-zÀ-ỹĐđ])', unicode: true),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // Step 7: Fix missing space between word and digit or emoji
    // "với3" → "với 3", "vào1" → "vào 1"
    result = result.replaceAllMapped(
      RegExp(r'([a-zà-ỹ])(\d)', unicode: true),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // Step 8: Collapse multiple spaces into one (preserve newlines)
    result = result.replaceAll(RegExp(r'[^\S\n]{2,}'), ' ');

    return result;
  }

  /// Splits markdown content into text and table segments.
  ///
  /// A table block is detected as consecutive lines starting with `|`.
  /// This allows rendering text normally and tables in horizontal scroll.
  List<_ContentSegment> _splitContentByTables(String content) {
    final lines = content.split('\n');
    final segments = <_ContentSegment>[];
    final buffer = StringBuffer();
    bool inTable = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final pipeCount = '|'.allMatches(trimmed).length;

      // A line is a table line if:
      // 1. Proper table row: starts AND ends with |, has ≥2 pipes
      // 2. Table separator: matches |---|---| pattern
      // 3. Continuation: we're already in a table AND line starts with |
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

  /// Remove raw | pipe characters from text (non-table) segments.
  /// Replaces pipes used as separators with proper formatting.
  String _cleanPipesInText(String text) {
    return text
        .split('\n')
        .map((line) {
          if (line.trim().isEmpty) return line;
          // Replace | separators with dash, clean up
          var cleaned = line
              .replaceAll(RegExp(r'\s*\|\s*\|\s*'), ' \n') // || → newline
              .replaceAll(RegExp(r'\s*\|\s*'), ' — ') // | → dash
              .replaceAll(RegExp(r'^\s*—\s*'), '') // leading dash
              .replaceAll(RegExp(r'\s*—\s*$'), ''); // trailing dash
          return cleaned;
        })
        .join('\n');
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}

/// A segment of markdown content — either plain text or a table block.
class _ContentSegment {
  final String content;
  final bool isTable;

  const _ContentSegment(this.content, {required this.isTable});
}
