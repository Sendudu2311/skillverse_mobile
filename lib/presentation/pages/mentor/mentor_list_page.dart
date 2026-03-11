import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/mentor_models.dart';
import '../../providers/mentor_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';

class MentorListPage extends StatefulWidget {
  const MentorListPage({super.key});

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
      provider.loadMentors();
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Icon(
              Icons.people_outline,
              color: AppTheme.primaryBlueDark,
              size: 28,
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
              ).createShader(bounds),
              child: const Text(
                'MENTOR NETWORK',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildSearchBar(context, isDark),
            _buildSkillFilter(context, isDark),
            Expanded(child: _buildMentorList(context, isDark)),
          ],
        ),
      ),
    );
  }




  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: _searchController,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm mentor...',
            hintStyle: TextStyle(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<MentorProvider>().searchMentors('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            context.read<MentorProvider>().searchMentors(value);
          },
        ),
      ),
    );
  }

  Widget _buildSkillFilter(BuildContext context, bool isDark) {
    return Consumer<MentorProvider>(
      builder: (context, provider, _) {
        if (provider.availableSkills.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 50,
          margin: const EdgeInsets.only(top: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.availableSkills.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedSkill == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSkill = null);
                      provider.filterBySkill(null);
                    },
                    backgroundColor: isDark
                        ? AppTheme.darkCardBackground
                        : AppTheme.lightCardBackground,
                    selectedColor: AppTheme.primaryBlueDark.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (isDark
                                ? AppTheme.primaryBlueDark
                                : AppTheme.primaryBlue)
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }

              final skill = provider.availableSkills[index - 1];
              final isSelected = _selectedSkill == skill;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(skill),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedSkill = isSelected ? null : skill);
                    provider.filterBySkill(isSelected ? null : skill);
                  },
                  backgroundColor: isDark
                      ? AppTheme.darkCardBackground
                      : AppTheme.lightCardBackground,
                  selectedColor: AppTheme.primaryBlueDark.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isDark
                              ? AppTheme.primaryBlueDark
                              : AppTheme.primaryBlue)
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMentorList(BuildContext context, bool isDark) {
    return Consumer<MentorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingMentors) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.mentors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 64,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy mentor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadMentors(refresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.mentors.length,
            itemBuilder: (context, index) {
              final mentor = provider.mentors[index];
              return _buildMentorCard(context, mentor, isDark, provider);
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

    return GestureDetector(
      onTap: () => context.push('/mentors/${mentor.id}'),
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
                      AppTheme.primaryBlueDark.withOpacity(0.15),
                      AppTheme.primaryBlue.withOpacity(0.05),
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
                          backgroundColor: AppTheme.primaryBlueDark.withOpacity(
                            0.3,
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
                        if (mentor.preChatEnabled)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkBackgroundPrimary
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
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
                                  mentor.ratingAverage!.toStringAsFixed(1),
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
                                  AppTheme.primaryBlueDark.withOpacity(0.15),
                                  AppTheme.primaryBlue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryBlueDark.withOpacity(
                                  0.3,
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
                      const SizedBox(height: 16),
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
                            ],
                          ),
                        ),
                        // Chat button
                        if (mentor.preChatEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.successColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: AppTheme.successColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Chat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                color: AppTheme.primaryBlueDark.withOpacity(
                                  0.3,
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
}
