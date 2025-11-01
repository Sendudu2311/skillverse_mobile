import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/course_models.dart';
import '../../../data/models/module_models.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/services/module_service.dart';
import 'course_learning_page.dart';

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

  CourseSummaryDto? _course;
  List<ModuleSummaryDto> _modules = [];
  bool _isLoadingCourse = true;
  bool _isLoadingModules = true;
  bool _isEnrolling = false;

  final ModuleService _moduleService = ModuleService();

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    final courseId = int.tryParse(widget.courseId);
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID khóa học không hợp lệ')),
      );
      return;
    }

    final courseProvider = context.read<CourseProvider>();
    final enrollmentProvider = context.read<EnrollmentProvider>();
    final authProvider = context.read<AuthProvider>();

    // Load course details
    setState(() => _isLoadingCourse = true);
    try {
      final course = await courseProvider.getCourseById(courseId);
      setState(() {
        _course = course;
        _isLoadingCourse = false;
      });
    } catch (e) {
      setState(() => _isLoadingCourse = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải khóa học: $e')),
        );
      }
    }

    // Load modules
    setState(() => _isLoadingModules = true);
    try {
      final modules = await _moduleService.listModules(courseId: courseId);
      setState(() {
        _modules = modules;
        _isLoadingModules = false;
      });
    } catch (e) {
      setState(() => _isLoadingModules = false);
      debugPrint('Error loading modules: $e');
    }

    // Check enrollment status
    if (authProvider.user != null) {
      await enrollmentProvider.checkEnrollmentStatus(
        courseId: courseId,
        userId: authProvider.user!.id,
      );
    }
  }

  void toggleWishlist() => setState(() => isWishlisted = !isWishlisted);

  void toggleModule(int id) =>
      setState(() => expandedModule = expandedModule == id ? null : id);

  Future<void> _handleEnroll() async {
    if (_course == null) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đăng ký khóa học')),
      );
      return;
    }

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final courseId = int.parse(widget.courseId);

    // Check if already enrolled
    if (enrollmentProvider.isEnrolled(courseId)) {
      // Navigate to course learning page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseLearningPage(courseId: widget.courseId),
        ),
      );
      return;
    }

    // Check if free course
    if (_course!.price == null || _course!.price == 0) {
      setState(() => _isEnrolling = true);
      final success = await enrollmentProvider.enrollInCourse(
        courseId: courseId,
        userId: authProvider.user!.id,
      );
      setState(() => _isEnrolling = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký khóa học thành công!')),
        );
        // Navigate to course learning page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseLearningPage(courseId: widget.courseId),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enrollmentProvider.errorMessage ?? 'Đăng ký thất bại'),
          ),
        );
      }
    } else {
      // Paid course - navigate to payment
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chức năng thanh toán sẽ được triển khai sau'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCourse) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết khóa học'),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết khóa học'),
          elevation: 0,
        ),
        body: const Center(child: Text('Không tìm thấy khóa học')),
      );
    }

    final enrollmentProvider = context.watch<EnrollmentProvider>();
    final isEnrolled =
        enrollmentProvider.isEnrolled(int.parse(widget.courseId));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Chi tiết khóa học'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: Center(
                child: _course!.thumbnailUrl != null
                    ? Image.network(
                        _course!.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.play_circle_fill,
                                size: 72, color: Colors.white),
                      )
                    : const Icon(Icons.play_circle_fill,
                        size: 72, color: Colors.white),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _course!.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _course!.description ?? 'Không có mô tả',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_course!.rating != null) ...[
                          Chip(
                            avatar: const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            label: Text(
                              _course!.rating!.toStringAsFixed(1),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Chip(
                          avatar: const Icon(Icons.people, size: 16),
                          label: Text('${_course!.enrollmentCount}'),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.school, size: 16),
                          label:
                              Text(_course!.level.name.toUpperCase()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _course!.price == null || _course!.price == 0
                                ? 'MIỄN PHÍ'
                                : '${_course!.price!.toStringAsFixed(0)} ${_course!.currency ?? 'VNĐ'}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isEnrolling ? null : _handleEnroll,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: _isEnrolling
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isEnrolled
                                            ? 'Vào học'
                                            : 'Đăng ký ngay',
                                        maxLines: 1,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: toggleWishlist,
                              icon: Icon(isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              label: Text(
                                isWishlisted ? 'Đã lưu' : 'Lưu khóa học',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Khóa học bao gồm:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall,
                          ),
                          const SizedBox(height: 6),
                          const Text('• Truy cập trọn đời',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const Text('• Chứng chỉ hoàn thành',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const Text('• Hỗ trợ giảng viên',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
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
                  _TabButton(
                    label: 'Tổng quan',
                    active: activeTab == 'overview',
                    onTap: () => setState(() => activeTab = 'overview'),
                  ),
                  _TabButton(
                    label: 'Nội dung khóa học',
                    active: activeTab == 'curriculum',
                    onTap: () => setState(() => activeTab = 'curriculum'),
                  ),
                  _TabButton(
                    label: 'Giảng viên',
                    active: activeTab == 'instructor',
                    onTap: () => setState(() => activeTab = 'instructor'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: activeTab == 'overview'
                  ? _buildOverview()
                  : activeTab == 'curriculum'
                      ? _buildCurriculum()
                      : _buildInstructor(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(_course!.description ?? 'Không có mô tả'),
        const SizedBox(height: 16),
        Text(
          'Chi tiết khóa học',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.school,
          label: 'Cấp độ',
          value: _course!.level.name.toUpperCase(),
        ),
        _InfoRow(
          icon: Icons.people,
          label: 'Học viên',
          value: '${_course!.enrollmentCount}',
        ),
        if (_course!.rating != null)
          _InfoRow(
            icon: Icons.star,
            label: 'Đánh giá',
            value: '${_course!.rating!.toStringAsFixed(1)}/5.0',
          ),
        _InfoRow(
          icon: Icons.subject,
          label: 'Số module',
          value: '${_modules.length}',
        ),
      ],
    );
  }

  Widget _buildCurriculum() {
    if (_isLoadingModules) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_modules.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Chưa có nội dung khóa học'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _modules.map((module) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: module.description != null
                ? Text(module.description!)
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => toggleModule(module.id),
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
            CircleAvatar(
              radius: 36,
              child: Text(
                (_course!.author.firstName?.isNotEmpty ?? false ? _course!.author.firstName![0] : 'U').toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giảng viên: ${_course!.authorName ?? _course!.author.fullName ?? '${_course!.author.firstName} ${_course!.author.lastName}'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('Email: ${_course!.author.email}'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor:
              active ? Theme.of(context).colorScheme.primary : Colors.grey[200],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}
