import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'galaxy_background.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentPath;
  final bool showAppBar;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
    this.showAppBar = true,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    // Main navigation: Dashboard, Courses, Jobs, Chat, Profile
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    NavigationItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Khóa học',
      route: '/courses',
    ),
    NavigationItem(
      icon: Icons.work_outline,
      activeIcon: Icons.work,
      label: 'Việc làm',
      route: '/jobs',
    ),
    NavigationItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum,
      label: 'Cộng đồng',
      route: '/community',
    ),
    NavigationItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Chat',
      route: '/chat',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Hồ sơ',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    // Special case: Portfolio page highlights Profile tab
    if (widget.currentPath == '/portfolio') {
      setState(() {
        _selectedIndex =
            5; // Profile tab index (updated after adding Community)
      });
      return;
    }

    // Check for exact match first, then prefix match
    int? exactMatch;
    int? prefixMatch;

    for (int i = 0; i < _navigationItems.length; i++) {
      if (widget.currentPath == _navigationItems[i].route) {
        exactMatch = i;
        break;
      }
      if (prefixMatch == null &&
          widget.currentPath.startsWith(_navigationItems[i].route)) {
        prefixMatch = i;
      }
    }

    setState(() {
      _selectedIndex = exactMatch ?? prefixMatch ?? 0;
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      context.go(_navigationItems[index].route);
    }
  }

  String _getPageTitle() {
    switch (widget.currentPath) {
      case '/dashboard':
        return 'Dashboard';
      case '/courses':
        return 'Khóa học';
      case '/jobs':
        return 'Việc làm';
      case '/community':
        return 'Cộng đồng';
      case '/chat':
        return 'Chat';
      case '/profile':
        return 'Hồ sơ';
      case '/portfolio':
        return 'Portfolio';
      case '/roadmap':
        return 'AI Roadmap';
      case '/mentors':
        return 'Mentor Network';
      case '/my-bookings':
        return 'Lịch hẹn';
      case '/skins':
        return 'Meowl Skin Shop';
      default:
        return 'SkillVerse';
    }
  }

  void _showLogoutDialog(BuildContext context) {
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
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowBackButton() {
    // Show back button for sub-pages (not main navigation items)
    // Special pages that need back button
    final pagesWithBackButton = [
      '/portfolio',
      '/mentors',
      '/my-bookings',
      '/roadmap',
      '/skins',
    ];

    if (pagesWithBackButton.any(
      (path) => widget.currentPath.startsWith(path),
    )) {
      return true;
    }

    return !_navigationItems.any((item) => item.route == widget.currentPath);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(_getPageTitle()),
              automaticallyImplyLeading: _shouldShowBackButton(),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Implement notifications
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            )
          : null,
      body: isDarkMode ? GalaxyBackground(child: widget.child) : widget.child,
      bottomNavigationBar: _navigationItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDarkMode
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              selectedItemColor: isDarkMode
                  ? const Color(0xFF6366F1)
                  : Theme.of(context).colorScheme.primary,
              unselectedItemColor: isDarkMode
                  ? Colors.grey.shade600
                  : Colors.grey,
              showUnselectedLabels: true,
              elevation: 16,
              items: _navigationItems
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      activeIcon: Icon(item.activeIcon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : BottomAppBar(
              elevation: 8,
              color: Colors.white,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_navigationItems.isNotEmpty) ...[
                      IconButton(
                        icon: Icon(
                          _navigationItems[0].icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          if (_selectedIndex != 0)
                            context.go(_navigationItems[0].route);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _navigationItems[0].label,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
