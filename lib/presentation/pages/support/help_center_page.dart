import 'package:flutter/material.dart';
import '../../../core/utils/string_helper.dart';
import '../../widgets/skillverse_app_bar.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String _search = '';
  // int? _selectedCategory; // not used for now

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Tài Khoản & Bảo Mật',
      'faqs': [
        {
          'q': 'Làm thế nào để thay đổi mật khẩu?',
          'a': 'Vào Cài đặt > Bảo mật > Đổi mật khẩu.',
        },
        {
          'q': 'Quên mật khẩu thì sao?',
          'a': 'Sử dụng tính năng Quên mật khẩu để đặt lại.',
        },
      ],
    },
    {
      'title': 'Khóa Học & Học Tập',
      'faqs': [
        {
          'q': 'Làm sao để tìm khóa học phù hợp?',
          'a': 'Dùng bộ lọc hoặc tìm kiếm theo chủ đề.',
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filtered => _search.isEmpty
      ? _categories
      : _categories
            .map(
              (c) => {
                'title': c['title'],
                'faqs': (c['faqs'] as List)
                    .where(
                      (f) =>
                          StringHelper.removeDiacritics(
                            f['q'] as String,
                          ).contains(StringHelper.removeDiacritics(_search)) ||
                          StringHelper.removeDiacritics(
                            f['a'] as String,
                          ).contains(StringHelper.removeDiacritics(_search)),
                    )
                    .toList(),
              },
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SkillVerseAppBar(title: 'Trung Tâm Hỗ Trợ'),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm kiếm câu hỏi...',
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, idx) {
                    final cat = _filtered[idx];
                    final faqs = cat['faqs'] as List;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Text(cat['title']),
                        children: faqs
                            .map<Widget>(
                              (f) => ListTile(
                                title: Text(f['q']),
                                subtitle: Text(f['a']),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _SupportCard(
                    icon: Icons.mail,
                    title: 'Email',
                    detail: 'support@skillverse.com',
                  ),
                  _SupportCard(
                    icon: Icons.phone,
                    title: 'Hotline',
                    detail: '1800 1234',
                  ),
                  _SupportCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    detail: '8:00 - 22:00',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 120,
        height: 96,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(detail, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
