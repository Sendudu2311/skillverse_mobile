import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  String _search = '';
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'Tất Cả', 'icon': Icons.work_outline, 'count': 89},
    {
      'id': 'design',
      'name': 'Thiết Kế',
      'icon': Icons.palette_outlined,
      'count': 18,
    },
    {
      'id': 'writing',
      'name': 'Viết Lách',
      'icon': Icons.edit_outlined,
      'count': 15,
    },
    {'id': 'development', 'name': 'Lập Trình', 'icon': Icons.code, 'count': 25},
    {
      'id': 'marketing',
      'name': 'Marketing',
      'icon': Icons.trending_up,
      'count': 20,
    },
  ];

  final List<Map<String, dynamic>> _jobs = [
    {
      'id': 1,
      'title': 'Thiết Kế Logo & Brand Identity',
      'company': 'TechViet Solutions',
      'category': 'design',
      'budget': '3.000.000 - 5.000.000 VNĐ',
      'duration': '1-2 tuần',
      'type': 'remote',
      'level': 'Trung cấp',
      'description':
          'Tìm designer có kinh nghiệm thiết kế logo và brand identity cho startup công nghệ.',
      'skills': ['Adobe Illustrator', 'Photoshop', 'Brand Design'],
      'gradientColors': [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
    },
    {
      'id': 2,
      'title': 'Full Stack Developer - React & Node.js',
      'company': 'Digital Hub Co.',
      'category': 'development',
      'budget': '10.000.000 - 15.000.000 VNĐ',
      'duration': '2-3 tháng',
      'type': 'hybrid',
      'level': 'Senior',
      'description':
          'Phát triển web application với React frontend và Node.js backend.',
      'skills': ['React', 'Node.js', 'MongoDB', 'TypeScript'],
      'gradientColors': [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
    },
    {
      'id': 3,
      'title': 'Content Writer - Blog & Social Media',
      'company': 'Green Energy Vietnam',
      'category': 'writing',
      'budget': '2.000.000 - 4.000.000 VNĐ',
      'duration': '1 tháng',
      'type': 'remote',
      'level': 'Mới bắt đầu',
      'description':
          'Viết content cho blog và quản lý social media về năng lượng xanh.',
      'skills': ['Content Writing', 'SEO', 'Social Media'],
      'gradientColors': [AppTheme.themeGreenStart, AppTheme.themeGreenEnd],
    },
    {
      'id': 4,
      'title': 'Digital Marketing Specialist',
      'company': 'Online Retail Plus',
      'category': 'marketing',
      'budget': '8.000.000 - 12.000.000 VNĐ',
      'duration': '3 tháng',
      'type': 'remote',
      'level': 'Trung cấp',
      'description':
          'Quản lý campaigns marketing trên Google Ads và Facebook Ads.',
      'skills': ['Google Ads', 'Facebook Ads', 'Analytics'],
      'gradientColors': [AppTheme.themeOrangeStart, AppTheme.themeOrangeEnd],
    },
    {
      'id': 5,
      'title': 'Mobile App Developer - Flutter',
      'company': 'FinTech Startup',
      'category': 'development',
      'budget': '15.000.000 - 20.000.000 VNĐ',
      'duration': '3-4 tháng',
      'type': 'remote',
      'level': 'Senior',
      'description':
          'Phát triển ứng dụng di động cho nền tảng FinTech sử dụng Flutter.',
      'skills': ['Flutter', 'Dart', 'Firebase', 'REST API'],
      'gradientColors': [AppTheme.themeBlueStart, AppTheme.themeBlueEnd],
    },
    {
      'id': 6,
      'title': 'UI/UX Designer - Web & Mobile',
      'company': 'Fashion Brand Vietnam',
      'category': 'design',
      'budget': '5.000.000 - 8.000.000 VNĐ',
      'duration': '1-2 tháng',
      'type': 'hybrid',
      'level': 'Trung cấp',
      'description':
          'Thiết kế giao diện cho website và mobile app thương mại điện tử thời trang.',
      'skills': ['Figma', 'User Research', 'Wireframing', 'Prototyping'],
      'gradientColors': [AppTheme.themePurpleStart, AppTheme.themePurpleEnd],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _jobs.where((j) {
      final matchesSearch =
          j['title'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          j['company'].toString().toLowerCase().contains(_search.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'all' || j['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(
                    context,
                  ).iconTheme.color?.withValues(alpha: 0.6),
                ),
                hintText: 'Tìm kiếm việc làm...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          const SizedBox(height: 16),

          // Categories
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory = category['id'] as String,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 85,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  AppTheme.themeBlueStart,
                                  AppTheme.themeBlueEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.themeBlueStart
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.themeBlueStart.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).iconTheme.color,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['name'] as String,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 11,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Jobs List Header
          Text(
            filtered.isEmpty ? 'Không tìm thấy' : '${filtered.length} việc làm',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.work_off_outlined,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy việc làm phù hợp',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((job) => _buildJobCard(context, job)),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final List<Color> gradientColors;
    if (job['gradientColors'] != null && job['gradientColors'] is List) {
      gradientColors = List<Color>.from(job['gradientColors'] as List);
    } else {
      gradientColors = [AppTheme.themeBlueStart, AppTheme.themeBlueEnd];
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Company Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['company'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
                color: Theme.of(
                  context,
                ).iconTheme.color?.withValues(alpha: 0.6),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            job['description'] as String,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Skills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (job['skills'] as List<String>).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gradientColors.first.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: gradientColors.first.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  skill,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: gradientColors.first,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Footer Info
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  context,
                  Icons.payments_outlined,
                  job['budget'] as String,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _buildInfoChip(
                context,
                Icons.schedule_outlined,
                job['duration'] as String,
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                context,
                Icons.location_on_outlined,
                job['type'] == 'remote'
                    ? 'Remote'
                    : job['type'] == 'hybrid'
                    ? 'Hybrid'
                    : 'Onsite',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                context,
                Icons.bar_chart_outlined,
                job['level'] as String,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: gradientColors.first.withValues(alpha: 0.5),
                ),
                foregroundColor: gradientColors.first,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Ứng tuyển ngay'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
