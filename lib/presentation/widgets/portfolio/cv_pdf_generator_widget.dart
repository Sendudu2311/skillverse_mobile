import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/cv_structured_data.dart';

/// Native PDF Generator for CVs.
/// Creates a clean, professional, ATS-friendly A4 PDF document based on CVStructuredData.
class CVPdfGeneratorWidget {
  CVPdfGeneratorWidget._();

  static const _primaryColor = PdfColor.fromInt(0xFF2563EB); // Indigo-600
  static const _textDark = PdfColor.fromInt(0xFF1E293B); // Slate-800
  static const _textLight = PdfColor.fromInt(0xFF64748B); // Slate-500
  static const _bgLight = PdfColor.fromInt(0xFFF8FAFC); // Slate-50

  /// Generate full PDF bytes from CVData.
  static Future<Uint8List> generateCvPdf(CVStructuredData cvData) async {
    // Load Vietnamese-compatible font (same as Learning Report)
    final fontData = await rootBundle.load('assets/fonts/Roboto-Variable.ttf');
    final roboto = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: roboto, bold: roboto),
    );

    // Xây dựng trang PDF với cấu trúc 2 cột sử dụng Partitions (hỗ trợ tràn trang)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Partitions(
              children: [
                // Left Column (Sidebar) — 30%
                pw.Partition(
                  flex: 3,
                  child: pw.Container(
                    color: _bgLight,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildContactInfo(cvData.personalInfo),
                        pw.SizedBox(height: 24),
                        _buildSkillsSection(cvData.skills),
                        if (cvData.languages.isNotEmpty) ...[
                          pw.SizedBox(height: 24),
                          _buildLanguagesSection(cvData.languages),
                        ],
                        if (cvData.certificates.isNotEmpty) ...[
                          pw.SizedBox(height: 24),
                          _buildCertificatesSection(cvData.certificates),
                        ],
                      ],
                    ),
                  ),
                ),

                // Right Column (Main Content) — 70%
                pw.Partition(
                  flex: 7,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(left: 16),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        left: pw.BorderSide(
                          color: PdfColor.fromInt(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildHeader(cvData.personalInfo),
                        if (cvData.summary.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          _buildSummarySection(cvData.summary),
                        ],
                        if (cvData.experience.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          _buildExperienceSection(cvData.experience),
                        ],
                        if (cvData.education.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          _buildEducationSection(cvData.education),
                        ],
                        if (cvData.projects.isNotEmpty) ...[
                          pw.SizedBox(height: 20),
                          _buildProjectsSection(cvData.projects),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ================= Helpers =================
  static final _templateNames = RegExp(
    r'\b(professional|modern|minimal|creative)\b',
    caseSensitive: false,
  );

  /// Strip leaked template names from fullName (backend AI bug).
  static String _cleanName(String name) => name
      .replaceAll(_templateNames, '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  // ================= Header =================
  static pw.Widget _buildHeader(CVPersonalInfo info) {
    final cleanName = _cleanName(info.fullName);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          cleanName.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 2,
          ),
        ),
        if (info.professionalTitle != null &&
            info.professionalTitle!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              info.professionalTitle!,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildContactInfo(CVPersonalInfo info) {
    final items = <pw.Widget>[];

    void addContact(String icon, String? value) {
      if (value != null && value.isNotEmpty) {
        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 14,
                  child: pw.Text(
                    icon,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _primaryColor,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    value,
                    style: const pw.TextStyle(fontSize: 10, color: _textDark),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Using simple text characters instead of exact icons to ensure font compatibility
    addContact('•', info.email);
    addContact('•', info.phone);
    addContact('•', info.location);
    addContact('•', info.linkedinUrl);
    addContact('•', info.portfolioUrl);
    addContact('•', info.githubUrl);

    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('CONTACT'),
        pw.SizedBox(height: 12),
        ...items,
      ],
    );
  }

  // ================= Sidebar Sections =================
  static pw.Widget _buildSkillsSection(List<CVSkillCategory> skills) {
    if (skills.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('SKILLS'),
        pw.SizedBox(height: 12),
        ...skills.map(
          (category) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  category.category ?? '',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.SizedBox(height: 4),
                ...category.skills.map(
                  (s) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '- ',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: _primaryColor,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            s.name,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: _textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLanguagesSection(List<CVLanguage> languages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('LANGUAGES'),
        pw.SizedBox(height: 12),
        ...languages.map(
          (lang) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  lang.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.Text(
                  lang.proficiency,
                  style: const pw.TextStyle(fontSize: 10, color: _textLight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCertificatesSection(List<CVCertificate> certificates) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSidebarTitle('CERTIFICATES'),
        pw.SizedBox(height: 12),
        ...certificates.map(
          (cert) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cert.title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${cert.issuingOrganization} | ${cert.issueDate ?? ""}',
                  style: const pw.TextStyle(fontSize: 9, color: _textLight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSidebarTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1.5, width: 30, color: _primaryColor),
      ],
    );
  }

  // ================= Main Content Sections =================
  static pw.Widget _buildMainTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 1,
          width: double.infinity,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildSummarySection(String summary) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildMainTitle('SUMMARY'),
        pw.Text(
          summary,
          style: const pw.TextStyle(
            fontSize: 11,
            color: _textDark,
            lineSpacing: 2,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildExperienceSection(List<CVExperience> experience) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildMainTitle('EXPERIENCE'),
        ...experience.map((exp) {
          final dateStr = (exp.startDate != null)
              ? '${exp.startDate} - ${exp.isCurrent ? "Present" : (exp.endDate ?? "")}'
              : "";

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp.title,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${exp.company}${exp.location != null ? " • ${exp.location}" : ""}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _textLight,
                  ),
                ),
                if (exp.description != null && exp.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    exp.description!,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _textDark,
                      lineSpacing: 1.5,
                    ),
                  ),
                ],
                if (exp.achievements.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  ...exp.achievements.map(
                    (ach) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2, right: 6),
                            child: pw.Text(
                              '•',
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              ach,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (exp.technologies.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Tech Stack: ${exp.technologies.join(", ")}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: _textLight,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildEducationSection(List<CVEducation> education) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildMainTitle('EDUCATION'),
        ...education.map((edu) {
          final dateStr = (edu.startDate != null)
              ? '${edu.startDate} - ${edu.endDate ?? "Present"}'
              : "";

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        edu.degree,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      edu.institution,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: _textLight,
                      ),
                    ),
                    if (edu.gpa != null && edu.gpa!.isNotEmpty)
                      pw.Text(
                        'GPA: ${edu.gpa}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: _textDark,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildProjectsSection(List<CVProject> projects) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildMainTitle('PROJECTS'),
        ...projects.map((proj) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        proj.title,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                    ),
                    if (proj.role != null && proj.role!.isNotEmpty)
                      pw.Text(
                        proj.role!,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                  ],
                ),
                if (proj.description != null &&
                    proj.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    proj.description!,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _textDark,
                      lineSpacing: 1.5,
                    ),
                  ),
                ],
                if (proj.outcomes.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  ...proj.outcomes.map(
                    (out) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2, right: 6),
                            child: pw.Text(
                              '•',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              out,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (proj.technologies.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Technologies: ${proj.technologies.join(", ")}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: _textLight,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
