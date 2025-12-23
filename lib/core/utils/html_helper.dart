import 'package:html/parser.dart' as html_parser;

class HtmlHelper {
  /// Remove HTML tags and decode HTML entities
  static String stripHtml(String htmlString) {
    // Parse HTML
    final document = html_parser.parse(htmlString);

    // Get text content (this automatically decodes entities)
    final String parsedString = document.body?.text ?? '';

    return parsedString.trim();
  }

  /// Decode HTML entities only (keep tags)
  static String decodeHtmlEntities(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.documentElement?.text ?? htmlString;
  }

  /// Clean HTML for display (remove unwanted tags but keep formatting)
  static String cleanHtml(String htmlString) {
    // Remove Microsoft Word specific tags
    htmlString = htmlString.replaceAll(RegExp(r'<o:p>.*?</o:p>'), '');
    htmlString = htmlString.replaceAll(RegExp(r'</?o:p>'), '');

    // Remove class attributes
    htmlString = htmlString.replaceAll(RegExp(r'\s*class="[^"]*"'), '');

    // Parse and get text
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }
}
