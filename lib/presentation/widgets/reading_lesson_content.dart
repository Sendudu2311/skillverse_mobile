import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class ReadingLessonContent extends StatelessWidget {
  final String? content;

  const ReadingLessonContent({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    if (content == null || content!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nội dung bài học chưa có sẵn',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Html(
          data: content!,
          style: {
            'body': Style(
              fontSize: FontSize(16),
              lineHeight: LineHeight.number(1.6),
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
            ),
            'h1': Style(
              fontSize: FontSize(28),
              fontWeight: FontWeight.bold,
              margin: Margins.only(bottom: 16, top: 8),
            ),
            'h2': Style(
              fontSize: FontSize(24),
              fontWeight: FontWeight.bold,
              margin: Margins.only(bottom: 14, top: 8),
            ),
            'h3': Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              margin: Margins.only(bottom: 12, top: 8),
            ),
            'p': Style(
              margin: Margins.only(bottom: 12),
            ),
            'ul': Style(
              margin: Margins.only(left: 16, bottom: 12),
            ),
            'ol': Style(
              margin: Margins.only(left: 16, bottom: 12),
            ),
            'li': Style(
              margin: Margins.only(bottom: 8),
            ),
            'code': Style(
              backgroundColor: Colors.grey[200],
              padding: HtmlPaddings.symmetric(horizontal: 8, vertical: 4),
              fontFamily: 'monospace',
              fontSize: FontSize(14),
            ),
            'pre': Style(
              backgroundColor: Colors.grey[100],
              padding: HtmlPaddings.all(16),
              margin: Margins.only(bottom: 16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            'blockquote': Style(
              backgroundColor: Colors.blue[50],
              border: Border(
                left: BorderSide(color: Colors.blue[700]!, width: 4),
              ),
              padding: HtmlPaddings.all(16),
              margin: Margins.only(bottom: 16, left: 0),
            ),
            'a': Style(
              color: Colors.blue[700],
              textDecoration: TextDecoration.underline,
            ),
            'img': Style(
              margin: Margins.only(bottom: 16),
            ),
            'table': Style(
              border: Border.all(color: Colors.grey[300]!),
              margin: Margins.only(bottom: 16),
            ),
            'th': Style(
              backgroundColor: Colors.grey[200],
              padding: HtmlPaddings.all(8),
              border: Border.all(color: Colors.grey[300]!),
              fontWeight: FontWeight.bold,
            ),
            'td': Style(
              padding: HtmlPaddings.all(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
          },
          onLinkTap: (url, attributes, element) async {
            if (url != null) {
              final uri = Uri.tryParse(url);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                debugPrint('Could not launch URL: $url');
              }
            }
          },
        ),
      ),
    );
  }
}
