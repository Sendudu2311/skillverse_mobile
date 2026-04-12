import 'package:flutter/material.dart';
import '../../../../data/models/cv_structured_data.dart';

/// Minimal CV Template — Ultra-clean single-column layout.
/// Mirrors Web Prototype's `MinimalTemplate.tsx`.
class CVMinimalTemplate extends StatelessWidget {
  final CVStructuredData data;
  const CVMinimalTemplate({super.key, required this.data});

  static const _textDark = Color(0xFF111827);
  static const _textMuted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final pi = data.personalInfo;
    final allSkills = data.skills.expand((c) => c.skills.map((s) => s.name)).toList();

    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Text(
              pi.fullName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
            if (pi.professionalTitle != null)
              Text(
                pi.professionalTitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 8),
            // Contact line (pipe-separated)
            DefaultTextStyle(
              style: const TextStyle(fontSize: 12, color: _textMuted),
              child: Wrap(
                children: _buildContactItems(pi),
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary ──
            if (data.summary.isNotEmpty) ...[
              _section('Giới thiệu'),
              Text(data.summary,
                  style: const TextStyle(
                      fontSize: 13, color: _textDark, height: 1.6)),
              const SizedBox(height: 18),
            ],

            // ── Experience ──
            if (data.experience.isNotEmpty) ...[
              _section('Kinh nghiệm'),
              ...data.experience.map(_buildExpItem),
              const SizedBox(height: 14),
            ],

            // ── Education ──
            if (data.education.isNotEmpty) ...[
              _section('Học vấn'),
              ...data.education.map(_buildEduItem),
              const SizedBox(height: 14),
            ],

            // ── Skills ──
            if (allSkills.isNotEmpty) ...[
              _section('Kỹ năng'),
              Text(
                allSkills.join(', '),
                style: const TextStyle(
                    fontSize: 13, color: _textDark, height: 1.5),
              ),
              const SizedBox(height: 14),
            ],

            // ── Projects ──
            if (data.projects.isNotEmpty) ...[
              _section('Dự án'),
              ...data.projects.map(_buildProjectItem),
              const SizedBox(height: 14),
            ],

            // ── Certificates ──
            if (data.certificates.isNotEmpty) ...[
              _section('Chứng chỉ'),
              ...data.certificates.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${c.title} — ${c.issuingOrganization ?? ""}${c.issueDate != null ? " (${c.issueDate})" : ""}',
                      style: const TextStyle(fontSize: 12, color: _textDark),
                    ),
                  )),
              const SizedBox(height: 14),
            ],

            // ── Languages ──
            if (data.languages.isNotEmpty) ...[
              _section('Ngôn ngữ'),
              Text(
                data.languages
                    .map((l) => '${l.name} (${l.proficiency})')
                    .join(', '),
                style: const TextStyle(fontSize: 13, color: _textDark),
              ),
              const SizedBox(height: 14),
            ],

            // ── Endorsements ──
            if (data.endorsements.isNotEmpty) ...[
              _section('Lời giới thiệu'),
              ...data.endorsements.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '"${e.quote}" — ${e.authorName}${e.authorTitle != null ? ", ${e.authorTitle}" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _textDark,
                        height: 1.5,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ─── helpers ───

  List<Widget> _buildContactItems(CVPersonalInfo pi) {
    final items = <String>[
      if (pi.email != null) pi.email!,
      if (pi.phone != null) pi.phone!,
      if (pi.location != null) pi.location!,
      if (pi.linkedinUrl != null) 'LinkedIn',
      if (pi.githubUrl != null) 'GitHub',
    ];
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        widgets.add(const Text('  |  '));
      }
      widgets.add(Text(items[i]));
    }
    return widgets;
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: _border),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildExpItem(CVExperience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(exp.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
              Text(
                '${exp.startDate ?? ""} — ${exp.isCurrent ? "Hiện tại" : exp.endDate ?? ""}',
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          Text(
            '${exp.company}${exp.location != null ? ", ${exp.location}" : ""}',
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
          if (exp.description != null) ...[
            const SizedBox(height: 4),
            Text(exp.description!,
                style: const TextStyle(
                    fontSize: 12, color: _textDark, height: 1.5)),
          ],
          if (exp.achievements.isNotEmpty) ...[
            ...exp.achievements.map((a) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 2),
                  child: Text('— $a',
                      style: const TextStyle(fontSize: 12, color: _textDark)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEduItem(CVEducation edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(edu.degree,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
              ),
              Text(
                '${edu.startDate ?? ""} — ${edu.endDate ?? "Hiện tại"}',
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          Text(
            '${edu.institution}${edu.gpa != null ? " — GPA: ${edu.gpa}" : ""}',
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(CVProject proj) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(proj.title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textDark)),
          if (proj.description != null)
            Text(proj.description!,
                style: const TextStyle(
                    fontSize: 12, color: _textDark, height: 1.5)),
          if (proj.technologies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Tech: ${proj.technologies.join(", ")}',
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
