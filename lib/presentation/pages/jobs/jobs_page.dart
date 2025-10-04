import 'package:flutter/material.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  String _search = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'Tất Cả', 'count': 89},
    {'id': 'design', 'name': 'Thiết Kế', 'count': 18},
    {'id': 'writing', 'name': 'Viết Lách', 'count': 15},
  ];

  final List<Map<String, dynamic>> _jobs = List.generate(6, (i) => {
    'id': i + 1,
    'title': ['Thiết Kế Logo', 'Nhập Dữ Liệu', 'Viết Bài Blog', 'Nghiên Cứu Thị Trường', 'Dịch Anh-Việt', 'Quản Lý Facebook'][i % 6],
    'company': ['TechViet', 'Green Energy', 'Digital Hub', 'Online Retail', 'Global Translate', 'Fashion Brand'][i % 6],
    'category': ['design', 'data-entry', 'writing', 'research', 'translation', 'social-media'][i % 6],
    'budget': '1.000.000 - 3.000.000',
    'duration': '1-7 ngày',
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _jobs.where((j) {
      final matchesSearch = j['title'].toString().toLowerCase().contains(_search.toLowerCase()) || j['company'].toString().toLowerCase().contains(_search.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || j['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Việc Làm Tự Do')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm kiếm việc làm...'),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem<String>(value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'all'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('Không tìm thấy việc làm'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final job = filtered[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(job['title']),
                            subtitle: Text(job['company']),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [Text(job['budget']), Text(job['duration'])],
                            ),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
