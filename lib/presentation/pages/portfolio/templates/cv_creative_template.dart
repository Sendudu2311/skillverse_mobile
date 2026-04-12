import 'package:flutter/material.dart';
import '../../../../data/models/cv_structured_data.dart';

/// Creative CV Template — Bold colors, timeline layout, infographic style.
/// Mirrors Web Prototype's `CreativeTemplate.tsx`.
class CVCreativeTemplate extends StatelessWidget {
  final CVStructuredData data;
  const CVCreativeTemplate({super.key, required this.data});

  // ── Colors ──
  static const _heroGradStart = Color(0xFFDB2777); // pink-600
  static const _heroGradMid = Color(0xFF7C3AED); // violet-600
  static const _heroGradEnd = Color(0xFF2563EB); // blue-600
  static const _accent = Color(0xFFEC4899); // pink-500
  static const _accentAlt = Color(0xFF7C3AED);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _bg = Color(0xFFFAFAFA);
  static const _tagBg = Color(0x1AEC4899); // pink-500/10
  static const _tagText = Color(0xFFBE185D);

  @override
  Widget build(BuildContext context) {
    final pi = data.personalInfo;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ═══ HERO HEADER ═══
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_heroGradStart, _heroGradMid, _heroGradEnd],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    backgroundImage: pi.avatarUrl != null
                        ? NetworkImage(pi.avatarUrl!)
                        : null,
                    child: pi.avatarUrl == null
                        ? Text(
                            pi.fullName.isNotEmpty
                                ? pi.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pi.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (pi.professionalTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            pi.professionalTitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (pi.email != null) _pill(Icons.mail_outline, pi.email!),
                          if (pi.phone != null) _pill(Icons.phone_outlined, pi.phone!),
                          if (pi.location != null)
                            _pill(Icons.location_on_outlined, pi.location!),
                          if (pi.linkedinUrl != null) _pill(Icons.link, 'LinkedIn'),
                          if (pi.githubUrl != null) _pill(Icons.code, 'GitHub'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ═══ BODY ═══
          Container(
            color: _bg,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary ──
                if (data.summary.isNotEmpty) ...[
                  _sectionTitle('Giới Thiệu'),
                  const SizedBox(height: 6),
                  Text(data.summary,
                      style: const TextStyle(
                          fontSize: 13, color: _textDark, height: 1.6)),
                  const SizedBox(height: 20),
                ],

                // ── Skills as colorful tags ──
                if (data.skills.isNotEmpty) ...[
                  _sectionTitle('Kỹ Năng'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: data.skills
                        .expand((cat) => cat.skills)
                        .map((skill) => _skillTag(skill.name))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Experience as Timeline ──
                if (data.experience.isNotEmpty) ...[
                  _sectionTitle('Kinh Nghiệm'),
                  const SizedBox(height: 10),
                  ...data.experience.asMap().entries.map(
                      (e) => _buildTimelineCard(e.value, e.key, showDot: true)),
                  const SizedBox(height: 16),
                ],

                // ── Education as Timeline ──
                if (data.education.isNotEmpty) ...[
                  _sectionTitle('Học Vấn'),
                  const SizedBox(height: 10),
                  ...data.education.asMap().entries.map(
                      (e) => _buildEduTimeline(e.value)),
                  const SizedBox(height: 16),
                ],

                // ── Projects as grid cards ──
                if (data.projects.isNotEmpty) ...[
                  _sectionTitle('Dự Án'),
                  const SizedBox(height: 10),
                  ...data.projects.map(_buildProjectCard),
                  const SizedBox(height: 16),
                ],

                // ── Certificates ──
                if (data.certificates.isNotEmpty) ...[
                  _sectionTitle('Chứng Chỉ'),
                  const SizedBox(height: 10),
                  ...data.certificates.map(_buildCertItem),
                  const SizedBox(height: 16),
                ],

                // ── Languages ──
                if (data.languages.isNotEmpty) ...[
                  _sectionTitle('Ngôn Ngữ'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: data.languages
                        .map((l) => _langTag('${l.name} — ${l.proficiency}'))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Endorsements ──
                if (data.endorsements.isNotEmpty) ...[
                  _sectionTitle('Lời Giới Thiệu'),
                  const SizedBox(height: 10),
                  ...data.endorsements.map(_buildEndorsement),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── helpers ───

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _accent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _textDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _skillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_heroGradStart, _heroGradMid],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _langTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTimelineCard(CVExperience exp, int index,
      {bool showDot = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline bar
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent,
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: _accent.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                  Text(exp.company,
                      style: const TextStyle(fontSize: 12, color: _accentAlt)),
                  Text(
                    '${exp.startDate ?? ""} — ${exp.isCurrent ? "Hiện tại" : exp.endDate ?? ""}',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                  ),
                  if (exp.description != null) ...[
                    const SizedBox(height: 6),
                    Text(exp.description!,
                        style: const TextStyle(
                            fontSize: 12, color: _textDark, height: 1.5)),
                  ],
                  if (exp.achievements.isNotEmpty)
                    ...exp.achievements.map((a) => Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text('▸ $a',
                              style: const TextStyle(
                                  fontSize: 12, color: _textDark)),
                        )),
                  if (exp.technologies.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: exp.technologies
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _tagBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                        fontSize: 10, color: _tagText)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEduTimeline(CVEducation edu) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentAlt,
                  ),
                ),
                Expanded(
                  child: Container(
                      width: 2, color: _accentAlt.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(edu.degree,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                  Text(edu.institution,
                      style: const TextStyle(fontSize: 12, color: _accentAlt)),
                  Text(
                    '${edu.startDate ?? ""} — ${edu.endDate ?? "Hiện tại"}${edu.gpa != null ? " | GPA: ${edu.gpa}" : ""}',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(CVProject proj) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _accent, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(proj.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
          if (proj.description != null) ...[
            const SizedBox(height: 4),
            Text(proj.description!,
                style: const TextStyle(
                    fontSize: 12, color: _textDark, height: 1.5)),
          ],
          if (proj.technologies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: proj.technologies
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _tagBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(t,
                            style:
                                const TextStyle(fontSize: 10, color: _tagText)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertItem(CVCertificate cert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                if (cert.issuingOrganization != null)
                  Text(cert.issuingOrganization!,
                      style: const TextStyle(fontSize: 12, color: _accentAlt)),
                if (cert.issueDate != null)
                  Text(cert.issueDate!,
                      style: const TextStyle(fontSize: 11, color: _textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndorsement(CVEndorsement end) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _accentAlt, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${end.quote}"',
            style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _textDark,
                height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            '— ${end.authorName}${end.authorTitle != null ? ", ${end.authorTitle}" : ""}',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _accentAlt),
          ),
        ],
      ),
    );
  }
}
