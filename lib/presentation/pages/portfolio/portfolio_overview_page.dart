import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/portfolio_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/html_helper.dart';
import '../../../core/utils/number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'widgets/cv_pdf_generator_widget.dart';
import '../../../data/models/cv_structured_data.dart';
import 'edit_extended_profile_page.dart';
import 'edit_project_page.dart';
import 'add_certificate_page.dart';
import 'cv_builder_page.dart';
import 'edit_cv_page.dart';
import 'public_portfolio_page.dart';

class PortfolioOverviewPage extends StatefulWidget {
  const PortfolioOverviewPage({super.key});

  @override
  State<PortfolioOverviewPage> createState() => _PortfolioOverviewPageState();
}

class _PortfolioOverviewPageState extends State<PortfolioOverviewPage> {
  late bool isDark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPortfolio();
    });
  }

  Future<void> _loadPortfolio() async {
    final portfolioProvider = context.read<PortfolioProvider>();
    await portfolioProvider.checkExtendedProfile();
    if (portfolioProvider.hasExtendedProfile) {
      try {
        await Future.wait([
          portfolioProvider.loadMyPortfolio(),
          portfolioProvider.loadProjects(),
          portfolioProvider.loadCertificates(),
          portfolioProvider.loadReviews(),
          portfolioProvider.loadActiveCV(),
          portfolioProvider.loadCompletedMissions(),
          portfolioProvider.loadSystemCertificates(),
          portfolioProvider.loadVerifiedSkills(
            userId: context.read<AuthProvider>().user?.id,
          ),
        ]);
      } catch (e) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _navigateToCreateProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditExtendedProfilePage(isCreate: true),
      ),
    );
    if (result == true && mounted) {
      _loadPortfolio();
    }
  }

  Future<void> _navigateToEditProfile(ExtendedProfileDto profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditExtendedProfilePage(existingProfile: profile, isCreate: false),
      ),
    );
    if (result == true && mounted) {
      _loadPortfolio();
    }
  }

  Future<void> _navigateToAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProjectPage(isCreate: true),
      ),
    );
    if (result == true && mounted) {
      await context.read<PortfolioProvider>().loadProjects();
    }
  }

  Future<void> _navigateToEditProject(ProjectDto project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProjectPage(existingProject: project, isCreate: false),
      ),
    );
    if (result == true && mounted) {
      await context.read<PortfolioProvider>().loadProjects();
    }
  }

  Future<void> _navigateToAddCertificate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCertificatePage()),
    );
    if (result == true && mounted) {
      await context.read<PortfolioProvider>().loadCertificates();
    }
  }

  Future<void> _openActiveCVPdf(CVDto cv) async {
    final cvData = CVStructuredData.tryParse(cv.cvJson);
    if (cvData == null) {
      if (mounted)
        ErrorHandler.showErrorSnackBar(context, 'Dữ liệu CV không hợp lệ.');
      return;
    }
    try {
      final pdfBytes = await CVPdfGeneratorWidget.generateCvPdf(cvData);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'CV_SkillVerse_${cvData.personalInfo.fullName.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, 'Lỗi tạo PDF: $e');
    }
  }

  void _navigateToEditActiveCV(CVDto cv) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCVPage(cv: cv)),
    ).then((result) {
      if (result == true && mounted) {
        context.read<PortfolioProvider>().loadActiveCV();
      }
    });
  }

  void _navigateToCVBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CVBuilderPage()),
    ).then((_) {
      if (mounted) {
        context.read<PortfolioProvider>().loadActiveCV();
      }
    });
  }

  void _navigateToPublicPortfolio(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PublicPortfolioPage(slug: slug)),
    );
  }

  void _sharePortfolioLink(String slug) {
    final link = 'https://skillverse.vn/portfolio/$slug';
    Clipboard.setData(ClipboardData(text: link));
    ErrorHandler.showSuccessSnackBar(context, 'Đã sao chép: $link');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isDark = this.isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(title: 'Portfolio', icon: Icons.folder_special),
      body: Stack(
        children: [
          // Galaxy Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [AppTheme.galaxyDarkest, AppTheme.galaxyDark]
                    : [Colors.grey.shade50, Colors.white],
              ),
            ),
          ),

          // Content
          Consumer<PortfolioProvider>(
            builder: (context, portfolioProvider, child) {
              if (portfolioProvider.isLoading) {
                return CommonLoading.center();
              }

              if (portfolioProvider.errorMessage != null) {
                return ErrorStateWidget(
                  message: portfolioProvider.errorMessage!,
                  onRetry: _loadPortfolio,
                );
              }

              if (!portfolioProvider.hasExtendedProfile) {
                return _buildNoProfileView(context);
              }

              return RefreshIndicator(
                onRefresh: _loadPortfolio,
                color: AppTheme.themePurpleStart,
                backgroundColor: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user info
                      _buildHeader(
                        context,
                        user,
                        portfolioProvider.extendedProfile,
                        portfolioProvider.activeCV,
                      ),

                      const SizedBox(height: 24),

                      // Extended Profile Section
                      if (portfolioProvider.extendedProfile != null)
                        _buildExtendedProfileSection(
                          context,
                          portfolioProvider.extendedProfile!,
                        ),

                      // Work Experience Section
                      if ((portfolioProvider
                              .extendedProfile
                              ?.workExperiences
                              ?.isNotEmpty ??
                          false)) ...[
                        const SizedBox(height: 24),
                        _buildWorkExperienceSection(
                          portfolioProvider.extendedProfile!.workExperiences!,
                        ),
                      ],

                      // Education Section
                      if ((portfolioProvider
                              .extendedProfile
                              ?.educationHistory
                              ?.isNotEmpty ??
                          false)) ...[
                        const SizedBox(height: 24),
                        _buildEducationSection(
                          portfolioProvider.extendedProfile!.educationHistory!,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Quick Stats
                      _buildQuickStats(
                        portfolioProvider.projects.length,
                        portfolioProvider.certificates.length,
                        portfolioProvider.reviews.length,
                      ),

                      const SizedBox(height: 24),

                      // Projects Section
                      _buildProjectsSection(
                        context,
                        portfolioProvider.projects,
                      ),

                      const SizedBox(height: 24),

                      // Completed Missions Section
                      _buildCompletedMissionsSection(
                        context,
                        portfolioProvider.completedMissions,
                      ),

                      const SizedBox(height: 24),

                      // Certificates Section
                      _buildCertificatesSection(
                        context,
                        portfolioProvider.certificates,
                        isSyncing: portfolioProvider.isSyncing,
                      ),

                      const SizedBox(height: 24),

                      // CV Section
                      _buildCVSection(context, portfolioProvider.activeCV),

                      const SizedBox(height: 24),

                      // Verified Skills Section
                      _buildVerifiedSkillsSection(
                        context,
                        portfolioProvider.verifiedSkills,
                      ),
                      const SizedBox(height: 24),

                      // Reviews Section
                      if (portfolioProvider.reviews.isNotEmpty)
                        _buildReviewsSection(portfolioProvider.reviews),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    ExtendedProfileDto? profile,
    CVDto? activeCV,
  ) {
    return GradientGlassCard(
      gradientColors: const [
        AppTheme.themePurpleStart,
        AppTheme.themePurpleEnd,
      ],
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.themePurpleStart.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              backgroundImage: profile?.avatarUrl.isNotEmpty == true
                  ? NetworkImage(profile!.avatarUrl)
                  : null,
              child: profile?.avatarUrl.isNotEmpty == true
                  ? null
                  : Text(
                      user?.fullName?.isNotEmpty == true
                          ? user!.fullName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.themePurpleStart,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (profile?.headline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile!.headline!,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (profile?.slug != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _navigateToPublicPortfolio(profile.slug ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '@${profile!.slug}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'Chỉnh sửa hồ sơ',
                onPressed: () {
                  if (profile != null) _navigateToEditProfile(profile);
                },
              ),
              if (profile?.slug != null)
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: 'Chia sẻ',
                  onPressed: () => _sharePortfolioLink(profile!.slug!),
                ),
              if (activeCV != null) ...[
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Mở PDF CV',
                  onPressed: () {
                    _openActiveCVPdf(activeCV);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.white),
                  tooltip: 'Sửa CV',
                  onPressed: () => _navigateToEditActiveCV(activeCV),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedProfileSection(
    BuildContext context,
    ExtendedProfileDto profile,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Về tôi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (profile.bio != null)
            Text(
              HtmlHelper.cleanHtml(profile.bio!),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
              ),
            ),
          if (profile.location != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.themePurpleStart,
                ),
                const SizedBox(width: 8),
                Text(
                  profile.location!,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ],

          // Social Links
          if (profile.website != null ||
              profile.githubUrl != null ||
              profile.linkedinUrl != null ||
              profile.behanceUrl != null ||
              profile.dribbbleUrl != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.website != null)
                  _buildSocialChip(Icons.language, 'Website', profile.website!),
                if (profile.githubUrl != null)
                  _buildSocialChip(Icons.code, 'GitHub', profile.githubUrl!),
                if (profile.linkedinUrl != null)
                  _buildSocialChip(
                    Icons.business,
                    'LinkedIn',
                    profile.linkedinUrl!,
                  ),
                if (profile.behanceUrl != null)
                  _buildSocialChip(
                    Icons.palette,
                    'Behance',
                    profile.behanceUrl!,
                  ),
                if (profile.dribbbleUrl != null)
                  _buildSocialChip(
                    Icons.sports_basketball,
                    'Dribbble',
                    profile.dribbbleUrl!,
                  ),
              ],
            ),
          ],

          // Expertise Areas
          if (profile.expertiseAreas != null &&
              profile.expertiseAreas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Chuyên môn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.expertiseAreas!
                  .map(
                    (area) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        area,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Years of experience badge
          if (profile.yearsOfExperience != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 16,
                  color: AppTheme.themeBlueStart,
                ),
                const SizedBox(width: 6),
                Text(
                  '${profile.yearsOfExperience} năm kinh nghiệm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkExperienceSection(List<PortfolioWorkExperienceDto> items) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.work_history,
                size: 18,
                color: AppTheme.themeBlueStart,
              ),
              const SizedBox(width: 8),
              Text(
                'Kinh nghiệm làm việc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((exp) {
            final dateRange =
                '${exp.startDate ?? ""} → ${exp.currentJob == true ? "Hiện tại" : (exp.endDate ?? "")}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppTheme.themeBlueStart,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.position ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          exp.companyName ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        if (exp.startDate != null)
                          Text(
                            dateRange,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        if (exp.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            exp.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<PortfolioEducationDto> items) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school,
                size: 18,
                color: AppTheme.themeOrangeStart,
              ),
              const SizedBox(width: 8),
              Text(
                'Học vấn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((edu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: const BoxDecoration(
                      color: AppTheme.themeOrangeStart,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu.degree ?? edu.institution ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          edu.institution ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white70
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        if (edu.fieldOfStudy != null)
                          Text(
                            edu.fieldOfStudy!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        if (edu.startDate != null)
                          Text(
                            '${edu.startDate} → ${edu.endDate ?? ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        if (edu.status != null)
                          Text(
                            edu.status!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.themeGreenStart,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSocialChip(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.themePurpleStart),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int projects, int certificates, int reviews) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Dự án',
            projects.toString(),
            Icons.work,
            AppTheme.themeBlueStart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Chứng chỉ',
            certificates.toString(),
            Icons.card_membership,
            AppTheme.themeOrangeStart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Đánh giá',
            reviews.toString(),
            Icons.star,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(
    BuildContext context,
    List<ProjectDto> projects,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dự án',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _navigateToAddProject,
              icon: const Icon(Icons.add, color: AppTheme.themeBlueStart),
              label: const Text(
                'Thêm',
                style: TextStyle(color: AppTheme.themeBlueStart),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          EmptyStateWidget(
            icon: Icons.work_outline,
            title: 'Không có dự án',
            subtitle: 'Chưa có dự án nào trong portfolio của bạn',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildProjectCard(projects[index]);
            },
          ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectDto project) {
    return GlassCard(
      onTap: () => _navigateToEditProject(project),
      child: Row(
        children: [
          if (project.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                project.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBackgroundSecondary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work, size: 32, color: Colors.white),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (project.isFeatured == true)
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                ),
                if (project.technologies != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.technologies!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (project.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    HtmlHelper.cleanHtml(project.description!),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white70
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Completed Missions Section ====================

  Widget _buildCompletedMissionsSection(
    BuildContext context,
    List<CompletedMissionDto> missions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhiệm vụ đã hoàn thành',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (missions.isEmpty)
          EmptyStateWidget(
            icon: Icons.assignment_outlined,
            title: 'Không có nhiệm vụ',
            subtitle: 'Chưa có nhiệm vụ nào được giao',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: missions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildMissionCard(missions[index]);
            },
          ),
      ],
    );
  }

  Widget _buildMissionCard(CompletedMissionDto mission) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.jobTitle ?? 'Nhiệm vụ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mission.recruiterCompanyName != null ||
                        mission.recruiterName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        mission.recruiterCompanyName ??
                            mission.recruiterName ??
                            '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: mission.status == 'PAID'
                      ? AppTheme.themeGreenStart.withValues(alpha: 0.15)
                      : AppTheme.themeBlueStart.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mission.status == 'PAID' ? 'Đã thanh toán' : 'Hoàn thành',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mission.status == 'PAID'
                        ? AppTheme.themeGreenStart
                        : AppTheme.themeBlueStart,
                  ),
                ),
              ),
            ],
          ),

          // Budget & Rating row
          if (mission.budget != null || mission.rating != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (mission.budget != null) ...[
                  Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mission.budgetDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (mission.rating != null) ...[
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormatter.formatRating(mission.rating!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Skills
          if (mission.requiredSkills != null &&
              mission.requiredSkills!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: mission.requiredSkills!
                  .take(5)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBackgroundSecondary
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== Certificates Section (with Sync) ====================

  Future<void> _handleSyncCertificates() async {
    final portfolioProvider = context.read<PortfolioProvider>();
    final count = await portfolioProvider.importSystemCertificates();
    if (!mounted) return;
    if (count >= 0) {
      ErrorHandler.showSuccessSnackBar(
        context,
        'Đã đồng bộ $count chứng chỉ từ hệ thống!',
      );
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        'Không thể đồng bộ chứng chỉ. Vui lòng thử lại.',
      );
    }
  }

  Widget _buildCertificatesSection(
    BuildContext context,
    List<CertificateDto> certificates, {
    bool isSyncing = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chứng chỉ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sync button
                isSyncing
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CommonLoading.small(
                            color: AppTheme.themeGreenStart,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _handleSyncCertificates,
                        icon: const Icon(
                          Icons.sync,
                          color: AppTheme.themeGreenStart,
                          size: 22,
                        ),
                        tooltip: 'Đồng bộ chứng chỉ hệ thống',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _navigateToAddCertificate,
                  icon: const Icon(Icons.add, color: AppTheme.themeOrangeStart),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(color: AppTheme.themeOrangeStart),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (certificates.isEmpty)
          EmptyStateWidget(
            icon: Icons.card_membership_outlined,
            title: 'Không có chứng chỉ',
            subtitle: 'Chưa có chứng chỉ nào trong portfolio của bạn',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certificates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildCertificateCard(certificates[index]);
            },
          ),
      ],
    );
  }

  Widget _buildCertificateCard(CertificateDto certificate) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.orangeGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_membership,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificate.issuer ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                if (certificate.issueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    certificate.issueDate!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCVSection(BuildContext context, CVDto? activeCV) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CV / Hồ sơ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _navigateToCVBuilder,
              icon: const Icon(
                Icons.auto_awesome,
                color: AppTheme.themePurpleStart,
              ),
              label: const Text(
                'Quản lý CV',
                style: TextStyle(color: AppTheme.themePurpleStart),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          onTap: _navigateToCVBuilder,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: activeCV != null
                      ? AppTheme.purpleGradient
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activeCV != null
                      ? Icons.description
                      : Icons.description_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeCV != null
                          ? (activeCV.templateName ?? 'CV của tôi')
                          : 'Chưa có CV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeCV != null
                          ? 'CV đang hoạt động'
                          : 'Tạo CV bằng AI để nộp việc',
                      style: TextStyle(
                        fontSize: 13,
                        color: activeCV != null
                            ? AppTheme.themeGreenStart
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(List<ReviewDto> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildReviewCard(reviews[index]);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewDto review) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.reviewerAvatarUrl != null
                    ? NetworkImage(review.reviewerAvatarUrl!)
                    : null,
                child: review.reviewerAvatarUrl == null
                    ? Text(
                        review.reviewerName?.isNotEmpty == true
                            ? review.reviewerName![0].toUpperCase()
                            : 'U',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (review.rating ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoProfileView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.themePurpleStart.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_box_outlined,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có Portfolio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo portfolio để giới thiệu bản thân,\ndự án và kỹ năng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.themePurpleStart.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToCreateProfile,
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Tạo Portfolio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (!provider.hasExtendedProfile) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () => _showQuickActionMenu(context),
          backgroundColor: AppTheme.themePurpleStart,
          child: const Icon(Icons.add),
        );
      },
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppTheme.darkCardBackground
          : AppTheme.lightCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work, color: Colors.white),
              ),
              title: Text(
                'Thêm dự án',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddProject();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.card_membership, color: Colors.white),
              ),
              title: Text(
                'Thêm chứng chỉ',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddCertificate();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              title: Text(
                'Quản lý CV',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToCVBuilder();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Verified Skills ─────────────────────────────────────────────────────

  Widget _buildVerifiedSkillsSection(
    BuildContext context,
    List<UserVerifiedSkillDto> skills,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: SectionHeader(
                title: 'Kỹ năng đã xác minh',
                icon: Icons.verified_outlined,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                context.push('/student/skill-verifications');
              },
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.themeGreenStart,
                size: 18,
              ),
              label: const Text(
                'Xác thực',
                style: TextStyle(color: AppTheme.themeGreenStart, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 40,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có kỹ năng nào được xác minh',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hoàn thành Journey hoặc gửi yêu cầu xác thực kỹ năng để bắt đầu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ...skills.map(
          (skill) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              onTap: () => _showVerifiedSkillDetail(context, skill),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.skillName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                        ),
                        if (skill.verifiedByMentorName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Xác minh bởi ${skill.verifiedByMentorName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                        if (skill.verifiedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateTimeHelper.formatRelativeTime(
                              skill.verifiedAt!,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: 'COMPLETED_VERIFIED'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBackgroundSecondary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill.sourceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showVerifiedSkillDetail(
    BuildContext context,
    UserVerifiedSkillDto skill,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? AppTheme.darkCardBackground
          : AppTheme.lightCardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title with verified icon
              Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: AppTheme.themeGreenStart,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chứng nhận Kỹ năng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Skill name
              Text(
                skill.skillName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.themeBlueStart,
                ),
              ),
              const SizedBox(height: 16),
              // Verified by
              _buildDetailRow(
                isDark,
                'Được xác thực bởi',
                skill.verifiedByMentorName ?? 'Hệ thống Admin',
                valueColor: AppTheme.themeBlueStart,
              ),
              const SizedBox(height: 10),
              // Date
              if (skill.verifiedAt != null)
                _buildDetailRow(
                  isDark,
                  'Thời gian xác thực',
                  DateTimeHelper.formatDate(skill.verifiedAt!),
                ),
              if (skill.verifiedAt != null) const SizedBox(height: 10),
              // Verification note
              if (skill.verificationNote != null &&
                  skill.verificationNote!.isNotEmpty) ...[
                Text(
                  'Đánh giá chi tiết:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"${skill.verificationNote}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Source badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: skill.journeyId != null
                      ? AppTheme.themeBlueStart.withValues(alpha: 0.15)
                      : AppTheme.themeGreenStart.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      skill.journeyId != null
                          ? Icons.map_outlined
                          : Icons.verified_user_outlined,
                      size: 16,
                      color: skill.journeyId != null
                          ? AppTheme.themeBlueStart
                          : AppTheme.themeGreenStart,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      skill.journeyId != null
                          ? 'Xác thực qua lộ trình (Roadmap Mentoring)'
                          : skill.sourceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: skill.journeyId != null
                            ? AppTheme.themeBlueStart
                            : AppTheme.themeGreenStart,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color:
                  valueColor ??
                  (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
