import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mentor_eligibility_models.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/selectable_chip_row.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/animated_list_item.dart';
import '../../../core/utils/number_formatter.dart';

class MentorListPage extends StatefulWidget {
  final String? action;
  final int? journeyId;
  final int? roadmapSessionId;
  final String? skillName;
  final String? nodeId;

  const MentorListPage({
    super.key,
    this.action,
    this.journeyId,
    this.roadmapSessionId,
    this.skillName,
    this.nodeId,
  });

  @override
  State<MentorListPage> createState() => _MentorListPageState();
}

class _MentorListPageState extends State<MentorListPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSkill;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MentorProvider>();
      if (widget.skillName != null) {
        provider.setContextSkill(widget.skillName!);
      }
      if (widget.action == 'roadmap_mentoring') {
        provider.loadRoadmapMentors(
          journeyId: widget.journeyId,
          roadmapSessionId: widget.roadmapSessionId,
          skillName: widget.skillName,
          nodeId: widget.nodeId,
        );
      } else {
        provider.loadMentors();
      }
      provider.loadAvailableSkills();
      provider.loadFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRoadmapContext = widget.action == 'roadmap_mentoring';

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'MENTOR NETWORK',
        icon: Icons.people_outline,
        useGradientTitle: true,
        onBack: () => context.go('/dashboard'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // V3: Contextual banner when navigating from Roadmap
            if (isRoadmapContext)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.primaryBlueDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.skillName != null
                            ? 'Ưu tiên mentor đã xác thực skill "${widget.skillName}" cho Roadmap của bạn.'
                            : 'Chọn mentor để đồng hành cùng Roadmap của bạn.',
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
            AppSearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm mentor...',
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onChanged: (v) => context.read<MentorProvider>().searchMentors(v),
              onClear: () => context.read<MentorProvider>().searchMentors(''),
            ),
            Consumer<MentorProvider>(
              builder: (context, provider, _) {
                if (provider.availableSkills.isEmpty) {
                  return const SizedBox.shrink();
                }
                final labels = ['Tất cả', ...provider.availableSkills];
                final selectedIndex = _selectedSkill == null
                    ? 0
                    : provider.availableSkills.indexOf(_selectedSkill!) + 1;

                final isActive = provider.showVerifiedOnly;
                final isEnriching = provider.isEnrichingVerifiedSkills;

                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20),
                  child: Row(
                    children: [
                      // Verified skills toggle
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: isEnriching
                            ? null
                            : () => provider.toggleVerifiedFilter(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.successColor.withValues(alpha: 0.4)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : AppTheme.lightBorderColor),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 16,
                                color: isActive
                                    ? AppTheme.successColor
                                    : (isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'Đã xác thực',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                              if (isEnriching) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 1,
                          height: 24,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),

                      Expanded(
                        child: SelectableChipRow(
                          labels: labels,
                          padding: const EdgeInsets.only(right: 20),
                          selectedIndex: selectedIndex.clamp(
                            0,
                            labels.length - 1,
                          ),
                          onSelected: (i) {
                            final skill = i == 0
                                ? null
                                : provider.availableSkills[i - 1];
                            setState(() => _selectedSkill = skill);
                            provider.filterBySkill(skill);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(child: _buildMentorList(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorList(BuildContext context, bool isDark) {
    return Consumer<MentorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingMentors || provider.isLoadingEligibility) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, __) => const MentorCardSkeleton(),
          );
        }

        if (provider.mentors.isEmpty) {
          if (widget.action == 'roadmap_mentoring') {
            return EmptyStateWidget(
              icon: Icons.person_search,
              title: 'Chưa có mentor phù hợp',
              subtitle:
                  'Không tìm thấy mentor đủ điều kiện cho roadmap này lúc này.',
              ctaLabel: 'Tải lại',
              onCtaPressed: () => provider.loadRoadmapMentors(
                journeyId: widget.journeyId,
                roadmapSessionId: widget.roadmapSessionId,
                skillName: widget.skillName,
                nodeId: widget.nodeId,
                refresh: true,
              ),
              iconGradient: AppTheme.blueGradient,
            );
          }
          // Special empty state when verified filter is active
          if (provider.showVerifiedOnly &&
              !provider.isEnrichingVerifiedSkills) {
            return EmptyStateWidget(
              icon: Icons.verified_user_outlined,
              title: 'Chưa có mentor đã xác thực',
              subtitle:
                  'Không tìm thấy mentor nào đã verified skills. Tắt bộ lọc để xem tất cả.',
              ctaLabel: 'Tắt bộ lọc xác thực',
              onCtaPressed: () => provider.toggleVerifiedFilter(),
              iconGradient: const LinearGradient(
                colors: [AppTheme.successColor, AppTheme.infoColor],
              ),
            );
          }
          return EmptyStateWidget(
            icon: Icons.person_search,
            title: 'Không tìm thấy mentor',
            subtitle: 'Thử tìm kiếm với từ khóa khác',
            ctaLabel: 'Tải lại',
            onCtaPressed: () => provider.loadMentors(refresh: true),
            iconGradient: AppTheme.blueGradient,
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.action == 'roadmap_mentoring'
              ? provider.loadRoadmapMentors(
                  journeyId: widget.journeyId,
                  roadmapSessionId: widget.roadmapSessionId,
                  skillName: widget.skillName,
                  nodeId: widget.nodeId,
                  refresh: true,
                )
              : provider.loadMentors(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.mentors.length,
            itemBuilder: (context, index) {
              final mentor = provider.mentors[index];
              return AnimatedListItem(
                index: index,
                child: _buildMentorCard(context, mentor, isDark, provider),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMentorCard(
    BuildContext context,
    MentorProfile mentor,
    bool isDark,
    MentorProvider provider,
  ) {
    final isFavorite = provider.isMentorFavorite(mentor.id);
    final eligibility = provider.eligibilityFor(mentor.id);

    return GestureDetector(
      onTap: () {
        final params = <String, String>{};
        if (widget.action != null) params['action'] = widget.action!;
        if (widget.journeyId != null) {
          params['journeyId'] = '${widget.journeyId}';
        }
        if (widget.roadmapSessionId != null) {
          params['roadmapSessionId'] = '${widget.roadmapSessionId}';
        }
        if (widget.nodeId != null) params['nodeId'] = widget.nodeId!;
        final uri = Uri(
          path: '/mentors/${mentor.id}',
          queryParameters: params.isNotEmpty ? params : null,
        );
        context.push(uri.toString());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlueDark.withValues(alpha: 0.15),
                      AppTheme.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar with status indicator
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primaryBlueDark.withValues(
                            alpha: 0.3,
                          ),
                          backgroundImage: mentor.avatar != null
                              ? NetworkImage(mentor.avatar!)
                              : null,
                          child: mentor.avatar == null
                              ? Text(
                                  mentor.fullName.isNotEmpty
                                      ? mentor.fullName[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlueDark,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Name and specialization
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentor.displayName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (mentor.specialization != null)
                            Text(
                              mentor.specialization!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          // Rating and experience row
                          Row(
                            children: [
                              if (mentor.ratingAverage != null) ...[
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppTheme.warningColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  NumberFormatter.formatRating(
                                    mentor.ratingAverage!,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.darkTextPrimary
                                        : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                Text(
                                  ' (${mentor.ratingCount ?? 0})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (mentor.experience != null) ...[
                                Icon(
                                  Icons.work_outline,
                                  size: 14,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${mentor.experience} năm',
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
                        ],
                      ),
                    ),
                    // Favorite button
                    IconButton(
                      onPressed: () => provider.toggleFavorite(mentor.id),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Colors.redAccent
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Body - Skills and info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skills
                    if (mentor.skills != null && mentor.skills!.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: mentor.skills!.take(4).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryBlueDark.withValues(
                                    alpha: 0.15,
                                  ),
                                  AppTheme.primaryBlue.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBlueDark.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.primaryBlueDark
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Roadmap mentoring badge
                    if (mentor.canOfferRoadmapMentoring) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_outlined,
                              size: 14,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hỗ trợ đồng hành Roadmap',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (eligibility != null) ...[
                      _buildEligibilityBlock(eligibility, isDark),
                      const SizedBox(height: 12),
                    ],

                    // Verified skills chips
                    if (provider.isEnrichingVerifiedSkills &&
                        mentor.verifiedSkills == null) ...[
                      // Skeleton chips while enriching
                      Row(
                        children: List.generate(
                          2,
                          (_) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 70,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (mentor.hasVerifiedSkills) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...mentor.verifiedSkills!.take(3).map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppTheme.successColor.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 12,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    skill,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (mentor.verifiedSkills!.length > 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${mentor.verifiedSkills!.length - 3}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Price and action buttons
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giá mỗi giờ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mentor.formattedHourlyRate,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              if (mentor.canOfferRoadmapMentoring) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Đồng hành: ${mentor.formattedEffectiveRoadmapMentoringPrice}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Chat button
                        const SizedBox(width: 8),
                        // View profile button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryBlueDark,
                                AppTheme.primaryBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlueDark.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityBlock(
    MentorTeachingEligibilityResponse eligibility,
    bool isDark,
  ) {
    final color = switch (eligibility.summaryStatus) {
      TeachingEligibilityStatus.eligible => AppTheme.successColor,
      TeachingEligibilityStatus.partiallyEligible => AppTheme.primaryBlue,
      TeachingEligibilityStatus.needsReview => AppTheme.warningColor,
      TeachingEligibilityStatus.notEligible => AppTheme.errorColor,
    };
    final topNode = eligibility.nodes.isNotEmpty
        ? eligibility.nodes.first
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                '${eligibility.summaryStatus.displayLabel} (${eligibility.overallMatchPercent}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (topNode != null) ...[
            const SizedBox(height: 6),
            Text(
              'Dạy tốt nhất: ${topNode.title ?? topNode.nodeId ?? 'Node'} (${topNode.matchPercent}%)',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            if (topNode.missingSkillsText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Thiếu skill phụ: ${topNode.missingSkillsText}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
