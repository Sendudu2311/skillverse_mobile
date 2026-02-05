import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
      context.read<SubscriptionProvider>().loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (userProvider.isLoading || subscriptionProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.user;
    final userProfile = userProvider.userProfile;
    final subscription = subscriptionProvider.subscription;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header with Avatar
          SliverToBoxAdapter(
            child: _buildProfileHeader(
              context,
              user,
              userProfile,
              subscription,
              isDark,
            ),
          ),

          // Personal Info Section
          SliverToBoxAdapter(
            child: _buildPersonalInfoSection(context, userProfile, isDark),
          ),

          // Menu Items
          SliverToBoxAdapter(child: _buildMenuSection(context, isDark)),

          // Logout Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildLogoutButton(context, authProvider, isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic user,
    dynamic userProfile,
    dynamic subscription,
    bool isDark,
  ) {
    final displayName = userProfile?.fullName ?? user?.fullName ?? 'User';
    final avatarUrl = subscription?.userAvatarUrl;

    // Get subscription info
    final planName = subscription?.plan.displayName ?? 'Cadet';
    final planType = subscription?.plan.planType ?? 'FREE';
    final level = 0; // TODO: Get from user stats
    final xp = 0; // TODO: Get from user stats
    final credits = 0; // TODO: Get from wallet
    final status = subscription?.status ?? 'ACTIVE';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.primaryBlueDark,
      ),
      child: Column(
        children: [
          // Avatar with Premium Ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Premium ring
              if (subscription != null)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getPremiumRingColor(planType),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getPremiumRingColor(
                          planType,
                        ).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.themePurpleStart,
                      AppTheme.themePurpleEnd,
                    ],
                  ),
                ),
                child: avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(displayName),
                        ),
                      )
                    : _buildDefaultAvatar(displayName),
              ),
              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            displayName.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Level and Plan badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge('Level $level', AppTheme.themeBlueStart),
              const SizedBox(width: 12),
              _buildBadge(planName, _getPlanColor(planType)),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('CREDITS', credits.toString(), isDark),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem('XP', xp.toString(), isDark),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem('STATUS', status, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(
    BuildContext context,
    dynamic userProfile,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlueDark, Color(0xFF00D4FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'THÔNG TIN CÁ NHÂN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00D4FF),
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/profile/edit'),
                color: const Color(0xFF00D4FF),
                tooltip: 'Chỉnh sửa',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            'HỌ VÀ TÊN',
            userProfile?.fullName ?? 'N/A',
            Icons.person_outline,
            isDark,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'LIÊN LẠC',
            userProfile?.phone ?? 'N/A',
            Icons.phone_outlined,
            isDark,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'ĐỊA CHỈ',
            userProfile?.address ?? 'N/A',
            Icons.location_on_outlined,
            isDark,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'EMAIL',
            userProfile?.email ?? 'N/A',
            Icons.email_outlined,
            isDark,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'GIỚI THIỆU / NHẬT KÝ',
            userProfile?.bio ?? 'N/A',
            Icons.description_outlined,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlueDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            'Cài đặt tài khoản',
            Icons.settings_outlined,
            () => context.push('/profile/settings'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Gói Premium',
            Icons.workspace_premium_outlined,
            () => context.push('/premium'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Lịch sử thanh toán',
            Icons.receipt_long_outlined,
            () => context.push('/payment-history'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Trung tâm trợ giúp',
            Icons.help_outline,
            () => context.push('/help'),
            isDark,
          ),
          _buildMenuItemWithSwitch(
            context,
            'Chế độ tối',
            Icons.dark_mode_outlined,
            context.watch<ThemeProvider>().isDarkMode,
            (value) => context.read<ThemeProvider>().toggleTheme(),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlueDark),
        title: Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuItemWithSwitch(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlueDark),
        title: Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryBlueDark,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AuthProvider authProvider,
    bool isDark,
  ) {
    return ElevatedButton(
      onPressed: () => _showLogoutDialog(context, authProvider),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.logout),
          SizedBox(width: 8),
          Text(
            'ĐĂNG XUẤT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getPremiumRingColor(String planType) {
    switch (planType) {
      case 'PREMIUM_PLUS':
        return const Color(0xFF00D4FF); // Diamond
      case 'PREMIUM':
        return const Color(0xFFFFD700); // Gold
      case 'BASIC':
        return const Color(0xFFC0C0C0); // Silver
      default:
        return Colors.grey;
    }
  }

  Color _getPlanColor(String planType) {
    switch (planType) {
      case 'PREMIUM_PLUS':
        return const Color(0xFF00D4FF);
      case 'PREMIUM':
        return const Color(0xFFFFD700);
      case 'BASIC':
        return AppTheme.themeGreenStart;
      default:
        return Colors.grey;
    }
  }
}
