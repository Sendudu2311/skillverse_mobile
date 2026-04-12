import 'package:flutter/material.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../data/models/cv_structured_data.dart';
import '../../widgets/skillverse_app_bar.dart';
import 'templates/cv_professional_template.dart';
import 'templates/cv_modern_template.dart';
import 'templates/cv_minimal_template.dart';
import 'templates/cv_creative_template.dart';

/// CV Preview page — Routes to the correct template based on `templateName`.
/// Mirrors Web Prototype's `CVTemplateRenderer.tsx`.
class CVPreviewPage extends StatelessWidget {
  final CVDto cv;

  const CVPreviewPage({super.key, required this.cv});

  @override
  Widget build(BuildContext context) {
    final data = CVStructuredData.tryParse(cv.cvJson);

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Xem CV',
        onBack: () => Navigator.pop(context),
      ),
      body: data == null
          ? _buildErrorState(context)
          : _buildTemplateContent(data),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không thể hiển thị CV',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Dữ liệu CV không hợp lệ hoặc chưa được tạo.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateContent(CVStructuredData data) {
    final templateKey =
        (cv.templateName ?? 'professional').toLowerCase().trim();

    switch (templateKey) {
      case 'modern':
      case 'hiện đại':
        return CVModernTemplate(data: data);
      case 'minimal':
      case 'mẫu cơ bản':
      case 'default':
        return CVMinimalTemplate(data: data);
      case 'creative':
      case 'sáng tạo':
        return CVCreativeTemplate(data: data);
      case 'professional':
      case 'chuyên nghiệp':
      default:
        return CVProfessionalTemplate(data: data);
    }
  }
}
