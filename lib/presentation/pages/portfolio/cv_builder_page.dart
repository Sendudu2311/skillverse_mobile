import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:printing/printing.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../data/models/cv_structured_data.dart';
import '../../widgets/portfolio/cv_pdf_generator_widget.dart';
import 'cv_preview_page.dart';
import 'edit_cv_page.dart';

class CVBuilderPage extends StatefulWidget {
  const CVBuilderPage({super.key});

  @override
  State<CVBuilderPage> createState() => _CVBuilderPageState();
}

class _CVBuilderPageState extends State<CVBuilderPage> {
  String _selectedTemplate = 'professional';
  bool _isGenerating = false;

  final _targetRoleController = TextEditingController();
  final _targetIndustryController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();
  bool _includeProjects = true;
  bool _includeCertificates = true;
  bool _includeReviews = true;

  static const _templates = [
    _TemplateInfo(
      id: 'professional',
      name: 'Chuyên nghiệp',
      icon: Icons.business_center,
      description: 'Sidebar tối, bố cục 2 cột',
      gradientColors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    ),
    _TemplateInfo(
      id: 'modern',
      name: 'Hiện đại',
      icon: Icons.auto_awesome,
      description: 'Gradient header, circular skill chart',
      gradientColors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
    ),
    _TemplateInfo(
      id: 'minimal',
      name: 'Tối giản',
      icon: Icons.text_fields,
      description: 'Clean single-column, typography-first',
      gradientColors: [Color(0xFF374151), Color(0xFF6B7280)],
    ),
    _TemplateInfo(
      id: 'creative',
      name: 'Sáng tạo',
      icon: Icons.palette,
      description: 'Timeline layout, bold gradient hero',
      gradientColors: [Color(0xFFDB2777), Color(0xFF7C3AED)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().loadCVs();
    });
  }

  @override
  void dispose() {
    _targetRoleController.dispose();
    _targetIndustryController.dispose();
    _additionalInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _generateCV() async {
    final portfolioProvider = context.read<PortfolioProvider>();
    setState(() => _isGenerating = true);

    final request = GenerateCVRequest(
      templateName: _selectedTemplate,
      targetRole: _targetRoleController.text.trim().isNotEmpty
          ? _targetRoleController.text.trim()
          : null,
      targetIndustry: _targetIndustryController.text.trim().isNotEmpty
          ? _targetIndustryController.text.trim()
          : null,
      additionalInstructions:
          _additionalInstructionsController.text.trim().isNotEmpty
          ? _additionalInstructionsController.text.trim()
          : null,
      includeProjects: _includeProjects,
      includeCertificates: _includeCertificates,
      includeReviews: _includeReviews,
    );

    final success = await portfolioProvider.generateCV(request: request);

    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (success) {
      ErrorHandler.showSuccessSnackBar(context, 'Tạo CV thành công!');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        portfolioProvider.errorMessage ?? 'Có lỗi xảy ra',
      );
    }
  }

  Future<void> _setActiveCV(int cvId) async {
    final portfolioProvider = context.read<PortfolioProvider>();
    final success = await portfolioProvider.setActiveCV(cvId);
    if (mounted && success) {
      ErrorHandler.showSuccessSnackBar(context, 'Đã thiết lập CV hoạt động');
    }
  }

