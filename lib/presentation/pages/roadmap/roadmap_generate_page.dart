import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../themes/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';

class RoadmapGeneratePage extends StatelessWidget {
  const RoadmapGeneratePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SkillVerseAppBar(
        title: 'Tạo lộ trình học tập',
        centerTitle: true,
      ),
      body: SafeArea(
        child: EmptyStateWidget(
          icon: Icons.route_outlined,
          title: 'Chức năng đã nâng cấp',
          subtitle:
              'Vui lòng tạo Roadmap thông qua Journey để có trải nghiệm tốt hơn',
          ctaLabel: 'Tạo Journey mới',
          onCtaPressed: () => context.push('/journey/create'),
          iconGradient: const LinearGradient(
            colors: [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
          ),
        ),
      ),
    );
  }
}
