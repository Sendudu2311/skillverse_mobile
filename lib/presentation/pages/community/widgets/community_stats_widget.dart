import 'package:flutter/material.dart';
import '../../../../data/models/post_models.dart';

class CommunityStatsWidget extends StatelessWidget {
  final PostStats? stats;
  final List<Trend>? trends;
  final bool isLoading;

  const CommunityStatsWidget({
    super.key,
    this.stats,
    this.trends,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null && (trends == null || trends!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'THỐNG KÊ HỆ THỐNG',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  context,
                  'Thành viên',
                  stats!.totalUsers.toString(),
                  Icons.people_outline,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  'Bài viết',
                  stats!.totalPosts.toString(),
                  Icons.article_outlined,
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  context,
                  'Tín hiệu',
                  stats!.signal.toString(),
                  Icons.show_chart,
                ),
              ],
            ),
          ),
        ],
        if (trends != null && trends!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'XU HƯỚNG',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: trends!.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final trend = entry.value;

                // Different colors for variety
                final colors = [
                  [Color(0xFF667eea), Color(0xFF764ba2)],
                  [Color(0xFFf093fb), Color(0xFFF5576C)],
                  [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  [Color(0xFFfa709a), Color(0xFFfee140)],
                  [Color(0xFF30cfd0), Color(0xFF330867)],
                ];

                final colorPair = colors[index % colors.length];

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorPair[0].withOpacity(0.1),
                        colorPair[1].withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: 1.5,
                      color: colorPair[0].withOpacity(0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        // Could filter by tag
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${trend.topic}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorPair[0],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: colorPair),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${trend.count}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    // Different gradient for each card
    final gradients = [
      [Color(0xFF667eea), Color(0xFF764ba2)], // Purple
      [Color(0xFFf093fb), Color(0xFFF5576C)], // Pink
      [Color(0xFF4facfe), Color(0xFF00f2fe)], // Blue
    ];

    final index = label == 'Thành viên' ? 0 : (label == 'Bài viết' ? 1 : 2);
    final gradient = gradients[index];

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gradient[0].withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
