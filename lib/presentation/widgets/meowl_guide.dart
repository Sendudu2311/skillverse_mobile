import 'package:flutter/material.dart';

class MeowlGuide extends StatelessWidget {
  final String currentPage;
  const MeowlGuide({super.key, this.currentPage = ''});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton.extended(
          heroTag: 'meowl_guide_fab',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meowl Guide', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Gợi ý và trợ giúp cho trang: $currentPage'),
                      const SizedBox(height: 12),
                      const Text('- Nhấn vào một mục để xem chi tiết'),
                      const SizedBox(height: 8),
                      const Text('- Bạn có thể tắt hướng dẫn nếu không cần'),
                    ],
                  ),
                ),
              ),
            );
          },
          label: const Text('Meowl Guide'),
          icon: const Icon(Icons.live_help_outlined),
        ),
      ),
    );
  }
}
