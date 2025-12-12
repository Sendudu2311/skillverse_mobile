import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/portfolio_models.dart';

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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      body: Consumer<PortfolioProvider>(
        builder: (context, portfolioProvider, child) {
          if (portfolioProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (portfolioProvider.errorMessage != null) {
            return _buildErrorView(portfolioProvider.errorMessage!);
          }

          if (!portfolioProvider.hasExtendedProfile) {
            return _buildNoProfileView(context);
          }

          return RefreshIndicator(
            onRefresh: _loadPortfolio,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info
                  _buildHeader(context, user, portfolioProvider.extendedProfile),

                  const SizedBox(height: 24),

                  // Extended Profile Section
                  if (portfolioProvider.extendedProfile != null)
                    _buildExtendedProfileSection(context, portfolioProvider.extendedProfile!),

                  const SizedBox(height: 24),

                  // Quick Stats
                  _buildQuickStats(
                    portfolioProvider.projects.length,
                    portfolioProvider.certificates.length,
                    portfolioProvider.reviews.length,
                  ),

                  const SizedBox(height: 24),

                  // Active CV Section
                  if (portfolioProvider.activeCV != null)
                    _buildActiveCVSection(context, portfolioProvider.activeCV!),

                  const SizedBox(height: 24),

                  // Projects Section
                  _buildProjectsSection(context, portfolioProvider.projects),

                  const SizedBox(height: 24),

                  // Certificates Section
                  _buildCertificatesSection(context, portfolioProvider.certificates),

                  const SizedBox(height: 24),

                  // Reviews Section
                  if (portfolioProvider.reviews.isNotEmpty)
                    _buildReviewsSection(portfolioProvider.reviews),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, ExtendedProfileDto? profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text(
              user?.fullName?.isNotEmpty == true
                  ? user!.fullName![0].toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
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
                const SizedBox(height: 4),
                if (profile?.headline != null)
                  Text(
                    profile!.headline!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                if (profile?.slug != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedProfileSection(BuildContext context, ExtendedProfileDto profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Về tôi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (profile.bio != null)
              Text(
                profile.bio!,
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 16),

            // Location
            if (profile.location != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(profile.location!),
                ],
              ),

            const SizedBox(height: 12),

            // Social Links
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

            // Expertise Areas
            if (profile.expertiseAreas != null && profile.expertiseAreas!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Chuyên môn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.expertiseAreas!
                    .map((area) => Chip(
                          label: Text(area),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildQuickStats(int projects, int certificates, int reviews) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Dự án', projects.toString(), Icons.work, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Chứng chỉ', certificates.toString(), Icons.card_membership, Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Đánh giá', reviews.toString(), Icons.star, Colors.amber),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCVSection(BuildContext context, CVDto cv) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CV đang hoạt động',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cv.templateName ?? 'CV của tôi',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Navigate to CV detail
              },
            ),
          ],
        ),
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
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to add project
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _buildEmptyState('Chưa có dự án nào', Icons.work_outline)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectCard(project);
            },
          ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectDto project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to project detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work, size: 32),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.technologies != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            project.technologies!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (project.isFeatured == true)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              if (project.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  project.description!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificatesSection(BuildContext context, List<CertificateDto> certificates) {
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
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to add certificate
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (certificates.isEmpty)
          _buildEmptyState('Chưa có chứng chỉ nào', Icons.card_membership_outlined)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certificates.length,
            itemBuilder: (context, index) {
              final cert = certificates[index];
              return _buildCertificateCard(cert);
            },
          ),
      ],
    );
  }

  Widget _buildCertificateCard(CertificateDto certificate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.card_membership, color: Colors.orange.shade700, size: 28),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    certificate.issuer ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (certificate.issueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      certificate.issueDate!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(review);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewDto review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < (review.rating ?? 0) ? Icons.star : Icons.star_border,
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
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
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
            Icon(
              Icons.account_box_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa có Portfolio',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo portfolio để giới thiệu bản thân, dự án và kỹ năng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to create profile
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo Portfolio'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPortfolio,
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
          onPressed: () {
            _showQuickActionMenu(context);
          },
          child: const Icon(Icons.add),
        );
      },
    );
  }

  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Thêm dự án'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add project
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Thêm chứng chỉ'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to add certificate
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Tạo CV'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to generate CV
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
