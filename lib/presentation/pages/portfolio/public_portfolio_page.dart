import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../../data/models/portfolio_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';

class PublicPortfolioPage extends StatefulWidget {
  final String slug;

  const PublicPortfolioPage({super.key, required this.slug});

  @override
  State<PublicPortfolioPage> createState() => _PublicPortfolioPageState();
}

class _PublicPortfolioPageState extends State<PublicPortfolioPage> {
  late bool isDark;
  bool _isLoading = true;
  ExtendedProfileDto? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await context
          .read<PortfolioProvider>()
          .getPortfolioBySlug(widget.slug);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không tìm thấy portfolio';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: '@${widget.slug}',
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
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
          if (_isLoading)
            CommonLoading.center()
          else if (_error != null)
            _buildError()
          else if (_profile != null)
            _buildContent(_profile!),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off,
                size: 64,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Không tìm thấy portfolio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themePurpleStart),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ExtendedProfileDto profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          GradientGlassCard(
            gradientColors: const [
              AppTheme.themePurpleStart,
              AppTheme.themePurpleEnd,
            ],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? NetworkImage(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.displayName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (profile.headline != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.headline!,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (profile.location != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              profile.location!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bio
          if (profile.bio != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới thiệu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white70
                          : AppTheme.lightTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Skills
          if (profile.expertiseAreas != null &&
              profile.expertiseAreas!.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chuyên môn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                                    fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // Links
          if (profile.website != null ||
              profile.githubUrl != null ||
              profile.linkedinUrl != null ||
              profile.behanceUrl != null ||
              profile.dribbbleUrl != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liên kết',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.website != null)
                        _buildLinkChip(Icons.language, 'Website'),
                      if (profile.githubUrl != null)
                        _buildLinkChip(Icons.code, 'GitHub'),
                      if (profile.linkedinUrl != null)
                        _buildLinkChip(Icons.business, 'LinkedIn'),
                      if (profile.behanceUrl != null)
                        _buildLinkChip(Icons.palette, 'Behance'),
                      if (profile.dribbbleUrl != null)
                        _buildLinkChip(Icons.sports_basketball, 'Dribbble'),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLinkChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.themePurpleStart),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
