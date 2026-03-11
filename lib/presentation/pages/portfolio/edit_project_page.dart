import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/glass_card.dart';
import '../../themes/app_theme.dart';
import '../../../data/models/portfolio_models.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../core/utils/error_handler.dart';

class EditProjectPage extends StatefulWidget {
  final ProjectDto? existingProject;
  final bool isCreate;

  const EditProjectPage({
    super.key,
    this.existingProject,
    this.isCreate = true,
  });

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage>
    with SingleTickerProviderStateMixin {
  late bool isDark;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _technologiesController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _projectUrlController = TextEditingController();
  final _githubUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFeatured = false;
  bool _isLoading = false;

  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Populate existing data
    if (widget.existingProject != null) {
      final project = widget.existingProject!;
      _titleController.text = project.title ?? '';
      _descriptionController.text = project.description ?? '';
      _technologiesController.text = project.technologies ?? '';
      _imageUrlController.text = project.imageUrl ?? '';
      _projectUrlController.text = project.projectUrl ?? '';
      _githubUrlController.text = project.githubUrl ?? '';
      _isFeatured = project.isFeatured ?? false;

      if (project.startDate != null) {
        try {
          _startDate = DateTime.parse(project.startDate!);
        } catch (_) {}
      }
      if (project.endDate != null) {
        try {
          _endDate = DateTime.parse(project.endDate!);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _technologiesController.dispose();
    _imageUrlController.dispose();
    _projectUrlController.dispose();
    _githubUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.themeBlueStart,
                    surface: AppTheme.darkCardBackground,
                  )
                : ColorScheme.light(
                    primary: AppTheme.themeBlueStart,
                    surface: Colors.grey.shade50,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng kiểm tra lại thông tin đã nhập',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final portfolioProvider = context.read<PortfolioProvider>();
      bool success;

      if (widget.isCreate) {
        final request = CreateProjectRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          technologies: _technologiesController.text.trim().isEmpty
              ? null
              : _technologiesController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          projectUrl: _projectUrlController.text.trim().isEmpty
              ? null
              : _projectUrlController.text.trim(),
          githubUrl: _githubUrlController.text.trim().isEmpty
              ? null
              : _githubUrlController.text.trim(),
          startDate: _startDate != null ? _dateFormat.format(_startDate!) : null,
          endDate: _endDate != null ? _dateFormat.format(_endDate!) : null,
          isFeatured: _isFeatured,
        );
        success = await portfolioProvider.createProject(request);
      } else {
        final request = UpdateProjectRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          technologies: _technologiesController.text.trim().isEmpty
              ? null
              : _technologiesController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          projectUrl: _projectUrlController.text.trim().isEmpty
              ? null
              : _projectUrlController.text.trim(),
          githubUrl: _githubUrlController.text.trim().isEmpty
              ? null
              : _githubUrlController.text.trim(),
          startDate: _startDate != null ? _dateFormat.format(_startDate!) : null,
          endDate: _endDate != null ? _dateFormat.format(_endDate!) : null,
          isFeatured: _isFeatured,
        );
        success = await portfolioProvider.updateProject(
          widget.existingProject!.id!,
          request,
        );
      }

      if (!mounted) return;

      if (success) {
        ErrorHandler.showSuccessSnackBar(
          context,
          widget.isCreate ? 'Tạo dự án thành công!' : 'Cập nhật dự án thành công!',
        );
        Navigator.pop(context, true);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          portfolioProvider.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Galaxy Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppTheme.galaxyDarkest, AppTheme.galaxyDark]
                      : [Colors.grey.shade50, Colors.white],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  _buildCustomAppBar(),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            _buildSectionHeader(
                              icon: Icons.work,
                              title: widget.isCreate
                                  ? 'Thêm dự án mới'
                                  : 'Chỉnh sửa dự án',
                              gradientColors: const [
                                AppTheme.themeBlueStart,
                                AppTheme.themeBlueEnd
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Basic Info Section
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),

                            // Links Section
                            _buildLinksSection(),
                            const SizedBox(height: 24),

                            // Timeline Section
                            _buildTimelineSection(),
                            const SizedBox(height: 24),

                            // Featured Section
                            _buildFeaturedSection(),
                            const SizedBox(height: 32),

                            // Save Button
                            _buildSaveButton(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.lightTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.isCreate ? 'Thêm dự án' : 'Chỉnh sửa dự án',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradientColors,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: gradientColors,
            ).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin dự án',
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          _buildTextField(
            controller: _titleController,
            label: 'Tên dự án *',
            hint: 'vd: E-commerce Website',
            prefixIcon: Icons.title,
            validator: (value) => ValidationHelper.required(value, fieldName: 'Tên dự án'),
          ),
          const SizedBox(height: 16),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Mô tả *',
            hint: 'Mô tả chi tiết về dự án...',
            prefixIcon: Icons.description,
            maxLines: 5,
            maxLength: 500,
            validator: (value) => ValidationHelper.required(value, fieldName: 'Mô tả'),
          ),
          const SizedBox(height: 16),

          // Technologies
          _buildTextField(
            controller: _technologiesController,
            label: 'Công nghệ',
            hint: 'vd: Flutter, Firebase, Node.js',
            prefixIcon: Icons.code,
          ),
          const SizedBox(height: 16),

          // Image URL
          _buildTextField(
            controller: _imageUrlController,
            label: 'URL hình ảnh',
            hint: 'https://example.com/image.jpg',
            prefixIcon: Icons.image,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: AppTheme.themeBlueStart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Liên kết',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Project URL
          _buildTextField(
            controller: _projectUrlController,
            label: 'URL dự án',
            hint: 'https://myproject.com',
            prefixIcon: Icons.language,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.url(value, isRequired: false),
          ),
          const SizedBox(height: 16),

          // GitHub URL
          _buildTextField(
            controller: _githubUrlController,
            label: 'GitHub Repository',
            hint: 'https://github.com/user/repo',
            prefixIcon: Icons.code,
            keyboardType: TextInputType.url,
            validator: (value) => ValidationHelper.githubRepoUrl(value, isRequired: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: AppTheme.themeOrangeStart, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thời gian',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Start Date
          _buildDateSelector(
            label: 'Ngày bắt đầu',
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 16),

          // End Date
          _buildDateSelector(
            label: 'Ngày kết thúc',
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? _dateFormat.format(date)
                        : 'Chọn ngày',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            _isFeatured ? Icons.star : Icons.star_outline,
            color: _isFeatured ? Colors.amber : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dự án nổi bật',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFeatured
                      ? 'Dự án này sẽ được hiển thị ưu tiên'
                      : 'Đánh dấu là dự án quan trọng',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
            },
            activeTrackColor: Colors.amber,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        counterText: maxLength != null ? null : '',
        labelStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        hintStyle: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      ),
      style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.blueGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.themeBlueStart.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProject,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        widget.isCreate ? 'Tạo dự án' : 'Lưu thay đổi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
