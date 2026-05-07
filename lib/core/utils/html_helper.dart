import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class HtmlHelper {
  /// Remove HTML tags and decode HTML entities
  static String stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      final String parsedString = document.body?.text ?? '';
      return parsedString.trim();
    } catch (e) {
      return htmlString;
    }
  }

  /// Decode HTML entities only (keep tags)
  static String decodeHtmlEntities(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      return document.documentElement?.text ?? htmlString;
    } catch (e) {
      return htmlString;
    }
  }

  /// Clean HTML for display (remove all tags and decode entities)
  static String cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);

      String text = document.body?.text ?? '';

      text = text
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
          .trim();

      return text;
    } catch (e) {
      return htmlString;
    }
  }

  /// Sanitize HTML before passing to flutter_html renderer.
  ///
  /// Physically removes tags at the DOM level that flutter_html cannot render
  /// and that produce large blank spaces: iframe, video, audio, script, style,
  /// noscript, object, embed, figure (without text), and empty block elements
  /// with fixed heights from rich-text editors (Quill, TinyMCE, etc.).
  static String sanitizeForDisplay(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      final document = html_parser.parse(htmlString);
      final body = document.body;
      if (body == null) return htmlString;

      // Tags to remove entirely (including their inner content)
      const removeTags = [
        'iframe',
        'video',
        'audio',
        'script',
        'style',
        'noscript',
        'object',
        'embed',
        'form',
        'input',
        'button',
        'select',
        'textarea',
        'canvas',
        'map',
        'svg',
      ];

      for (final tag in removeTags) {
        for (final el in body.querySelectorAll(tag).toList()) {
          el.remove();
        }
      }

      // Remove empty block containers with explicit height
      // (produced by Quill/TinyMCE when inserting empty rows)
      _removeProblematicBlocks(body);

      return body.innerHtml;
    } catch (e) {
      return htmlString;
    }
  }

  /// Removes:
  /// - `<figure>` elements with no visible text (usually broken image wrappers)
  /// - Block elements with an inline `height:` style and no text content
  static void _removeProblematicBlocks(html_dom.Element root) {
    // Remove empty figures (broken image/media wrappers)
    for (final el in root.querySelectorAll('figure').toList()) {
      if (el.text.trim().isEmpty) {
        el.remove();
      }
    }

    // Remove block containers with fixed height and no text
    const blockSelectors = 'div,section,article,aside,p,span';
    for (final el in root.querySelectorAll(blockSelectors).toList()) {
      final style = el.attributes['style'] ?? '';
      final hasExplicitHeight =
          RegExp(r'height\s*:\s*\d').hasMatch(style) ||
          RegExp(r'min-height\s*:\s*[1-9]').hasMatch(style);
      final hasNoText = el.text.trim().isEmpty;

      if (hasExplicitHeight && hasNoText) {
        el.remove();
      }
    }
  }
}
