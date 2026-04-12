import 'package:flutter/material.dart';
import '../../../../data/models/cv_structured_data.dart';

/// Professional CV Template — Dark sidebar + clean white main content.
/// Faithfully mirrors Web Prototype's `ProfessionalTemplate.tsx`.
class CVProfessionalTemplate extends StatelessWidget {
  final CVStructuredData data;
  const CVProfessionalTemplate({super.key, required this.data});

  // ── Colors (matching Prototype CSS) ──
  static const _sidebarBg = Color(0xFF1E293B); // slate-800
  static const _sidebarText = Colors.white;
  static const _sidebarMuted = Color(0xFF94A3B8); // slate-400
  static const _sidebarAccent = Color(0xFF93C5FD); // blue-300
  static const _sidebarHeading = Color(0xFFBFDBFE); // blue-200
  static const _mainBg = Colors.white;
  static const _mainHeading = Color(0xFF1E3A8A); // blue-900
  static const _mainText = Color(0xFF374151); // gray-700
  static const _mainMuted = Color(0xFF6B7280); // gray-500
  static const _mainDate = Color(0xFF9CA3AF); // gray-400
  static const _tagBg = Color(0xFFEFF6FF); // blue-50
  static const _tagBorder = Color(0xFFBFDBFE); // blue-200
  static const _tagText = Color(0xFF1E40AF); // blue-800
  static const _barTrack = Color(0x33FFFFFF); // white/20%
  static const _barFill = _sidebarAccent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSidebar(),
          _buildMainContent(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  SIDEBAR (dark)
  // ════════════════════════════════════════════
  Widget _buildSidebar() {
    final pi = data.personalInfo;
    return Container(
      width: double.infinity,
      color: _sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // ── Avatar ──
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _sidebarAccent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _sidebarAccent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: pi.avatarUrl != null
                  ? Image.network(pi.avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(pi))
                  : _avatarFallback(pi),
            ),
          ),
          const SizedBox(height: 16),

          // ── Name ──
          Text(
            pi.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _sidebarText,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (pi.professionalTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              pi.professionalTitle!,
              style: TextStyle(
                fontSize: 13,
                color: _sidebarAccent,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // ── Contact ──
          const SizedBox(height: 20),
          _sidebarSection(
            'LIÊN HỆ',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pi.phone != null) _contactRow(Icons.phone_outlined, pi.phone!),
                if (pi.email != null) _contactRow(Icons.mail_outline, pi.email!),
                if (pi.location != null)
                  _contactRow(Icons.location_on_outlined, pi.location!),
                if (pi.linkedinUrl != null) _contactRow(Icons.link, 'LinkedIn'),
                if (pi.githubUrl != null) _contactRow(Icons.code, 'GitHub'),
                if (pi.portfolioUrl != null)
                  _contactRow(Icons.language, 'Portfolio'),
              ],
            ),
          ),

          // ── Education ──
          if (data.education.isNotEmpty)
            _sidebarSection(
              'HỌC VẤN',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.education.map((edu) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.degree,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _sidebarText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          edu.institution,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _sidebarMuted,
                          ),
                        ),
                        Text(
                          '${edu.startDate ?? ""} — ${edu.endDate ?? "Hiện tại"}'
                          '${edu.gpa != null ? " | GPA: ${edu.gpa}" : ""}',
                          style: TextStyle(
                            fontSize: 11,
                            color: _sidebarMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Skills with progress bars ──
          if (data.skills.isNotEmpty)
            _sidebarSection(
              'CHUYÊN MÔN',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.skills.map((cat) {
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _sidebarAccent,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ...cat.skills.map(
                          (skill) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  skill.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _sidebarMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _skillBar(skill.level),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Languages with dot indicators ──
          if (data.languages.isNotEmpty)
            _sidebarSection(
              'NGÔN NGỮ',
              Column(
                children: data.languages.map((lang) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lang.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _sidebarText,
                            ),
                          ),
                        ),
                        _langDots(lang.dots),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Certificates ──
          if (data.certificates.isNotEmpty)
            _sidebarSection(
              'CHỨNG CHỈ',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.certificates.map((cert) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _sidebarText,
                          ),
                        ),
                        if (cert.issuingOrganization != null)
                          Text(
                            '${cert.issuingOrganization}'
                            '${cert.issueDate != null ? " — ${cert.issueDate}" : ""}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _sidebarMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════
  //  MAIN CONTENT (white)
  // ════════════════════════════════════════════
  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      color: _mainBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary ──
          if (data.summary.isNotEmpty) ...[
            _mainSectionTitle('Giới Thiệu'),
            const SizedBox(height: 8),
            Text(
              data.summary,
              style: const TextStyle(
                fontSize: 13.5,
                color: _mainText,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Experience ──
          if (data.experience.isNotEmpty) ...[
            _mainSectionTitle('Kinh Nghiệm'),
            const SizedBox(height: 12),
            ...data.experience.map(_buildExpItem),
            const SizedBox(height: 16),
          ],

          // ── Projects ──
          if (data.projects.isNotEmpty) ...[
            _mainSectionTitle('Dự Án'),
            const SizedBox(height: 12),
            ...data.projects.map(_buildProjectItem),
            const SizedBox(height: 16),
          ],

          // ── Endorsements ──
          if (data.endorsements.isNotEmpty) ...[
            _mainSectionTitle('Lời Giới Thiệu'),
            const SizedBox(height: 12),
            ...data.endorsements.map(_buildEndorsement),
          ],
        ],
      ),
    );
  }

  // ─── Sidebar helpers ───

  Widget _avatarFallback(CVPersonalInfo pi) {
    return Container(
      width: 96,
      height: 96,
      color: const Color(0xFF334155),
      alignment: Alignment.center,
      child: Text(
        pi.fullName.isNotEmpty ? pi.fullName[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: _sidebarText,
        ),
      ),
    );
  }

  Widget _sidebarSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _sidebarHeading,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 1,
            color: _sidebarMuted.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _sidebarAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: _sidebarMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillBar(int level) {
    final pct = (level.clamp(0, 5) / 5.0);
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: _barTrack,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            color: _barFill,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _langDots(int filled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? _sidebarAccent : _barTrack,
          ),
        );
      }),
    );
  }

  // ─── Main content helpers ───

  Widget _mainSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _mainHeading,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: _mainHeading.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildExpItem(CVExperience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: role + date
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
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${exp.company}${exp.location != null ? " — ${exp.location}" : ""}',
                      style: const TextStyle(fontSize: 13, color: _mainMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${exp.startDate ?? ""} — ${exp.isCurrent ? "Hiện tại" : exp.endDate ?? ""}',
                style: const TextStyle(fontSize: 11, color: _mainDate),
              ),
            ],
          ),
          // Description
          if (exp.description != null) ...[
            const SizedBox(height: 6),
            Text(
              exp.description!,
              style: const TextStyle(
                fontSize: 13,
                color: _mainText,
                height: 1.6,
              ),
            ),
          ],
          // Achievements (bullet list)
          if (exp.achievements.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...exp.achievements.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: _mainHeading,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(a,
                            style: const TextStyle(
                                fontSize: 13, color: _mainText, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
          // Technology tags
          if (exp.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: exp.technologies.map(_techTag).toList(),
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
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (proj.role != null)
                Text(proj.role!,
                    style: const TextStyle(fontSize: 11, color: _mainDate)),
            ],
          ),
          if (proj.description != null) ...[
            const SizedBox(height: 4),
            Text(
              proj.description!,
              style: const TextStyle(
                fontSize: 13,
                color: _mainText,
                height: 1.6,
              ),
            ),
          ],
          if (proj.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: proj.technologies.map(_techTag).toList(),
            ),
          ],
          if (proj.outcomes.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...proj.outcomes.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: TextStyle(
                              color: _mainHeading,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(o,
                            style: const TextStyle(
                                fontSize: 13, color: _mainText, height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEndorsement(CVEndorsement end) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: _mainHeading, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${end.quote}"',
            style: const TextStyle(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: _mainText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${end.authorName}${end.authorTitle != null ? ", ${end.authorTitle}" : ""}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _mainMuted,
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
        color: _tagBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _tagBorder),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: _tagText)),
    );
  }
}
