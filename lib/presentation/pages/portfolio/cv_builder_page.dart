import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/common_loading.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../../data/models/portfolio_models.dart';

class CVBuilderPage extends StatefulWidget {
  const CVBuilderPage({super.key});

  @override
  State<CVBuilderPage> createState() => _CVBuilderPageState();
}

class _CVBuilderPageState extends State<CVBuilderPage> {
  String _selectedTemplate = 'default';
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _templates = [
    {'id': 'default', 'name': 'Mẫu cơ bản', 'icon': Icons.description},
    {'id': 'modern', 'name': 'Hiện đại', 'icon': Icons.auto_awesome},
    {
      'id': 'professional',
      'name': 'Chuyên nghiệp',
      'icon': Icons.business_center,
    },
    {'id': 'creative', 'name': 'Sáng tạo', 'icon': Icons.palette},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().loadCVs();
    });
  }

  Future<void> _generateCV() async {
    final messenger = ScaffoldMessenger.of(context);
    final portfolioProvider = context.read<PortfolioProvider>();
    setState(() => _isGenerating = true);

    final request = GenerateCVRequest(
      templateName: _selectedTemplate,
      customData: {},
    );

    final success = await portfolioProvider.generateCV(request: request);

    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tạo CV thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(portfolioProvider.errorMessage ?? 'Có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setActiveCV(int cvId) async {
    final messenger = ScaffoldMessenger.of(context);
    final portfolioProvider = context.read<PortfolioProvider>();
    final success = await portfolioProvider.setActiveCV(cvId);

    if (mounted && success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã thiết lập CV hoạt động'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteCV(int cvId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa CV này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final messenger = ScaffoldMessenger.of(context);
      final portfolioProvider = context.read<PortfolioProvider>();
      final success = await portfolioProvider.deleteCV(cvId);

      if (mounted && success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Đã xóa CV'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkillVerseAppBar(title: 'Quản lý CV'),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CardSkeleton(imageHeight: null),
                  SizedBox(height: 16),
                  TextSkeleton(lines: 6),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Template Selection
                const Text(
                  'Chọn mẫu CV',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final isSelected = _selectedTemplate == template['id'];

                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedTemplate = template['id']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              template['icon'],
                              size: 48,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              template['name'],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateCV,
                    icon: _isGenerating
                        ? CommonLoading.small()
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating ? 'Đang tạo...' : 'Tạo CV'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // My CVs
                const Text(
                  'CV của tôi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (provider.cvs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có CV nào',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.cvs.length,
                    itemBuilder: (context, index) {
                      final cv = provider.cvs[index];
                      final isActive = cv.isActive ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: isActive
                                  ? Colors.green
                                  : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            cv.templateName ?? 'CV của tôi',
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            isActive ? 'CV đang hoạt động' : cv.createdAt ?? '',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (!isActive)
                                const PopupMenuItem(
                                  value: 'activate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 20),
                                      SizedBox(width: 12),
                                      Text('Kích hoạt'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'preview',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 12),
                                    Text('Xem trước'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'download',
                                child: Row(
                                  children: [
                                    Icon(Icons.download, size: 20),
                                    SizedBox(width: 12),
                                    Text('Tải xuống'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'activate':
                                  _setActiveCV(cv.id!);
                                  break;
                                case 'preview':
                                  // TODO: Implement preview
                                  break;
                                case 'download':
                                  // TODO: Implement download
                                  break;
                                case 'delete':
                                  _deleteCV(cv.id!);
                                  break;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
