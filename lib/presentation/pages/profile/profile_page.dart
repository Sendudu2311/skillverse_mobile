import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/common_loading.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/premium_provider.dart';
import '../../../data/models/premium_models.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/number_formatter.dart';

import '../../widgets/glass_card.dart';
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
      // Only fetch from API if provider has no cached data yet
      if (context.read<UserProvider>().userProfile == null) {
        context.read<UserProvider>().loadUserProfile();
      }
      if (context.read<PremiumProvider>().currentSubscription == null) {
        context.read<PremiumProvider>().loadCurrentSubscription();
      }
      if (context.read<WalletProvider>().cashBalance == 0 &&
          context.read<WalletProvider>().coinBalance == 0) {
        context.read<WalletProvider>().refresh();
      }
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    // Capture references before any async gap
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

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
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      await UserService().uploadAvatar(filePath, userId);
      if (!mounted) return;

      // Reload profile to get the new avatar URL
      await userProvider.loadUserProfile();
      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
        context,
        'Cập nhật ảnh đại diện thành công!',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
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
    final premiumProvider = context.watch<PremiumProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (userProvider.isLoading || premiumProvider.isLoading) {
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
    final subscription = premiumProvider.currentSubscription;

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
    UserSubscriptionDto? subscription,
    WalletProvider walletProvider,
    bool isDark,
  ) {
    final displayName = userProfile?.fullName ?? user?.fullName ?? 'User';
    final avatarUrl =
        userProfile?.avatarMediaUrl ?? subscription?.userAvatarUrl;

    // Get subscription info
    final planName = subscription?.plan.displayName ?? 'Cadet';
    final planType = subscription?.plan.planType ?? PlanType.freeTier;
    final joinedYear = userProfile?.createdAt != null
        ? 'Since ${DateTime.tryParse(userProfile!.createdAt)?.year ?? '---'}'
        : 'Since ---';
    final cashBalance = walletProvider.cashBalance;
    final coinBalance = walletProvider.coinBalance;
    final statusText = _getStatusText(subscription?.status);

    final tierColor = _getPlanColor(planType);
    final isFree = planType == PlanType.freeTier;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.darkCardBackground, const Color(0xFF0D1117)]
              : [AppTheme.primaryBlueDark, const Color(0xFF3730A3)],
        ),
      ),
      child: Column(
        children: [
          // ── Avatar with tier ring ──────────────────────────
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer colored ring (tier indicator, replaces PNG frame)
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isFree
                        ? Colors.white.withValues(alpha: 0.3)
                        : tierColor,
                    width: 3,
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 100,
                height: 100,
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
                          errorBuilder: (_, __, ___) =>
                              _buildDefaultAvatar(displayName),
                        ),
                      )
                    : _buildDefaultAvatar(displayName),
              ),
              // Camera button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCardBackground
                          : AppTheme.primaryBlueDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: _isUploadingAvatar
                        ? CommonLoading.small()
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Name ──────────────────────────────────────────
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isFree
                  ? [Colors.white, Colors.white70]
                  : [tierColor, Colors.white, tierColor],
              stops: isFree ? null : const [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              displayName.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),

          // ── Single subtitle line ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 12, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                joinedYear,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              if (!isFree) ...[
                const Text('  ·  ', style: TextStyle(color: Colors.white30)),
                Text(
                  planName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tierColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── Stats row ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem2(
                    Icons.account_balance_wallet_outlined,
                    'Ví',
                    '${NumberFormatter.formatCompact(cashBalance.toInt())} đ',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.24),
                ),
                Expanded(
                  child: _buildStatItem2(
                    Icons.monetization_on_outlined,
                    'Xu',
                    NumberFormatter.formatCompact(coinBalance),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.24),
                ),
                Expanded(
                  child: _buildStatItem2(
                    Icons.verified_outlined,
                    'Trạng thái',
                    statusText,
                    valueColor: statusText == 'ACTIVE'
                        ? AppTheme.successColor
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem2(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ==================== SUBSCRIPTION CARD ====================

  String _getPlanIcon(PlanType planType) {
    switch (planType) {
      case PlanType.studentPack:
        return '🎓';
      case PlanType.premiumBasic:
        return '⭐';
      case PlanType.premiumPlus:
        return '💎';
      case PlanType.recruiterPro:
        return '🚀';
      default:
        return '📦';
    }
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    UserSubscriptionDto? subscription,
    bool isDark,
  ) {
    if (subscription != null && (subscription.currentlyActive ?? false)) {
      final planType = subscription.plan.planType;
      final tierColor = _getPlanColor(planType);
      final tierIcon = _getPlanIcon(planType);
      final daysLeft = subscription.daysRemaining ?? 0;
      final totalDays = subscription.plan.durationMonths * 30;
      final progress = totalDays > 0
          ? (1.0 - (daysLeft / totalDays)).clamp(0.0, 1.0)
          : 1.0;
      final features = subscription.plan.features ?? [];

      final secColor = isDark
          ? AppTheme.darkTextSecondary
          : AppTheme.lightTextSecondary;
      final priColor = isDark
          ? AppTheme.darkTextPrimary
          : AppTheme.lightTextPrimary;

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────
                Row(
                  children: [
                    Text(tierIcon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.plan.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                          Text(
                            subscription.plan.description ?? '',
                            style: TextStyle(fontSize: 11, color: secColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '● ACTIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Progress ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      daysLeft <= 7
                          ? '⚠️ Còn $daysLeft ngày'
                          : 'Còn $daysLeft ngày',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: daysLeft <= 7 ? AppTheme.errorColor : priColor,
                      ),
                    ),
                    Text(
                      'HH: ${_formatDate(subscription.endDate)}',
                      style: TextStyle(fontSize: 11, color: secColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: tierColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      daysLeft <= 7 ? AppTheme.errorColor : tierColor,
                    ),
                  ),
                ),

                // ── Features (top 2) ───────────────────────
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...features
                      .take(2)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 13,
                                color: tierColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: priColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],

                // ── Footer ─────────────────────────────────
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      (subscription.autoRenew ?? false)
                          ? Icons.repeat
                          : Icons.event_busy,
                      size: 13,
                      color: secColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (subscription.autoRenew ?? false)
                          ? 'Tự động gia hạn'
                          : 'Không gia hạn',
                      style: TextStyle(fontSize: 11, color: secColor),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.push('/premium'),
                      icon: const Icon(Icons.tune, size: 13),
                      label: const Text(
                        'Quản lý',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: tierColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ],
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
      child: GestureDetector(
        onTap: () => context.push('/premium'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.4),
            ),
            gradient: LinearGradient(
              colors: [
                AppTheme.accentGold.withValues(alpha: isDark ? 0.15 : 0.08),
                AppTheme.themeOrangeStart.withValues(
                  alpha: isDark ? 0.08 : 0.04,
                ),
              ],
            ),
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
            'Tin nhắn',
            Icons.chat_outlined,
            () => context.push('/messaging'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Lịch hẹn của tôi',
            Icons.calendar_today_outlined,
            () => context.push('/my-bookings'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Báo cáo học tập AI',
            Icons.analytics_outlined,
            () => context.push('/profile/learning-report'),
            isDark,
          ),
          _buildMenuItem(
            context,
            'Hợp đồng của tôi',
            Icons.description_outlined,
            () => context.push('/my-contracts'),
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
        backgroundColor: AppTheme.errorColor,
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

  String _getStatusText(SubscriptionStatus? status) {
    if (status == null) return 'ACTIVE';
    switch (status) {
      case SubscriptionStatus.active:
        return 'ACTIVE';
      case SubscriptionStatus.expired:
        return 'EXPIRED';
      case SubscriptionStatus.cancelled:
        return 'CANCELLED';
      case SubscriptionStatus.pending:
        return 'PENDING';
      case SubscriptionStatus.suspended:
        return 'SUSPENDED';
    }
  }

  Color _getPlanColor(PlanType planType) {
    switch (planType) {
      case PlanType.premiumPlus:
        return AppTheme.accentCyan;
      case PlanType.premiumBasic:
        return AppTheme.accentGold;
      case PlanType.studentPack:
        return AppTheme.themeGreenStart;
      case PlanType.recruiterPro:
        return AppTheme.themeOrangeStart;
      case PlanType.freeTier:
        return Colors.grey;
    }
  }
}
