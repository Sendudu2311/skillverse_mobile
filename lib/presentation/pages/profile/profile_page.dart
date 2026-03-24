import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUserProfile();
      context.read<SubscriptionProvider>().loadSubscription();
      context.read<WalletProvider>().refresh();
    });
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }

    final filePath = result.files.first.path!;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      await UserService().uploadAvatar(filePath, userId);

      // Reload profile to get the new avatar URL
      if (mounted) {
        await context.read<UserProvider>().loadUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProvider = context.watch<UserProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (userProvider.isLoading || subscriptionProvider.isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 40),
              ProfileHeaderSkeleton(),
              SizedBox(height: 24),
              TextSkeleton(lines: 4),
            ],
          ),
        ),
      );
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
              walletProvider,
              isDark,
            ),
          ),

          // Subscription Card (NEW — kept from rewrite)
          SliverToBoxAdapter(
            child: _buildSubscriptionCard(context, subscription, isDark),
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
    WalletProvider walletProvider,
    bool isDark,
  ) {
    final displayName = userProfile?.fullName ?? user?.fullName ?? 'User';
    final avatarUrl =
        userProfile?.avatarMediaUrl ?? subscription?.userAvatarUrl;

    // Get subscription info
    final planName = subscription?.plan.displayName ?? 'Cadet';
    final planType = subscription?.plan.planType ?? 'FREE_TIER';
    final joinedYear = userProfile?.createdAt != null
        ? 'Since ${DateTime.tryParse(userProfile!.createdAt)?.year ?? '---'}'
        : 'Since ---';
    final cashBalance = walletProvider.cashBalance;
    final coinBalance = walletProvider.coinBalance;
    final status = subscription?.status ?? 'ACTIVE';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.primaryBlueDark,
      ),
      child: Column(
        children: [
          // Avatar with Premium Frame (matching web PilotHeader)
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Avatar (smaller, centered inside Stack)
                Container(
                  width: 112,
                  height: 112,
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
                // Premium frame overlay — wraps around avatar
                if (_getAvatarFrame(planType) != null)
                  Positioned(
                    top: -4,
                    left: -4,
                    right: -4,
                    bottom: -4,
                    child: Image.asset(
                      _getAvatarFrame(planType)!,
                      fit: BoxFit.contain,
                    ),
                  ),
                // Camera button — tap to upload avatar
                Positioned(
                  bottom: 6,
                  right: 10,
                  child: GestureDetector(
                    onTap: _isUploadingAvatar
                        ? null
                        : () => _pickAndUploadAvatar(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingAvatar
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Name with gradient + glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow layer (blurred shadow behind text)
              Text(
                displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  color: Colors.transparent,
                  shadows: [
                    Shadow(
                      color: _getPlanColor(planType).withValues(alpha: 0.8),
                      blurRadius: 30,
                    ),
                    Shadow(
                      color: _getPlanColor(planType).withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              // Gradient text layer
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: planType == 'FREE_TIER'
                      ? [Colors.white, Colors.white70]
                      : [
                          _getPlanColor(planType),
                          Colors.white,
                          _getPlanColor(planType),
                        ],
                  stops: planType == 'FREE_TIER' ? null : const [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(
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
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Level and Plan badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildJoinedBadge(joinedYear),
              const SizedBox(width: 12),
              _buildPlanBadge(planName, planType),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row — real data from wallet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'VÍ',
                  NumberFormatter.formatCompact(cashBalance),
                  isDark,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  'XU',
                  NumberFormatter.formatCompact(coinBalance),
                  isDark,
                ),
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

  // ==================== SUBSCRIPTION CARD (NEW) ====================

  Widget _buildSubscriptionCard(
    BuildContext context,
    dynamic subscription,
    bool isDark,
  ) {
    if (subscription != null && subscription.currentlyActive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GlassCard(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPlanColor(
                    subscription.plan.planType,
                  ).withValues(alpha: 0.12),
                  _getPlanColor(
                    subscription.plan.planType,
                  ).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getPlanColor(
                      subscription.plan.planType,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    color: _getPlanColor(subscription.plan.planType),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.plan.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            subscription.autoRenew
                                ? Icons.repeat
                                : Icons.event_busy,
                            size: 13,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subscription.autoRenew
                                  ? 'Tự động gia hạn · Còn ${subscription.daysRemaining} ngày'
                                  : 'Hết hạn ${_formatDate(subscription.endDate)} · Còn ${subscription.daysRemaining} ngày',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/premium'),
                  child: const Text('Quản lý', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // CTA — no active subscription
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassCard(
        child: InkWell(
          onTap: () => context.push('/premium'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGold.withValues(alpha: 0.12),
                  AppTheme.themeOrangeStart.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.accentGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nâng cấp Premium',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Truy cập không giới hạn khóa học & AI',
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
                const Icon(Icons.chevron_right, color: AppTheme.accentGold),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== OLD UI SECTIONS ====================

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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildJoinedBadge(String text) {
    final color = AppTheme.themeBlueStart;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.35)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_month, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String planName, String planType) {
    final color = _getPlanColor(planType);
    final isFree = planType == 'FREE_TIER';

    // Free tier → keep simple badge
    if (isFree) return _buildBadge(planName, color);

    // Paid plans → gradient + icon + glow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
            ),
          ),
        ],
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
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
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
                    colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
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
                    color: AppTheme.accentCyan,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/profile/edit'),
                color: AppTheme.accentCyan,
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
            'Khóa học của tôi',
            Icons.school_outlined,
            () => context.push('/my-courses'),
            isDark,
          ),
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
          activeTrackColor: AppTheme.primaryBlueDark,
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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Returns the premium frame image asset path for the given plan type.
  /// Matches web's PilotHeader.getAvatarFrame logic.
  String? _getAvatarFrame(String planType) {
    switch (planType) {
      case 'STUDENT_PACK':
        return 'assets/images/premium/silver_avatar.png';
      case 'PREMIUM_BASIC':
        return 'assets/images/premium/golden_avatar.png';
      case 'PREMIUM_PLUS':
        return 'assets/images/premium/diamond_avatar.png';
      default:
        return null;
    }
  }

  Color _getPlanColor(String planType) {
    switch (planType) {
      case 'PREMIUM_PLUS':
        return AppTheme.accentCyan;
      case 'PREMIUM_BASIC':
        return AppTheme.accentGold;
      case 'STUDENT_PACK':
        return AppTheme.themeGreenStart;
      case 'RECRUITER_PRO':
        return AppTheme.themeOrangeStart;
      case 'FREE_TIER':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
