import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class MeowlGuard extends StatelessWidget {
  final Widget child;
  const MeowlGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!auth.isAuthenticated) {
      // redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }
    return child;
  }
}
