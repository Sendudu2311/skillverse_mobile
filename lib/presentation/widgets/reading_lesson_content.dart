import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/lesson_models.dart';
import '../../core/utils/error_handler.dart';

class ReadingLessonContent extends StatelessWidget {
  final String? content;
  final String? resourceUrl;
  final List<LessonAttachmentDto>? attachments;

  const ReadingLessonContent({
    super.key,
    required this.content,
    this.resourceUrl,
    this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = content != null && content!.isNotEmpty;
    final hasResource = resourceUrl != null && resourceUrl!.isNotEmpty;
    final hasAttachments = attachments != null && attachments!.isNotEmpty;

    if (!hasContent && !hasResource && !hasAttachments) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nội dung bài học chưa có sẵn',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasContent)
          Card(
            elevation: 1,
            child: Padding(
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
                  'p': Style(margin: Margins.only(bottom: 12)),
                  'ul': Style(margin: Margins.only(left: 16, bottom: 12)),
                  'ol': Style(margin: Margins.only(left: 16, bottom: 12)),
                  'li': Style(margin: Margins.only(bottom: 8)),
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
                  'img': Style(margin: Margins.only(bottom: 16)),
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
                    try {
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ErrorHandler.showWarningSnackBar(
                            context,
                            'Không thể mở liên kết',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorHandler.showErrorSnackBar(
                          context,
                          'Lỗi khi mở liên kết: $e',
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ),

        // Legacy single resource URL (fallback if no structured attachments)
        if (hasResource && !hasAttachments)
          Card(
            elevation: 1,
            margin: const EdgeInsets.only(top: 12),
            child: ListTile(
              leading: Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Tài liệu đính kèm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                resourceUrl!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              trailing: Icon(
                Icons.open_in_new,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () async {
                try {
                  final uri = Uri.tryParse(resourceUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ErrorHandler.showWarningSnackBar(
                        context,
                        'Không thể mở tài liệu',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ErrorHandler.showErrorSnackBar(
                      context,
                      'Lỗi khi mở tài liệu: $e',
                    );
                  }
                }
              },
            ),
          ),

        // Structured attachments list from LessonAttachmentDTO
        if (hasAttachments) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tài liệu đính kèm (${attachments!.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...attachments!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final att = entry.value;
                  return Column(
                    children: [
                      _AttachmentTile(attachment: att),
                      if (i < attachments!.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final LessonAttachmentDto attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final isLink =
        attachment.type == AttachmentType.externalLink ||
        attachment.type == AttachmentType.googleDrive ||
        attachment.type == AttachmentType.github ||
        attachment.type == AttachmentType.youtube ||
        attachment.type == AttachmentType.website;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.1),
        radius: 20,
        child: Icon(
          _iconFor(attachment.type),
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        attachment.title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle:
          attachment.description != null && attachment.description!.isNotEmpty
          ? Text(
              attachment.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : attachment.fileSizeFormatted != null
          ? Text(
              attachment.fileSizeFormatted!,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      trailing: Icon(
        isLink ? Icons.open_in_new : Icons.download_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => _openAttachment(context, attachment),
    );
  }

  Future<void> _openAttachment(
    BuildContext context,
    LessonAttachmentDto attachment,
  ) async {
    final url = attachment.downloadUrl;
    if (url == null || url.isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Đường dẫn tài liệu không có sẵn',
      );
      return;
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ErrorHandler.showWarningSnackBar(context, 'Không thể mở tài liệu');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Lỗi khi mở tài liệu: $e');
      }
    }
  }

  IconData _iconFor(AttachmentType? type) {
    return switch (type) {
      AttachmentType.pdf => Icons.picture_as_pdf_outlined,
      AttachmentType.docx => Icons.description_outlined,
      AttachmentType.pptx => Icons.slideshow_outlined,
      AttachmentType.xlsx => Icons.table_chart_outlined,
      AttachmentType.googleDrive => Icons.add_to_drive_outlined,
      AttachmentType.github => Icons.code_outlined,
      AttachmentType.youtube => Icons.play_circle_outline,
      AttachmentType.externalLink ||
      AttachmentType.website ||
      null => Icons.link_outlined,
    };
  }
}
