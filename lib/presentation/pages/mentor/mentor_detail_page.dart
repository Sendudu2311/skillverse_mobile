import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/error_state_widget.dart';
import 'mentor_chat_dialog.dart';
import 'mentor_booking_sheet.dart';

class MentorDetailPage extends StatefulWidget {
  final int mentorId;

  const MentorDetailPage({super.key, required this.mentorId});

  @override
  State<MentorDetailPage> createState() => _MentorDetailPageState();
}

class _MentorDetailPageState extends State<MentorDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MentorProvider>();
      provider.loadMentorDetail(widget.mentorId);
      provider.loadAvailability(widget.mentorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<MentorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingDetail) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ProfileHeaderSkeleton(),
                  SizedBox(height: 16),
                  TextSkeleton(lines: 4),
                  SizedBox(height: 16),
                  TextSkeleton(lines: 3),
                ],
              ),
            );
          }

          final mentor = provider.selectedMentor;
          if (mentor == null) {
            return ErrorStateWidget(
              message: 'Không tìm thấy thông tin mentor',
              onRetry: () => provider.loadMentorDetail(widget.mentorId),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, mentor, isDark, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(context, mentor, isDark),
                      const SizedBox(height: 20),
                      _buildBioSection(context, mentor, isDark),
                      const SizedBox(height: 20),
                      _buildSkillsSection(context, mentor, isDark),
                      const SizedBox(height: 20),
                      _buildPricingSection(context, mentor, isDark),
                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<MentorProvider>(
        builder: (context, provider, _) {
          final mentor = provider.selectedMentor;
          if (mentor == null) return const SizedBox.shrink();
          return _buildBottomActions(context, mentor, isDark, provider);
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
    MentorProvider provider,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: isDark
          ? AppTheme.darkCardBackground
          : AppTheme.lightCardBackground,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => provider.toggleFavorite(mentor.id),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              provider.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: provider.isFavorite ? Colors.redAccent : Colors.white,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          AppTheme.indigoDark,
                          const Color(0xFF312E81),
                          AppTheme.darkBackgroundPrimary,
                        ]
                      : [
                          const Color(0xFFE0E7FF),
                          AppTheme.lightBackgroundPrimary,
                        ],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
                    backgroundImage: mentor.avatar != null
                        ? NetworkImage(mentor.avatar!)
                        : null,
                    child: mentor.avatar == null
                        ? Text(
                            mentor.fullName.isNotEmpty
                                ? mentor.fullName[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlueDark,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    mentor.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // Specialization
                  if (mentor.specialization != null)
                    Text(
                      mentor.specialization!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  // Online status
                  if (mentor.preChatEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Trực tuyến',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.star,
            label: 'Đánh giá',
            value: mentor.ratingAverage?.toStringAsFixed(1) ?? '0.0',
            subValue: '(${mentor.ratingCount ?? 0})',
            iconColor: AppTheme.warningColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.work_outline,
            label: 'Kinh nghiệm',
            value: '${mentor.experience ?? 0}',
            subValue: 'năm',
            iconColor: AppTheme.infoColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.emoji_events_outlined,
            label: 'Level',
            value: '${mentor.currentLevel ?? 1}',
            subValue: 'SP: ${mentor.skillPoints ?? 0}',
            iconColor: AppTheme.themePurpleStart,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
    required Color iconColor,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
  ) {
    if (mentor.bio == null || mentor.bio!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới thiệu',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            mentor.bio!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
  ) {
    if (mentor.skills == null || mentor.skills!.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kỹ năng',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mentor.skills!.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlueDark.withOpacity(0.2),
                    AppTheme.themePurpleStart.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryBlueDark.withOpacity(0.3),
                ),
              ),
              child: Text(
                skill,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingSection(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đơn giá',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phí tư vấn 1:1',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mentor.formattedHourlyRate,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.access_time,
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

  Widget _buildBottomActions(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
    MentorProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat button
            if (mentor.preChatEnabled)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChatDialog(context, mentor),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat trước'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.primaryBlueDark
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            if (mentor.preChatEnabled) const SizedBox(width: 12),
            // Book button
            Expanded(
              flex: mentor.preChatEnabled ? 1 : 2,
              child: ElevatedButton.icon(
                onPressed: () => _openBookingSheet(context, mentor, provider),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Đặt lịch'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isDark
                      ? AppTheme.primaryBlueDark
                      : AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatDialog(BuildContext context, MentorProfile mentor) {
    showDialog(
      context: context,
      builder: (context) => MentorChatDialog(mentor: mentor),
    );
  }

  void _openBookingSheet(
    BuildContext context,
    MentorProfile mentor,
    MentorProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MentorBookingSheet(
        mentor: mentor,
        availability: provider.availability,
      ),
    );
  }
}
