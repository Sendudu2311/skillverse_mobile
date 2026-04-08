import 'package:flutter/material.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../data/models/cv_structured_data.dart';
import '../../widgets/skillverse_app_bar.dart';

/// Trang xem trước CV — tái tạo layout Professional Template từ Web.
/// Bố cục: Sidebar trái (dark) + Nội dung chính phải (white).
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
          : _buildCVContent(context, data),
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

  Widget _buildCVContent(BuildContext context, CVStructuredData data) {
    // On mobile we stack sidebar on top, then main content below
    return SingleChildScrollView(
      child: Column(
        children: [
          // === HEADER / SIDEBAR (dark background) ===
          _buildSidebarSection(context, data),
          // === MAIN CONTENT (white) ===
          _buildMainContent(context, data),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SIDEBAR SECTION (Dark header on mobile)
  // Mirrors: cv-pro-sidebar from ProfessionalTemplate.tsx
  // ═══════════════════════════════════════════════════════
  Widget _buildSidebarSection(BuildContext context, CVStructuredData data) {
    final pi = data.personalInfo;
    const sidebarColor = Color(0xFF1e3a8a); // Professional primary
    const sidebarText = Colors.white;
    const sidebarMuted = Color(0xFFbfdbfe);

    return Container(
      width: double.infinity,
      color: sidebarColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white24,
            backgroundImage: pi.avatarUrl != null
                ? NetworkImage(pi.avatarUrl!)
                : null,
            child: pi.avatarUrl == null
                ? Text(
                    pi.fullName.isNotEmpty ? pi.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            pi.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: sidebarText,
            ),
            textAlign: TextAlign.center,
          ),
          if (pi.professionalTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              pi.professionalTitle!,
              style: const TextStyle(fontSize: 14, color: sidebarMuted),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // Contact Info
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (pi.email != null)
                _contactChip(Icons.mail_outline, pi.email!, sidebarMuted),
              if (pi.phone != null)
                _contactChip(Icons.phone_outlined, pi.phone!, sidebarMuted),
              if (pi.location != null)
                _contactChip(
                  Icons.location_on_outlined,
                  pi.location!,
                  sidebarMuted,
                ),
              if (pi.linkedinUrl != null)
                _contactChip(Icons.link, 'LinkedIn', sidebarMuted),
              if (pi.githubUrl != null)
                _contactChip(Icons.code, 'GitHub', sidebarMuted),
            ],
          ),

          // Skills with progress bars (in sidebar on Web)
          if (data.skills.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sidebarHeading('Chuyên Môn', sidebarMuted),
            const SizedBox(height: 8),
            ...data.skills.map((cat) => _buildSkillGroup(cat, sidebarMuted)),
          ],

          // Languages with dots
          if (data.languages.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sidebarHeading('Ngôn Ngữ', sidebarMuted),
            const SizedBox(height: 8),
            ...data.languages.map((lang) => _buildLanguageItem(lang)),
          ],

          // Education
          if (data.education.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sidebarHeading('Học Vấn', sidebarMuted),
            const SizedBox(height: 8),
            ...data.education.map(
              (edu) => _buildEducationItem(edu, sidebarText, sidebarMuted),
            ),
          ],

          // Certificates
          if (data.certificates.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sidebarHeading('Chứng Chỉ', sidebarMuted),
            const SizedBox(height: 8),
            ...data.certificates.map(
              (cert) => _buildCertItem(cert, sidebarText, sidebarMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _sidebarHeading(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSkillGroup(CVSkillCategory cat, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cat.category != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                cat.category!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                ),
              ),
            ),
          ...cat.skills.map(
            (skill) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (skill.level.clamp(0, 5) / 5.0),
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF93c5fd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(CVLanguage lang) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lang.name,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < lang.dots
                      ? const Color(0xFF93c5fd)
                      : Colors.white24,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(
    CVEducation edu,
    Color textColor,
    Color mutedColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.degree,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            edu.institution,
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          if (edu.startDate != null)
            Text(
              '${edu.startDate} — ${edu.endDate ?? "Hiện tại"}${edu.gpa != null ? " | GPA: ${edu.gpa}" : ""}',
              style: TextStyle(
                fontSize: 11,
                color: mutedColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCertItem(CVCertificate cert, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cert.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (cert.issuingOrganization != null)
            Text(
              '${cert.issuingOrganization}${cert.issueDate != null ? " — ${cert.issueDate}" : ""}',
              style: TextStyle(fontSize: 11, color: mutedColor),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MAIN CONTENT (white background)
  // Mirrors: cv-pro-main from ProfessionalTemplate.tsx
  // ═══════════════════════════════════════════════════════
  Widget _buildMainContent(BuildContext context, CVStructuredData data) {
    const headingColor = Color(0xFF1e3a8a);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          if (data.summary.isNotEmpty) ...[
            _mainHeading('Giới Thiệu', headingColor),
            const SizedBox(height: 8),
            Text(
              data.summary,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Experience
          if (data.experience.isNotEmpty) ...[
            _mainHeading('Kinh Nghiệm', headingColor),
            const SizedBox(height: 12),
            ...data.experience.map(_buildExperienceItem),
            const SizedBox(height: 16),
          ],

          // Projects
          if (data.projects.isNotEmpty) ...[
            _mainHeading('Dự Án', headingColor),
            const SizedBox(height: 12),
            ...data.projects.map(_buildProjectItem),
            const SizedBox(height: 16),
          ],

          // Endorsements
          if (data.endorsements.isNotEmpty) ...[
            _mainHeading('Lời Giới Thiệu', headingColor),
            const SizedBox(height: 12),
            ...data.endorsements.map(_buildEndorsementItem),
          ],
        ],
      ),
    );
  }

  Widget _mainHeading(String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 2, width: 40, color: color.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildExperienceItem(CVExperience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    Text(
                      '${exp.company}${exp.location != null ? " — ${exp.location}" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${exp.startDate ?? ""} — ${exp.isCurrent ? "Hiện tại" : exp.endDate ?? ""}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
              ),
            ],
          ),
          if (exp.description != null) ...[
            const SizedBox(height: 6),
            Text(
              exp.description!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4b5563),
                height: 1.5,
              ),
            ),
          ],
          if (exp.achievements.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...exp.achievements.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFF3b82f6)),
                    ),
                    Expanded(
                      child: Text(
                        a,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4b5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (exp.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: exp.technologies.map((t) => _techTag(t)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectItem(CVProject proj) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  proj.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ),
              if (proj.role != null)
                Text(
                  proj.role!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9ca3af),
                  ),
                ),
            ],
          ),
          if (proj.description != null) ...[
            const SizedBox(height: 6),
            Text(
              proj.description!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4b5563),
                height: 1.5,
              ),
            ),
          ],
          if (proj.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: proj.technologies.map((t) => _techTag(t)).toList(),
            ),
          ],
          if (proj.outcomes.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...proj.outcomes.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFF3b82f6)),
                    ),
                    Expanded(
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4b5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndorsementItem(CVEndorsement end) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: const Color(0xFF3b82f6), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${end.quote}"',
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${end.authorName}${end.authorTitle != null ? ", ${end.authorTitle}" : ""}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _techTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFeff6ff),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFbfdbfe)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF1e40af)),
      ),
    );
  }
}
