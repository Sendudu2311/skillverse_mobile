import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/roadmap_provider.dart';
import '../../widgets/roadmap_card.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoadmapProvider>().loadRoadmaps();
      context.read<RoadmapProvider>().loadUserRoadmaps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Roadmaps'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Roadmaps'),
            Tab(text: 'My Progress'),
          ],
        ),
      ),
      body: Consumer<RoadmapProvider>(
        builder: (context, roadmapProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // All Roadmaps Tab
              _buildRoadmapsList(roadmapProvider.roadmaps, roadmapProvider.isLoading, roadmapProvider.errorMessage),

              // My Progress Tab
              _buildRoadmapsList(roadmapProvider.userRoadmaps, roadmapProvider.isLoading, roadmapProvider.errorMessage),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoadmapsList(List roadmaps, bool isLoading, String? error) {
    if (isLoading && roadmaps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            ElevatedButton(
              onPressed: () => context.read<RoadmapProvider>().refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (roadmaps.isEmpty) {
      return const Center(
        child: Text('No roadmaps available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roadmaps.length,
      itemBuilder: (context, index) {
        final roadmap = roadmaps[index];
        return RoadmapCard(roadmap: roadmap);
      },
    );
  }
}
