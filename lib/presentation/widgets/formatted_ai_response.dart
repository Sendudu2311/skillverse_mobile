import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../themes/app_theme.dart';

/// Widget to render AI response with special formatting
/// Supports: <thinking>, ** **, <suggestions>
class FormattedAIResponse extends StatelessWidget {
  final String content;
  final bool isDark;
  final Function(String)? onSuggestionTap;

  const FormattedAIResponse({
    super.key,
    required this.content,
    required this.isDark,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _parseContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parsed.map((section) {
        switch (section.type) {
          case SectionType.thinking:
            return _buildThinkingSection(section.content);
          case SectionType.suggestions:
            return _buildSuggestionsSection(section.content);
          case SectionType.normal:
            return _buildNormalSection(section.content);
        }
      }).toList(),
    );
  }

  List<ContentSection> _parseContent(String text) {
    final sections = <ContentSection>[];
    final lines = text.split('\n');

    String currentContent = '';
    SectionType currentType = SectionType.normal;
    bool inThinking = false;
    bool inSuggestions = false;

    for (var line in lines) {
      // Check for thinking tags
      if (line.contains('<thinking>')) {
        if (currentContent.isNotEmpty) {
          sections.add(ContentSection(currentType, currentContent.trim()));
          currentContent = '';
        }
        inThinking = true;
        currentType = SectionType.thinking;
        continue;
      }

      if (line.contains('</thinking>')) {
        if (currentContent.isNotEmpty) {
          sections.add(ContentSection(currentType, currentContent.trim()));
          currentContent = '';
        }
        inThinking = false;
        currentType = SectionType.normal;
        continue;
      }

      // Check for suggestions tags
      if (line.contains('<suggestions>')) {
        if (currentContent.isNotEmpty) {
          sections.add(ContentSection(currentType, currentContent.trim()));
          currentContent = '';
        }
        inSuggestions = true;
        currentType = SectionType.suggestions;
        continue;
      }

      if (line.contains('</suggestions>')) {
        if (currentContent.isNotEmpty) {
          sections.add(ContentSection(currentType, currentContent.trim()));
          currentContent = '';
        }
        inSuggestions = false;
        currentType = SectionType.normal;
        continue;
      }

      // Add line to current content
      currentContent += line + '\n';
    }

    // Add remaining content
    if (currentContent.isNotEmpty) {
      sections.add(ContentSection(currentType, currentContent.trim()));
    }

    return sections;
  }

  Widget _buildThinkingSection(String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.psychology, size: 16, color: AppTheme.primaryBlueDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THINKING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppTheme.primaryBlueDark,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection(String content) {
    final suggestions = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentCyan.withValues(alpha: 0.1),
            AppTheme.primaryBlueDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'GỢI Ý TIẾP THEO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppTheme.accentCyan,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...suggestions.asMap().entries.map((entry) {
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: onSuggestionTap != null
                    ? () => onSuggestionTap!(suggestion)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.accentCyan.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNormalSection(String content) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 13,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          height: 1.5,
        ),
        strong: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        em: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        code: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          color: AppTheme.primaryBlueDark,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        listBullet: TextStyle(fontSize: 13, color: AppTheme.primaryBlueDark),
        h1: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
      ),
    );
  }
}

enum SectionType { thinking, suggestions, normal }

class ContentSection {
  final SectionType type;
  final String content;

  ContentSection(this.type, this.content);
}
