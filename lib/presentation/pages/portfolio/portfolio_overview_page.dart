import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/portfolio_models.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import 'edit_extended_profile_page.dart';
import 'edit_project_page.dart';
import 'add_certificate_page.dart';

class PortfolioOverviewPage extends StatefulWidget {
  const PortfolioOverviewPage({super.key});

  @override
  State<PortfolioOverviewPage> createState() => _PortfolioOverviewPageState();
}

class _PortfolioOverviewPageState extends State<PortfolioOverviewPage> {
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
      await Future.wait([
        portfolioProvider.loadMyPortfolio(),
        portfolioProvider.loadProjects(),
        portfolioProvider.loadCertificates(),
        portfolioProvider.loadReviews(),
        portfolioProvider.loadActiveCV(),
      ]);
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
        builder: (context) => EditExtendedProfilePage(
          existingProfile: profile,
          isCreate: false,
        ),
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
        builder: (context) => EditProjectPage(
          existingProject: project,
          isCreate: false,
        ),
      ),
    );
    if (result == true && mounted) {
      await context.read<PortfolioProvider>().loadProjects();
    }
  }

  Future<void> _navigateToAddCertificate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCertificatePage(),
      ),
    );
    if (result == true && mounted) {
      await context.read<PortfolioProvider>().loadCertificates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Stack(
        children: [
          // Galaxy Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.galaxyDarkest, AppTheme.galaxyDark],
              ),
            ),
          ),

          // Content
          SafeArea(
              child: Consumer<PortfolioProvider>(
                builder: (context, portfolioProvider, child) {
                  if (portfolioProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.themePurpleStart,
                      ),
                    );
                  }

                  if (portfolioProvider.errorMessage != null) {
                    return _buildErrorView(portfolioProvider.errorMessage!);
                  }

                  if (!portfolioProvider.hasExtendedProfile) {
                    return _buildNoProfileView(context);
                  }

                  return RefreshIndicator(
                    onRefresh: _loadPortfolio,
                    color: AppTheme.themePurpleStart,
                    backgroundColor: AppTheme.darkCardBackground,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with user info
                          _buildHeader(
                              context, user, portfolioProvider.extendedProfile),

                          const SizedBox(height: 24),

                          // Extended Profile Section
                          if (portfolioProvider.extendedProfile != null)
                            _buildExtendedProfileSection(
                                context, portfolioProvider.extendedProfile!),

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
                              context, portfolioProvider.projects),

                          const SizedBox(height: 24),

                          // Certificates Section
                          _buildCertificatesSection(
                              context, portfolioProvider.certificates),

                          const SizedBox(height: 24),

                          // Reviews Section
                          if (portfolioProvider.reviews.isNotEmpty)
                            _buildReviewsSection(portfolioProvider.reviews),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(
      BuildContext context, dynamic user, ExtendedProfileDto? profile) {
    return GradientGlassCard(
      gradientColors: const [
        AppTheme.themePurpleStart,
        AppTheme.themePurpleEnd
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
              child: Text(
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (profile?.slug != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '@${profile!.slug}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              if (profile != null) {
                _navigateToEditProfile(profile);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedProfileSection(
      BuildContext context, ExtendedProfileDto profile) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Về tôi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (profile.bio != null)
            Text(
              profile.bio!,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          if (profile.location != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppTheme.themePurpleStart),
                const SizedBox(width: 8),
                Text(
                  profile.location!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],

          // Social Links
          if (profile.website != null ||
              profile.githubUrl != null ||
              profile.linkedinUrl != null ||
              profile.twitterUrl != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.website != null)
                  _buildSocialChip(Icons.language, 'Website'),
                if (profile.githubUrl != null)
                  _buildSocialChip(Icons.code, 'GitHub'),
                if (profile.linkedinUrl != null)
                  _buildSocialChip(Icons.business, 'LinkedIn'),
                if (profile.twitterUrl != null)
                  _buildSocialChip(Icons.chat, 'Twitter'),
              ],
            ),
          ],

          // Expertise Areas
          if (profile.expertiseAreas != null &&
              profile.expertiseAreas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Chuyên môn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.expertiseAreas!
                  .map((area) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
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
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.themePurpleStart),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int projects, int certificates, int reviews) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
              'Dự án', projects.toString(), Icons.work, AppTheme.themeBlueStart),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Chứng chỉ', certificates.toString(),
              Icons.card_membership, AppTheme.themeOrangeStart),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Đánh giá', reviews.toString(), Icons.star,
              Colors.amber),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection(BuildContext context, List<ProjectDto> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dự án',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: _navigateToAddProject,
              icon: const Icon(Icons.add, color: AppTheme.themeBlueStart),
              label: const Text('Thêm',
                  style: TextStyle(color: AppTheme.themeBlueStart)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _buildEmptyState('Chưa có dự án nào', Icons.work_outline)
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
                    color: AppTheme.darkBackgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: AppTheme.darkTextSecondary),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (project.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    project.description!,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
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

  Widget _buildCertificatesSection(
      BuildContext context, List<CertificateDto> certificates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chứng chỉ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: _navigateToAddCertificate,
              icon: const Icon(Icons.add, color: AppTheme.themeOrangeStart),
              label: const Text('Thêm',
                  style: TextStyle(color: AppTheme.themeOrangeStart)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (certificates.isEmpty)
          _buildEmptyState('Chưa có chứng chỉ nào', Icons.card_membership_outlined)
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
            child: const Icon(Icons.card_membership,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  certificate.issuer ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkTextSecondary,
                  ),
                ),
                if (certificate.issueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    certificate.issueDate!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondary,
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

  Widget _buildReviewsSection(List<ReviewDto> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                    ? Text(review.reviewerName?.isNotEmpty == true
                        ? review.reviewerName![0].toUpperCase()
                        : 'U')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return GlassCard(
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: AppTheme.darkTextSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.darkTextSecondary,
              ),
            ),
          ],
        ),
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
            const Text(
              'Chưa có Portfolio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tạo portfolio để giới thiệu bản thân,\ndự án và kỹ năng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.darkTextSecondary,
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

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.darkTextSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPortfolio,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.themePurpleStart,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Thử lại'),
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
      backgroundColor: AppTheme.darkCardBackground,
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
                color: AppTheme.darkTextSecondary,
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
              title: const Text('Thêm dự án',
                  style: TextStyle(color: Colors.white)),
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
              title: const Text('Thêm chứng chỉ',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _navigateToAddCertificate();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
