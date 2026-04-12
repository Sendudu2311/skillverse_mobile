import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../data/models/cv_structured_data.dart';

/// Modern CV Template — Gradient header, card-based layout, circular skill charts.
/// Mirrors Web Prototype's `ModernTemplate.tsx`.
class CVModernTemplate extends StatelessWidget {
  final CVStructuredData data;
  const CVModernTemplate({super.key, required this.data});

  // ── Colors ──
  static const _primary = Color(0xFF7C3AED); // violet-600
  static const _primaryLight = Color(0xFFA78BFA);
  static const _headerGradStart = Color(0xFF6D28D9);
  static const _headerGradEnd = Color(0xFF4F46E5);
  static const _bg = Color(0xFFF8FAFC);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);
  static const _badgeBg = Color(0xFFEDE9FE);
  static const _badgeText = Color(0xFF6D28D9);

  @override
  Widget build(BuildContext context) {
    final pi = data.personalInfo;
    return SingleChildScrollView(
      child: Column(
        children: [
          // ═══ GRADIENT HEADER ═══
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_headerGradStart, _headerGradEnd],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      pi.avatarUrl != null ? NetworkImage(pi.avatarUrl!) : null,
                  child: pi.avatarUrl == null
                      ? Text(
                          pi.fullName.isNotEmpty
                              ? pi.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
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
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (pi.professionalTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            pi.professionalTitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Contact chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (pi.email != null)
                            _contactChip(Icons.mail_outline, pi.email!),
                          if (pi.phone != null)
                            _contactChip(Icons.phone_outlined, pi.phone!),
                          if (pi.location != null)
                            _contactChip(
                                Icons.location_on_outlined, pi.location!),
                          if (pi.linkedinUrl != null)
                            _contactChip(Icons.link, 'LinkedIn'),
                          if (pi.githubUrl != null)
                            _contactChip(Icons.code, 'GitHub'),
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
                  Text(
                    data.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textDark,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // ── Experience ──
                if (data.experience.isNotEmpty) ...[
                  _sectionTitle('Kinh Nghiệm'),
                  const SizedBox(height: 10),
                  ...data.experience.map(_buildExpCard),
                  const SizedBox(height: 16),
                ],

                // ── Education ──
                if (data.education.isNotEmpty) ...[
                  _sectionTitle('Học Vấn'),
                  const SizedBox(height: 10),
                  ...data.education.map(_buildEduCard),
                  const SizedBox(height: 16),
                ],

                // ── Skills – Circular % ──
                if (data.skills.isNotEmpty) ...[
                  _sectionTitle('Kỹ Năng'),
                  const SizedBox(height: 10),
                  ...data.skills.map(_buildSkillGrid),
                  const SizedBox(height: 16),
                ],

                // ── Projects ──
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
                    spacing: 8,
                    runSpacing: 6,
                    children: data.languages
                        .map((l) => _badge('${l.name} — ${l.proficiency}'))
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

  Widget _contactChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: _primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: _badgeText)),
    );
  }

  Widget _buildExpCard(CVExperience exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exp.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
          Text(
            '${exp.company}${exp.location != null ? " — ${exp.location}" : ""}',
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
          Text(
            '${exp.startDate ?? ""} — ${exp.isCurrent ? "Hiện tại" : exp.endDate ?? ""}',
            style: TextStyle(
                fontSize: 11, color: _textMuted.withValues(alpha: 0.7)),
          ),
          if (exp.description != null) ...[
            const SizedBox(height: 6),
            Text(exp.description!,
                style: const TextStyle(
                    fontSize: 12, color: _textDark, height: 1.5)),
          ],
          if (exp.achievements.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...exp.achievements.map((a) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: _primary, fontSize: 12)),
                      Expanded(
                          child: Text(a,
                              style: const TextStyle(
                                  fontSize: 12, color: _textDark))),
                    ],
                  ),
                )),
          ],
          if (exp.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 4,
                children: exp.technologies.map((t) => _badge(t)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildEduCard(CVEducation edu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(edu.degree,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
          Text(edu.institution,
              style: const TextStyle(fontSize: 12, color: _textMuted)),
          Text(
            '${edu.startDate ?? ""} — ${edu.endDate ?? "Hiện tại"}${edu.gpa != null ? " | GPA: ${edu.gpa}" : ""}',
            style: TextStyle(
                fontSize: 11, color: _textMuted.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillGrid(CVSkillCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cat.category != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                cat.category!,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _primary),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: cat.skills.map((skill) {
              final pct = (skill.level.clamp(0, 5) * 20).toDouble();
              return SizedBox(
                width: 56,
                child: Column(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomPaint(
                        painter: _CircularSkillPainter(pct / 100.0, _primary),
                        child: Center(
                          child: Text('${pct.toInt()}%',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _primary)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(skill.name,
                        style: const TextStyle(fontSize: 10, color: _textDark),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            }).toList(),
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
        border: Border(left: BorderSide(color: _primary, width: 3)),
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
                spacing: 6,
                runSpacing: 4,
                children: proj.technologies.map((t) => _badge(t)).toList()),
          ],
          if (proj.outcomes.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...proj.outcomes.map((o) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: _primary, fontSize: 12)),
                      Expanded(
                          child: Text(o,
                              style: const TextStyle(
                                  fontSize: 12, color: _textDark))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCertItem(CVCertificate cert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, size: 16, color: _primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textDark)),
                if (cert.issuingOrganization != null)
                  Text(
                    '${cert.issuingOrganization}${cert.issueDate != null ? " — ${cert.issueDate}" : ""}',
                    style: const TextStyle(fontSize: 11, color: _textMuted),
                  ),
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
        border: Border(left: BorderSide(color: _primaryLight, width: 3)),
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
                fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted),
          ),
        ],
      ),
    );
  }
}

/// Draws a circular progress ring for skill percentage.
class _CircularSkillPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularSkillPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularSkillPainter old) => old.progress != progress;
}
