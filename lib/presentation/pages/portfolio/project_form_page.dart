import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../../data/models/portfolio_models.dart';

class ProjectFormPage extends StatefulWidget {
  final ProjectDto? project;

  const ProjectFormPage({super.key, this.project});

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _technologiesController;
  late TextEditingController _imageUrlController;
  late TextEditingController _projectUrlController;
  late TextEditingController _githubUrlController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  bool _isFeatured = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _titleController = TextEditingController(text: project?.title);
    _descriptionController = TextEditingController(text: project?.description);
    _technologiesController = TextEditingController(text: project?.technologies);
    _imageUrlController = TextEditingController(text: project?.imageUrl);
    _projectUrlController = TextEditingController(text: project?.projectUrl);
    _githubUrlController = TextEditingController(text: project?.githubUrl);
    _startDateController = TextEditingController(text: project?.startDate);
    _endDateController = TextEditingController(text: project?.endDate);
    _isFeatured = project?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _technologiesController.dispose();
    _imageUrlController.dispose();
    _projectUrlController.dispose();
    _githubUrlController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final portfolioProvider = context.read<PortfolioProvider>();
    final bool success;

    if (widget.project == null) {
      final request = CreateProjectRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        technologies: _technologiesController.text.trim().isEmpty ? null : _technologiesController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        projectUrl: _projectUrlController.text.trim().isEmpty ? null : _projectUrlController.text.trim(),
        githubUrl: _githubUrlController.text.trim().isEmpty ? null : _githubUrlController.text.trim(),
        startDate: _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim(),
        endDate: _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim(),
        isFeatured: _isFeatured,
      );
      success = await portfolioProvider.createProject(request);
    } else {
      final request = UpdateProjectRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        technologies: _technologiesController.text.trim().isEmpty ? null : _technologiesController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        projectUrl: _projectUrlController.text.trim().isEmpty ? null : _projectUrlController.text.trim(),
        githubUrl: _githubUrlController.text.trim().isEmpty ? null : _githubUrlController.text.trim(),
        startDate: _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim(),
        endDate: _endDateController.text.trim().isEmpty ? null : _endDateController.text.trim(),
        isFeatured: _isFeatured,
      );
      success = await portfolioProvider.updateProject(widget.project!.id!, request);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.project == null ? 'Tạo dự án thành công!' : 'Cập nhật dự án thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(portfolioProvider.errorMessage ?? 'Có lỗi xảy ra')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Thêm dự án' : 'Chỉnh sửa dự án'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Lưu'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên dự án *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập tên dự án' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả *',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _technologiesController,
              decoration: const InputDecoration(
                labelText: 'Công nghệ sử dụng',
                hintText: 'Flutter, Firebase, Node.js',
                prefixIcon: Icon(Icons.code),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL hình ảnh',
                hintText: 'https://example.com/image.png',
                prefixIcon: Icon(Icons.image),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _projectUrlController,
              decoration: const InputDecoration(
                labelText: 'URL dự án',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _githubUrlController,
              decoration: const InputDecoration(
                labelText: 'GitHub Repository',
                hintText: 'https://github.com/username/repo',
                prefixIcon: Icon(Icons.folder_open),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày bắt đầu',
                      hintText: '2024-01-01',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Ngày kết thúc',
                      hintText: '2024-12-31',
                      prefixIcon: Icon(Icons.event),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Dự án nổi bật'),
              subtitle: const Text('Hiển thị dự án này ở đầu danh sách'),
              value: _isFeatured,
              onChanged: (value) => setState(() => _isFeatured = value),
            ),
          ],
        ),
      ),
    );
  }
}