  void _openCVPreview(CVDto cv) {
    if (cv.cvJson == null || cv.cvJson!.isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'CV chưa có dữ liệu. Hãy tạo lại CV.',
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CVPreviewPage(cv: cv)),
    );
  }

  Future<void> _shareCV(CVDto cv) async {
    final pdfUrl = cv.pdfUrl;
    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      await Share.share('CV của tôi: $pdfUrl');
      return;
    }
    final summary = cv.cvJson ?? cv.cvContent ?? 'CV SkillVerse';
    await Share.share('CV SkillVerse - ${cv.templateName ?? ""}: $summary');
  }

  Future<void> _openCVPdf(CVDto cv) async {
    final cvData = CVStructuredData.tryParse(cv.cvJson);
    if (cvData == null) {
      if (mounted)
        ErrorHandler.showErrorSnackBar(context, 'Dữ liệu CV không hợp lệ.');
      return;
    }
    try {
      final pdfBytes = await CVPdfGeneratorWidget.generateCvPdf(cvData);
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name:
            'CV_SkillVerse_${cvData.personalInfo.fullName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, 'Lỗi tạo PDF: $e');
    }
  }

  void _navigateToEditCV(CVDto cv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCVPage(cv: cv)),
    ).then((result) {
      if (result == true && mounted) {
        context.read<PortfolioProvider>().loadCVs();
      }
    });
  }

  Future<void> _deleteCV(int cvId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa CV này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final portfolioProvider = context.read<PortfolioProvider>();
      final success = await portfolioProvider.deleteCV(cvId);
      if (mounted && success) {
        ErrorHandler.showSuccessSnackBar(context, 'Đã xóa CV');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(title: 'Quản lý CV', icon: Icons.description),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CardSkeleton(imageHeight: null),
                  SizedBox(height: 16),
                  TextSkeleton(lines: 6),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ TEMPLATE SELECTOR (horizontal carousel) ═══
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accentCyan,
                            AppTheme.primaryBlueDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CHỌN MẪU CV',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _templates.map((t) {
                    final selected = _selectedTemplate == t.id;
                    return _buildTemplateCard(t, selected, isDark);
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ═══ AI CUSTOMIZATION ═══
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accentCyan,
                            AppTheme.primaryBlueDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TÙY CHỈNH AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'AI sẽ tối ưu CV dựa trên thông tin bạn cung cấp',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _targetRoleController,
                          decoration: const InputDecoration(
                            labelText: 'Vị trí mục tiêu',
                            hintText: 'VD: Senior Flutter Developer',
                            prefixIcon: Icon(Icons.work_outline, size: 20),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _targetIndustryController,
                          decoration: const InputDecoration(
                            labelText: 'Ngành nghề',
                            hintText: 'VD: Fintech, E-commerce',
                            prefixIcon: Icon(Icons.business, size: 20),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _additionalInstructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Yêu cầu đặc biệt',
                            hintText: 'VD: Nhấn mạnh React và Node.js...',
                            prefixIcon: Icon(Icons.edit_note, size: 20),
                            isDense: true,
                          ),
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ═══ CONTENT TOGGLES ═══
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Bao gồm Dự án',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _includeProjects,
                          onChanged: (v) =>
                              setState(() => _includeProjects = v),
                          secondary: const Icon(
                            Icons.folder_outlined,
                            size: 20,
                          ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Bao gồm Chứng chỉ',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _includeCertificates,
                          onChanged: (v) =>
                              setState(() => _includeCertificates = v),
                          secondary: const Icon(
                            Icons.verified_outlined,
                            size: 20,
                          ),
                          dense: true,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Bao gồm Đánh giá',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _includeReviews,
                          onChanged: (v) => setState(() => _includeReviews = v),
                          secondary: const Icon(
                            Icons.rate_review_outlined,
                            size: 20,
                          ),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ═══ GENERATE BUTTON ═══
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateCV,
                    icon: _isGenerating
                        ? CommonLoading.small()
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isGenerating ? 'Đang tạo CV...' : 'Tạo CV bằng AI',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ═══ MY CVs ═══
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accentCyan,
                            AppTheme.primaryBlueDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CV CỦA TÔI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.cvs.length} CV',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.cvs.isEmpty)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có CV nào',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tạo CV đầu tiên bằng AI ở trên',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...provider.cvs.map((cv) => _buildCVCard(cv, isDark)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Template Card (horizontal carousel item) ───
  Widget _buildTemplateCard(_TemplateInfo t, bool selected, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = t.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: t.gradientColors,
                )
              : null,
          color: selected
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08)),
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              t.icon,
              size: 32,
              color: selected
                  ? Colors.white
                  : (isDark ? AppTheme.darkTextSecondary : Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              t.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              t.description,
              style: TextStyle(
                fontSize: 9,
                color: selected
                    ? Colors.white.withValues(alpha: 0.8)
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── CV List Card ───
  Widget _buildCVCard(CVDto cv, bool isDark) {
    final isActive = cv.isActive ?? false;
    final templateKey = (cv.templateName ?? '').toLowerCase();
    final templateInfo = _templates.firstWhere(
      (t) => t.id == templateKey,
      orElse: () => _templates.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Template color indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [AppTheme.successColor, const Color(0xFF059669)]
                        : templateInfo.gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? Icons.check_circle : templateInfo.icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            cv.templateName ?? 'CV của tôi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cv.createdAt ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                itemBuilder: (context) => [
                  if (!isActive)
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 12),
                          Text('Kích hoạt'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 12),
                        Text('Xem trước'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, size: 20),
                        SizedBox(width: 12),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'open_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Mở file PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share_link',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 12),
                        Text('Chia sẻ link'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'activate':
                      _setActiveCV(cv.id!);
                      break;
                    case 'preview':
                      _openCVPreview(cv);
                      break;
                    case 'edit':
                      _navigateToEditCV(cv);
                      break;
                    case 'open_pdf':
                      _openCVPdf(cv);
                      break;
                    case 'share_link':
                      _shareCV(cv);
                      break;
                    case 'delete':
                      _deleteCV(cv.id!);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateInfo {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final List<Color> gradientColors;

  const _TemplateInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.gradientColors,
  });
}
