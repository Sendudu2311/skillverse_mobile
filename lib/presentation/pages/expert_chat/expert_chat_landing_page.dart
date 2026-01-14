import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/expert_chat_provider.dart';
import '../../themes/app_theme.dart';

/// Expert Chat Landing Page
/// Main entry point with stats and mode selection
class ExpertChatLandingPage extends StatefulWidget {
  const ExpertChatLandingPage({super.key});

  @override
  State<ExpertChatLandingPage> createState() => _ExpertChatLandingPageState();
}

class _ExpertChatLandingPageState extends State<ExpertChatLandingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpertChatProvider>().loadExpertFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.primaryBlueDark, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryBlueDark, Color(0xFF00D4FF)],
              ).createShader(bounds),
              child: const Text(
                'HỆ THỐNG CHUYÊN GIA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with subtitle
            Text(
              'Luôn cập nhật • Phục vụ 24/7 • Chuyên môn đa dạng',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Stats Row
            _buildStatsRow(context),
            const SizedBox(height: 16),

            // Features Row
            _buildFeaturesRow(context),
            const SizedBox(height: 32),

            // Mode Selection Cards
            _buildModeCard(
              context,
              icon: Icons.work_outline,
              title: 'TƯ VẤN NGHỀ NGHIỆP',
              subtitle: 'GENERAL CAREER ADVISOR',
              features: [
                'Tư vấn nghề nghiệp tổng quát',
                'Xu hướng thị trường lao động',
                'Lộ trình phát triển kỹ năng',
                'Định hướng học tập',
              ],
              buttonText: 'BẮT ĐẦU',
              onTap: () => context.push('/chat'),
              color: AppTheme.primaryBlueDark,
            ),
            const SizedBox(height: 16),

            _buildModeCard(
              context,
              icon: Icons.auto_awesome,
              title: 'CHAT VỚI CHUYÊN GIA',
              subtitle: 'EXPERT MODE',
              features: [
                'Tư vấn chuyên sâu theo lĩnh vực',
                'Chuyên gia theo ngành nghề',
                'Kiến thức chuyên môn chi tiết',
                'Lộ trình cụ thể cho từng vai trò',
              ],
              buttonText: 'CHỌN CHUYÊN GIA',
              onTap: () => context.push('/expert-chat/domains'),
              color: const Color(0xFF00D4FF),
              isPremium: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<ExpertChatProvider>(
      builder: (context, provider, _) {
        final totalExperts = provider.expertFields.fold<int>(
          0,
          (sum, field) => sum + field.totalRoles,
        );
        final totalDomains = provider.expertFields.length;
        final totalIndustries = provider.expertFields.fold<int>(
          0,
          (sum, field) => sum + field.industries.length,
        );

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.groups,
                value: totalExperts > 0 ? '$totalExperts+' : '300+',
                label: 'CHUYÊN GIA',
                color: AppTheme.primaryBlueDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.category,
                value: totalDomains > 0 ? '$totalDomains' : '13',
                label: 'LĨNH VỰC',
                color: const Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.business,
                value: totalIndustries > 0 ? '$totalIndustries+' : '45+',
                label: 'NGÀNH NGHỀ',
                color: AppTheme.themeOrangeStart,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesRow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final features = [
      (Icons.bolt, 'Cập nhật liên tục'),
      (Icons.adjust, 'Chuyên môn sâu'),
      (Icons.public, 'Phù hợp Việt Nam'),
      (Icons.flash_on, 'Phản hồi tức thì'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features.map((f) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, size: 14, color: AppTheme.primaryBlueDark),
              const SizedBox(width: 6),
              Text(
                f.$2,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> features,
    required String buttonText,
    required VoidCallback onTap,
    required Color color,
    bool isPremium = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Features
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
