import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/group_chat_models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../themes/app_theme.dart';

/// Page showing the list of groups the current user belongs to.
class CommunityGroupsPage extends StatefulWidget {
  const CommunityGroupsPage({super.key});

  @override
  State<CommunityGroupsPage> createState() => _CommunityGroupsPageState();
}

class _CommunityGroupsPageState extends State<CommunityGroupsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndLoad();
    });
  }

  void _initAndLoad() {
    final auth = context.read<AuthProvider>();
    final provider = context.read<GroupChatProvider>();
    if (auth.user != null) {
      provider.setCurrentUser(
        userId: auth.user!.id,
        userName: auth.user!.fullName ?? auth.user!.email,
      );
      provider.loadMyGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm Chat'),
        centerTitle: true,
      ),
      body: Consumer<GroupChatProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingGroups) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => const CardSkeleton(),
            );
          }

          if (provider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa tham gia nhóm nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tham gia một khóa học để vào nhóm chat',
                    style: TextStyle(
                      fontSize: 13,
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
            onRefresh: () => provider.loadMyGroups(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];
                return _GroupCard(group: group);
              },
            ),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupChatResponse group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/group-chat/${group.id}'),
      child: Row(
        children: [
          // Group avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryBlueDark.withOpacity(0.2),
            backgroundImage:
                group.avatarUrl != null ? NetworkImage(group.avatarUrl!) : null,
            child: group.avatarUrl == null
                ? const Icon(
                    Icons.groups,
                    color: AppTheme.primaryBlueDark,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.memberCount} thành viên',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    if (group.mentorName != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '• Mentor: ${group.mentorName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlueDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Arrow indicator
          Icon(
            Icons.chevron_right,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ],
      ),
    );
  }
}
