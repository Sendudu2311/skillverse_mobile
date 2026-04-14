import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../data/models/cv_structured_data.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/portfolio_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';

/// Full-form editor for a [CVDto].
/// Parses [cv.cvJson] (structured JSON) into editable fields,
/// then regenerates both cvJson + cvContent (HTML) on save.
class EditCVPage extends StatefulWidget {
  final CVDto cv;

  const EditCVPage({super.key, required this.cv});

  @override
  State<EditCVPage> createState() => _EditCVPageState();
}

class _EditCVPageState extends State<EditCVPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Personal Info
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _professionalTitleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _githubCtrl;

  // Sections (flattened from arrays to editable text)
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _educationCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _projectsCtrl;
  late final TextEditingController _certificatesCtrl;

  /// Original parsed data — kept for fields we don't expose in the form
  CVStructuredData? _originalData;

  @override
  void initState() {
    super.initState();
    _originalData = CVStructuredData.tryParse(widget.cv.cvJson);

    final info = _originalData?.personalInfo;
    _fullNameCtrl = TextEditingController(text: info?.fullName ?? '');
    _professionalTitleCtrl = TextEditingController(
      text: info?.professionalTitle ?? '',
    );
    _emailCtrl = TextEditingController(text: info?.email ?? '');
    _phoneCtrl = TextEditingController(text: info?.phone ?? '');
    _locationCtrl = TextEditingController(text: info?.location ?? '');
    _linkedinCtrl = TextEditingController(text: info?.linkedinUrl ?? '');
    _githubCtrl = TextEditingController(text: info?.githubUrl ?? '');

    _summaryCtrl = TextEditingController(text: _originalData?.summary ?? '');
    _experienceCtrl = TextEditingController(
      text: _flattenExperience(_originalData?.experience ?? []),
    );
    _educationCtrl = TextEditingController(
      text: _flattenEducation(_originalData?.education ?? []),
    );
    _skillsCtrl = TextEditingController(
      text: _flattenSkills(_originalData?.skills ?? []),
    );
    _projectsCtrl = TextEditingController(
      text: _flattenProjects(_originalData?.projects ?? []),
    );
    _certificatesCtrl = TextEditingController(
      text: _flattenCertificates(_originalData?.certificates ?? []),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _professionalTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    _summaryCtrl.dispose();
    _experienceCtrl.dispose();
    _educationCtrl.dispose();
    _skillsCtrl.dispose();
    _projectsCtrl.dispose();
    _certificatesCtrl.dispose();
    super.dispose();
  }

  // ─── Flatten structured arrays → readable text ─────────────────────────────

  String _flattenExperience(List<CVExperience> items) {
    return items
        .map((e) {
          final period = [
            e.startDate,
            e.isCurrent ? 'Hiện tại' : e.endDate,
          ].where((s) => s != null && s.isNotEmpty).join(' - ');
          final header = '${e.title} tại ${e.company}';
          final lines = <String>[
            header,
            if (period.isNotEmpty) period,
            if (e.description != null && e.description!.isNotEmpty)
              e.description!,
            if (e.achievements.isNotEmpty)
              e.achievements.map((a) => '• $a').join('\n'),
          ];
          return lines.join('\n');
        })
        .join('\n\n');
  }

  String _flattenEducation(List<CVEducation> items) {
    return items
        .map((e) {
          final period = [
            e.startDate,
            e.endDate,
          ].where((s) => s != null && s.isNotEmpty).join(' - ');
          final lines = <String>[
            '${e.degree} — ${e.institution}',
            if (period.isNotEmpty) period,
            if (e.gpa != null && e.gpa!.isNotEmpty) 'GPA: ${e.gpa}',
          ];
          return lines.join('\n');
        })
        .join('\n\n');
  }

  String _flattenSkills(List<CVSkillCategory> categories) {
    return categories
        .map((cat) {
          final names = cat.skills.map((s) => s.name).join(', ');
          if (cat.category != null && cat.category!.isNotEmpty) {
            return '${cat.category}: $names';
          }
          return names;
        })
        .join('\n');
  }

  String _flattenProjects(List<CVProject> items) {
    return items
        .map((p) {
          final lines = <String>[
            p.title,
            if (p.role != null && p.role!.isNotEmpty) 'Vai trò: ${p.role}',
            if (p.description != null && p.description!.isNotEmpty)
              p.description!,
            if (p.technologies.isNotEmpty)
              'Công nghệ: ${p.technologies.join(", ")}',
          ];
          return lines.join('\n');
        })
        .join('\n\n');
  }

  String _flattenCertificates(List<CVCertificate> items) {
    return items
        .map((c) {
          final lines = <String>[
            c.title,
            if (c.issuingOrganization != null) c.issuingOrganization!,
            if (c.issueDate != null) c.issueDate!,
          ];
          return lines.join(' — ');
        })
        .join('\n');
  }

  // ─── Build updated JSON (preserving original structure where possible) ─────

  Map<String, dynamic> _buildUpdatedJson() {
    // Start from original if available, else build fresh
    final base = _originalData != null
        ? json.decode(widget.cv.cvJson!) as Map<String, dynamic>
        : <String, dynamic>{};

    // Update personalInfo
    base['personalInfo'] = {
      'fullName': _fullNameCtrl.text.trim(),
      'professionalTitle': _professionalTitleCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'linkedinUrl': _linkedinCtrl.text.trim(),
      'githubUrl': _githubCtrl.text.trim(),
      // Preserve avatarUrl/portfolioUrl from original
      if (_originalData?.personalInfo.avatarUrl != null)
        'avatarUrl': _originalData!.personalInfo.avatarUrl,
      if (_originalData?.personalInfo.portfolioUrl != null)
        'portfolioUrl': _originalData!.personalInfo.portfolioUrl,
    };

    // Update summary (plain text field)
    base['summary'] = _summaryCtrl.text.trim();

    // NOTE: experience/education/skills/projects/certificates are complex arrays.
    // For a simple text edit we keep the original arrays to preserve structure.
    // Only summary and personalInfo are updated from form fields directly.
    // Future: implement per-item editing for each array.

    return base;
  }

  // ─── Generate HTML from form data ──────────────────────────────────────────

  String _generateHtml() {
    final fn = _fullNameCtrl.text.trim();
    final pt = _professionalTitleCtrl.text.trim();
    final em = _emailCtrl.text.trim();
    final ph = _phoneCtrl.text.trim();
    final lo = _locationCtrl.text.trim();
    final li = _linkedinCtrl.text.trim();
    final gh = _githubCtrl.text.trim();

    final contactParts = [
      if (em.isNotEmpty) '<span>📧 $em</span>',
      if (ph.isNotEmpty) '<span>📞 $ph</span>',
      if (lo.isNotEmpty) '<span>📍 $lo</span>',
      if (li.isNotEmpty)
        '<span><a href="$li" target="_blank" style="color:#0077b5;text-decoration:none;">🔗 LinkedIn</a></span>',
      if (gh.isNotEmpty)
        '<span><a href="$gh" target="_blank" style="color:#333;text-decoration:none;">🐙 GitHub</a></span>',
    ].join('\n            ');

    String section(String title, String content) {
      if (content.trim().isEmpty) return '';
      final body = content.replaceAll('\n', '<br>');
      return '''
        <section style="margin-bottom: 25px;">
          <h3 style="color: #1e40af; border-bottom: 1px solid #e5e7eb; padding-bottom: 5px; margin-bottom: 15px;">$title</h3>
          <div style="line-height: 1.6;">$body</div>
        </section>''';
    }

    return '''
      <div style="font-family: 'Inter', 'Roboto', 'Arial', sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: white; color: #333;">
        <header style="text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 2px solid #3b82f6;">
          <h1 style="color: #1e40af; margin: 0 0 10px 0; font-size: 2.5rem;">$fn</h1>
          <h2 style="color: #3b82f6; margin: 0 0 15px 0; font-size: 1.5rem; font-weight: 400;">$pt</h2>
          <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; font-size: 0.9rem; color: #666;">
            $contactParts
          </div>
        </header>
        ${section('Tóm tắt', _summaryCtrl.text)}
        ${section('Kinh nghiệm', _experienceCtrl.text)}
        ${section('Học vấn', _educationCtrl.text)}
        ${section('Kỹ năng', _skillsCtrl.text)}
        ${section('Dự án', _projectsCtrl.text)}
        ${section('Chứng chỉ', _certificatesCtrl.text)}
      </div>
    ''';
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final provider = context.read<PortfolioProvider>();
      final updatedJsonMap = _buildUpdatedJson();
      final success = await provider.updateCV(
        widget.cv.id!,
        UpdateCVRequest(
          cvContent: _generateHtml(),
          cvJson: json.encode(updatedJsonMap),
        ),
      );
      if (!mounted) return;
      if (success) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã lưu CV thành công!');
        Navigator.pop(context, true);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          provider.errorMessage ?? 'Không thể lưu CV.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(title: 'Chỉnh sửa CV', icon: Icons.edit_note),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard('Thông tin cá nhân', Icons.person_outline, [
                _field(_fullNameCtrl, 'Họ và tên', required: true),
                _field(_professionalTitleCtrl, 'Chức danh'),
                _field(_locationCtrl, 'Địa chỉ'),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Liên hệ', Icons.contact_mail_outlined, [
                _field(
                  _emailCtrl,
                  'Email',
                  keyboard: TextInputType.emailAddress,
                ),
                _field(_phoneCtrl, 'Điện thoại', keyboard: TextInputType.phone),
                _field(
                  _linkedinCtrl,
                  'LinkedIn URL',
                  keyboard: TextInputType.url,
                ),
                _field(_githubCtrl, 'GitHub URL', keyboard: TextInputType.url),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Tóm tắt', Icons.summarize_outlined, [
                _field(_summaryCtrl, 'Giới thiệu bản thân', maxLines: 4),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Kinh nghiệm', Icons.work_outline, [
                _field(
                  _experienceCtrl,
                  'Mô tả kinh nghiệm làm việc',
                  maxLines: 6,
                ),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Học vấn', Icons.school_outlined, [
                _field(_educationCtrl, 'Mô tả học vấn', maxLines: 4),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Kỹ năng', Icons.psychology_outlined, [
                _field(_skillsCtrl, 'Liệt kê kỹ năng', maxLines: 4),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Dự án', Icons.folder_outlined, [
                _field(_projectsCtrl, 'Mô tả dự án nổi bật', maxLines: 5),
              ]),
              const SizedBox(height: 16),
              _sectionCard('Chứng chỉ', Icons.verified_outlined, [
                _field(_certificatesCtrl, 'Liệt kê chứng chỉ', maxLines: 4),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: AppTheme.primaryBlueDark,
        foregroundColor: Colors.white,
        icon: _isSaving ? CommonLoading.small() : const Icon(Icons.save),
        label: Text(_isSaving ? 'Đang lưu...' : 'Lưu CV'),
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> fields) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlueDark),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < fields.length; i++) ...[
              fields[i],
              if (i < fields.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: required
          ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập $label.' : null
          : null,
    );
  }
}
