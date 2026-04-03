import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_theme.dart';
import 'galaxy_background.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final body = SafeArea(child: widget.child);

    return Scaffold(
      body: isDarkMode ? GalaxyBackground(child: body) : body,
      bottomNavigationBar: _navigationItems.length >= 2
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: isDarkMode
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              selectedItemColor: isDarkMode
                  ? AppTheme.primaryBlueDark
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
                          if (_selectedIndex != 0) {
                            context.go(_navigationItems[0].route);
                          }
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
