import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/glass_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.fullName?.isNotEmpty == true 
                              ? user!.fullName![0].toUpperCase()
                              : user?.email[0].toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // User Info
                      Text(
                        user?.fullName ?? 'Học viên SkillVerse',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.roles?.isNotEmpty == true 
                              ? user!.roles!.first
                              : 'USER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Learning Stats
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Khóa học',
                        value: '3',
                        icon: Icons.school,
                        gradientColors: const [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
                        onTap: () => context.go('/courses'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Chứng chỉ',
                        value: '2',
                        icon: Icons.card_membership,
                        gradientColors: const [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
                        onTap: () => context.push('/portfolio'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Điểm',
                        value: '1,250',
                        icon: Icons.star,
                        gradientColors: const [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Premium Banner
                PremiumCard(
                  title: 'Nâng cấp Premium',
                  subtitle: 'Truy cập không giới hạn tất cả khóa học',
                  icon: Icons.workspace_premium,
                  onTap: () {
                    context.push('/premium');
                  },
                ),

                const SizedBox(height: 24),

                // Menu Items
                _buildMenuItem(
                  context,
                  'Khóa học của tôi',
                  Icons.school_outlined,
                  () {
                    context.go('/courses');
                  },
                ),

                _buildMenuItem(
                  context,
                  'Portfolio & Chứng chỉ',
                  Icons.work_history_outlined,
                  () {
                    context.push('/portfolio');
                  },
                ),

                _buildMenuItem(
                  context,
                  'Lịch sử thanh toán',
                  Icons.payment_outlined,
                  () {
                    context.push('/profile/payments');
                  },
                ),

                _buildMenuItem(
                  context,
                  'Cài đặt',
                  Icons.settings_outlined,
                  () {
                    context.push('/profile/settings');
                  },
                ),

                // Dark Mode Toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildMenuItemWithSwitch(
                      context,
                      'Chế độ tối',
                      Icons.dark_mode_outlined,
                      themeProvider.isDarkMode,
                      (value) {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  'Hỗ trợ',
                  Icons.help_outline,
                  () {
                    context.go('/help');
                  },
                ),
                
                _buildMenuItem(
                  context,
                  'Điều khoản sử dụng',
                  Icons.description_outlined,
                  () {
                    context.go('/terms');
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLogoutDialog(context, authProvider);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      );
    }

  

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
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
  ) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}