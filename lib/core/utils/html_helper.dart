import 'package:html/parser.dart' as html_parser;

class HtmlHelper {
  /// Remove HTML tags and decode HTML entities
  static String stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';

    try {
      // Parse HTML
      final document = html_parser.parse(htmlString);

      // Get text content (this automatically decodes entities)
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
      // Parse HTML - this handles all tags including <p>, <i>, <b>, <o:p>, etc.
      final document = html_parser.parse(htmlString);

      // Extract text content - automatically:
      // 1. Removes ALL HTML tags (including <p>, <i>, <b>, <o:p>, etc.)
      // 2. Decodes HTML entities (&ndash; -> –, &ocirc; -> ô, etc.)
      // 3. Preserves text content
      String text = document.body?.text ?? '';

      // Clean up whitespace
      text = text
          .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
          .replaceAll(RegExp(r'\n\s*\n+'), '\n\n') // Multiple newlines to max 2
          .trim();

      return text;
    } catch (e) {
      // Fallback: if parsing fails, return original
      return htmlString;
    }
  }
}
