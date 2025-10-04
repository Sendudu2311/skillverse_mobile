import 'package:flutter/material.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  bool isWishlisted = false;
  String activeTab = 'overview';
  int? expandedModule;

  final mockCourse = {
    'id': '1',
    'title': 'The Complete React Developer Course',
    'description': 'Learn React from scratch and build real-world projects.',
    'image': null,
    'price': '1,999,000 VNĐ',
    'rating': 4.8,
    'students': 15200,
    'duration': '6 tuần',
    'modules': 12,
  };

  final modules = [
    {
      'id': 1,
      'title': 'Giới thiệu và Cài đặt',
      'duration': '45 phút',
      'lessons': ['Giới thiệu', 'Cài đặt môi trường', 'Tạo project']
    },
    {
      'id': 2,
      'title': 'Components, Props và State',
      'duration': '1 giờ 20 phút',
      'lessons': ['Functional components', 'Props', 'useState']
    }
  ];

  void toggleWishlist() => setState(() => isWishlisted = !isWishlisted);

  void toggleModule(int id) => setState(() => expandedModule = expandedModule == id ? null : id);

  void enroll() {
    final price = mockCourse['price'] as String?;
    if (price == null || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký khóa học miễn phí.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đi tới trang thanh toán cho ${mockCourse['title']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mockCourse['title'] as String),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: Center(
                child: mockCourse['image'] == null
                    ? const Icon(Icons.play_circle_fill, size: 72, color: Colors.white)
                    : Image.network(mockCourse['image'] as String),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mockCourse['title'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(mockCourse['description'] as String),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text('${mockCourse['rating']}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(width: 12),
                            const Icon(Icons.people, size: 16),
                            const SizedBox(width: 6),
                            Text('${mockCourse['students']} học viên'),
                            const SizedBox(width: 12),
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 6),
                            Text('${mockCourse['duration'] ?? '—'}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card
                  Container(
                    width: 260,
                    margin: const EdgeInsets.only(left: 12),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(mockCourse['price'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: enroll, child: const Text('Đăng ký ngay')),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(onPressed: toggleWishlist, icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border), label: Text(isWishlisted ? 'Đã lưu' : 'Lưu khóa học')),
                            const Divider(),
                            Text('Khóa học bao gồm:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            const Text('• Truy cập trọn đời'),
                            const Text('• Chứng chỉ hoàn thành'),
                            const Text('• Hỗ trợ giảng viên'),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _TabButton(label: 'Tổng quan', active: activeTab == 'overview', onTap: () => setState(() => activeTab = 'overview')),
                  _TabButton(label: 'Nội dung khóa học', active: activeTab == 'curriculum', onTap: () => setState(() => activeTab = 'curriculum')),
                  _TabButton(label: 'Giảng viên', active: activeTab == 'instructor', onTap: () => setState(() => activeTab = 'instructor')),
                  _TabButton(label: 'Đánh giá', active: activeTab == 'reviews', onTap: () => setState(() => activeTab = 'reviews')),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: activeTab == 'overview'
                  ? Text('Mô tả chi tiết về khóa học sẽ được hiển thị ở đây. ${mockCourse['description']}')
                  : activeTab == 'curriculum'
                      ? _buildCurriculum()
                      : activeTab == 'instructor'
                          ? _buildInstructor()
                          : _buildReviews(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculum() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: modules.map((m) {
        final id = m['id'] as int;
        final lessons = m['lessons'] as List<String>;
        final isExpanded = expandedModule == id;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            title: Text('${m['title']} • ${m['duration']}'),
            children: lessons.map((l) => ListTile(title: Text(l))).toList(),
            onExpansionChanged: (_) => toggleModule(id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(radius: 36, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Giảng viên: John Doe', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Senior Frontend Developer • 8+ năm kinh nghiệm'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () {}, child: const Text('Xem hồ sơ giảng viên'))
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReviews() {
    final reviews = [
      {'user': 'Nguyen A', 'rating': 5, 'comment': 'Khóa học rất tốt!'},
      {'user': 'Tran B', 'rating': 4, 'comment': 'Nội dung hữu ích.'}
    ];
    return Column(
      children: reviews.map((r) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Text(r['user'] as String),
          subtitle: Text(r['comment'] as String),
        ),
      )).toList(),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor: active ? Theme.of(context).colorScheme.primary : Colors.grey[200],
        ),
      ),
    );
  }
}
