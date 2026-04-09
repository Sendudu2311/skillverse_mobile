import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../themes/app_theme.dart';
import '../glass_card.dart';
import 'section_navigation_widget.dart';

/// GlassCard wrapper for a single report section with markdown rendering.
class ReportSectionCardWidget extends StatelessWidget {
  final String sectionKey;
  final String content;
  final bool isDark;

  const ReportSectionCardWidget({
    super.key,
    required this.sectionKey,
    required this.content,
    required this.isDark,
  });

  IconData get _icon {
    return switch (sectionKey) {
      'currentSkills' => Icons.build_circle_outlined,
      'learningGoals' => Icons.flag_outlined,
      'progressSummary' => Icons.trending_up,
      'strengths' => Icons.star_outlined,
      'areasToImprove' => Icons.lightbulb_outline,
      'recommendations' => Icons.tips_and_updates_outlined,
      'skillGaps' => Icons.warning_amber_outlined,
      'nextSteps' => Icons.arrow_forward_outlined,
      'motivation' => Icons.favorite_outline,
      _ => Icons.article_outlined,
    };
  }

  String get _title {
    return kReportSectionTitles[sectionKey] ?? sectionKey;
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(_icon, size: 18, color: AppTheme.primaryBlueDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title.toUpperCase(),
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
            const SizedBox(height: 12),
            ...segments.map((seg) {
              if (seg.isTable) {
                return _buildScrollableTable(seg.content);
              }
              return _buildMarkdownText(seg.content);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownText(String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    final cleaned = _cleanPipesInText(content);
    if (cleaned.trim().isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: cleaned,
      extensionSet: md.ExtensionSet.gitHubWeb,
      shrinkWrap: true,
      styleSheet: _buildMarkdownStyle(),
    );
  }

  Widget _buildScrollableTable(String tableMarkdown) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: MarkdownBody(
        data: tableMarkdown,
        extensionSet: md.ExtensionSet.gitHubWeb,
        shrinkWrap: true,
        styleSheet: _buildMarkdownStyle().copyWith(
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
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle() {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      h2: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
      ),
      h3: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlueDark,
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

  String _sanitizeContent(String content) {
    var result = content
        .replaceAll('<br>', '  \n')
        .replaceAll('<br/>', '  \n')
        .replaceAll('<br />', '  \n')
        .replaceAll('\\n', '\n');

    result = result.replaceAllMapped(
      RegExp(r'^-(\S)', multiLine: true),
      (m) => '- ${m.group(1)}',
    );

    result = result.replaceAllMapped(
      RegExp(r'^\s*\|\s*$', multiLine: true),
      (m) => '',
    );

    result = result.replaceAllMapped(
      RegExp(r'([.:!?])([A-Za-zÀ-ỹĐđ])', unicode: true),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    result = result.replaceAllMapped(
      RegExp(r'([a-zà-ỹ])(\d)', unicode: true),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    result = result.replaceAll(RegExp(r'[^\S\n]{2,}'), ' ');

    return result;
  }

  List<_ContentSegment> _splitContentByTables(String content) {
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

  String _cleanPipesInText(String text) {
    return text
        .split('\n')
        .map((line) {
          if (line.trim().isEmpty) return line;
          var cleaned = line
              .replaceAll(RegExp(r'\s*\|\s*\|\s*'), ' \n')
              .replaceAll(RegExp(r'\s*\|\s*'), ' — ')
              .replaceAll(RegExp(r'^\s*—\s*'), '')
              .replaceAll(RegExp(r'\s*—\s*$'), '');
          return cleaned;
        })
        .join('\n');
  }
}

class _ContentSegment {
  final String content;
  final bool isTable;

  const _ContentSegment(this.content, {required this.isTable});
}
