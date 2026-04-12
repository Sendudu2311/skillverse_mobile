import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../data/models/assignment_models.dart';
import '../../../data/services/assignment_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/common_loading.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/skillverse_app_bar.dart';

/// AssignmentPage — student submits assignments and views grading results
/// Navigates from: CourseLearningPage → push('/assignment/:assignmentId')
class AssignmentPage extends StatefulWidget {
  final int assignmentId;
  final VoidCallback? onSubmitted;
  final bool isInline;

  const AssignmentPage({
    super.key,
    required this.assignmentId,
    this.onSubmitted,
    this.isInline = false,
  });

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  final AssignmentService _assignmentService = AssignmentService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  AssignmentDetailDto? _assignment;
  List<AssignmentSubmissionDetailDto> _submissions = [];

  // Form state
  final _textController = TextEditingController();
  final _linkController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _assignmentService.getAssignmentById(widget.assignmentId),
        _assignmentService.getMySubmissions(widget.assignmentId),
      ]);

      setState(() {
        _assignment = results[0] as AssignmentDetailDto;
        _submissions = results[1] as List<AssignmentSubmissionDetailDto>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // ── Submission Gate Logic ─────────────────────────────────────────────────

  /// Check if student can submit
  /// Blocked if: latest submission is PENDING/LATE_PENDING OR already PASSED
  bool get _canSubmit {
    if (_submissions.isEmpty) return true;
    final latest = _submissions.first;
    final isPending = latest.status == SubmissionStatus.pending ||
        latest.status == SubmissionStatus.latePending;
    final isPassed = latest.isPassed == true;
    return !isPending && !isPassed;
  }

  AssignmentSubmissionDetailDto? get _latestSubmission {
    return _submissions.isNotEmpty ? _submissions.first : null;
  }

  bool get _isPendingSubmission {
    if (_submissions.isEmpty) return false;
    final latest = _submissions.first;
    return latest.status == SubmissionStatus.pending ||
        latest.status == SubmissionStatus.latePending;
  }

  // ── File Picking ──────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Không thể chọn file: $e');
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final assignment = _assignment;
    if (assignment == null) return;

    final subType = assignment.submissionType;

    // Validate based on submission type
    if (subType == SubmissionType.text ||
        subType == SubmissionType.textAndFile) {
      if (_textController.text.trim().isEmpty) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Vui lòng nhập nội dung bài tập',
        );
        return;
      }
    }

    if (subType == SubmissionType.link ||
        subType == SubmissionType.linkAndFile) {
      if (_linkController.text.trim().isEmpty) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Vui lòng nhập đường dẫn',
        );
        return;
      }
      final url = _linkController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Đường dẫn không hợp lệ (phải bắt đầu bằng http:// hoặc https://)',
        );
        return;
      }
    }

    if (subType == SubmissionType.file ||
        subType == SubmissionType.textAndFile ||
        subType == SubmissionType.linkAndFile) {
      if (_selectedFile == null) {
        ErrorHandler.showWarningSnackBar(
          context,
          'Vui lòng chọn file để nộp',
        );
        return;
      }
    }

    // Confirm dialog
    final confirmed = await _showConfirmDialog(
      'Xác nhận nộp bài',
      'Bạn có chắc muốn nộp bài? Sau khi nộp không thể sửa.',
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      int? fileMediaId;

      // Upload file first if needed
      if (_selectedFile != null &&
          (subType == SubmissionType.file ||
              subType == SubmissionType.textAndFile ||
              subType == SubmissionType.linkAndFile)) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0;
        });

        fileMediaId = await _uploadFileWithProgress(_selectedFile!);

        setState(() => _isUploading = false);
      }

      // Build submission DTO
      final submission = AssignmentSubmissionCreateDto(
        submissionText:
            _textController.text.trim().isNotEmpty ? _textController.text.trim() : null,
        linkUrl:
            _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null,
        fileMediaId: fileMediaId,
      );

      await _assignmentService.submitAssignment(
        assignmentId: widget.assignmentId,
        submission: submission,
      );

      // Clear form
      _textController.clear();
      _linkController.clear();
      setState(() {
        _selectedFile = null;
        _isSubmitting = false;
      });

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, '✅ Nộp bài thành công!');
      }

      // Reload data
      await _loadData();

      if (widget.onSubmitted != null) {
        widget.onSubmitted!();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isUploading = false;
      });
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getErrorMessage(e),
        );
      }
    }
  }

  Future<int> _uploadFileWithProgress(PlatformFile file) async {
    if (file.path == null) {
      throw Exception('File không có đường dẫn');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!, filename: file.name),
    });

    final response = await Dio().post(
      'https://skillverse.vn/api/media/upload',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
      onSendProgress: (sent, total) {
        if (total > 0) {
          setState(() => _uploadProgress = sent / total);
        }
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['id'] as int;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  String _getSubmissionTypeLabel(SubmissionType? type) {
    switch (type) {
      case SubmissionType.text:
        return 'Nộp văn bản';
      case SubmissionType.link:
        return 'Nộp đường dẫn';
      case SubmissionType.file:
        return 'Nộp file';
      case SubmissionType.textAndFile:
        return 'Nộp văn bản + file';
      case SubmissionType.linkAndFile:
        return 'Nộp đường dẫn + file';
      default:
        return 'Nộp bài';
    }
  }

  String _getSubmissionTypeHint(SubmissionType? type) {
    switch (type) {
      case SubmissionType.text:
        return 'Nhập nội dung bài làm của bạn...';
      case SubmissionType.link:
        return 'Nhập đường dẫn (GitHub, Figma, Google Drive...)';
      case SubmissionType.file:
        return 'Chọn file để nộp (tài liệu, code, hình ảnh...)';
      case SubmissionType.textAndFile:
        return 'Nhập nội dung và đính kèm file';
      case SubmissionType.linkAndFile:
        return 'Nhập đường dẫn và đính kèm file minh chứng';
      default:
        return 'Nộp bài tập của bạn';
    }
  }

  IconData _getStatusIcon(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
      case SubmissionStatus.latePending:
        return Icons.hourglass_empty;
      case SubmissionStatus.graded:
      case SubmissionStatus.lateGraded:
        return Icons.check_circle;
      case SubmissionStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
        return AppTheme.warningColor;
      case SubmissionStatus.latePending:
        return Colors.orange;
      case SubmissionStatus.graded:
        return AppTheme.successColor;
      case SubmissionStatus.lateGraded:
        return AppTheme.successColor;
      case SubmissionStatus.rejected:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(SubmissionStatus? status) {
    switch (status) {
      case SubmissionStatus.pending:
        return 'Đang chờ chấm';
      case SubmissionStatus.latePending:
        return 'Nộp muộn - Đang chờ';
      case SubmissionStatus.graded:
        return 'Đã chấm';
      case SubmissionStatus.lateGraded:
        return 'Nộp muộn - Đã chấm';
      case SubmissionStatus.rejected:
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Inline mode: no Scaffold, embed directly in parent
    if (widget.isInline) {
      return _buildBody();
    }

    // Full-screen mode (standalone)
    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'Bài tập',
        onBack: () => Navigator.of(context).pop(),
        actions: [
          if (_submissions.isNotEmpty)
            IconButton(
              icon: Icon(_showHistory ? Icons.edit_note : Icons.history),
              onPressed: () => setState(() => _showHistory = !_showHistory),
              tooltip: _showHistory ? 'Xem bài nộp' : 'Lịch sử nộp bài',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return CommonLoading.center();

    if (_errorMessage != null) {
      return ErrorStateWidget(
        message: _errorMessage!,
        onRetry: _loadData,
      );
    }

    if (_assignment == null) {
      return const Center(child: Text('Không tìm thấy bài tập'));
    }

    if (_showHistory) {
      return _buildHistoryView();
    }

    return _buildSubmissionView();
  }

  Widget _buildSubmissionView() {
    final assignment = _assignment!;
    final latest = _latestSubmission;
    final subType = assignment.submissionType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Assignment header
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (assignment.description != null) ...[
                  const SizedBox(height: 8),
                  Text(assignment.description!),
                ],
                const SizedBox(height: 12),

                // Meta info
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (assignment.maxScore != null)
                      _buildMetaChip(
                        Icons.stars,
                        'Tối đa: ${assignment.maxScore} điểm',
                      ),
                    if (assignment.dueAt != null)
                      _buildMetaChip(
                        Icons.schedule,
                        'Hạn: ${DateTimeHelper.formatSmart(assignment.dueAt!)}',
                        color: _isOverdue(assignment.dueAt!)
                            ? AppTheme.errorColor
                            : null,
                      ),
                    _buildMetaChip(
                      Icons.upload_file,
                      _getSubmissionTypeLabel(subType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rubric criteria (shown before submission)
          if (assignment.criteria != null && assignment.criteria!.isNotEmpty) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tiêu chí chấm điểm',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...assignment.criteria!.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${c.maxPoints}đ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (c.description != null)
                                Text(
                                  c.description!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Latest submission result (if exists and is graded)
          if (latest != null && latest.status == SubmissionStatus.graded) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderColor: AppTheme.successColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kết quả chấm gần nhất',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Score
                  Row(
                    children: [
                      Text(
                        '${latest.score ?? 0}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: (latest.isPassed ?? false)
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      Text(
                        ' / ${assignment.maxScore ?? 100}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (latest.isLate == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Nộp muộn',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Status
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(latest.status),
                        size: 16,
                        color: _getStatusColor(latest.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusLabel(latest.status),
                        style: TextStyle(
                          color: _getStatusColor(latest.status),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Grading breakdown
                  if (latest.criteriaScores != null &&
                      latest.criteriaScores!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...latest.criteriaScores!.map((cs) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            cs.passed == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: cs.passed == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cs.criteriaName ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${cs.score ?? 0}/${cs.maxPoints ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],

                  // Feedback
                  if (latest.feedback != null &&
                      latest.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phản hồi từ Mentor',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latest.feedback!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  // Grader + time
                  if (latest.graderName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Chấm bởi ${latest.graderName} · ${latest.gradedAt != null ? DateTimeHelper.formatSmart(latest.gradedAt!) : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  // Submitted content preview
                  if (latest.submissionText != null ||
                      latest.linkUrl != null ||
                      latest.fileMediaUrl != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Nội dung đã nộp',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    if (latest.submissionText != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          latest.submissionText!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (latest.linkUrl != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.link, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              latest.linkUrl!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (latest.fileMediaUrl != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attachment, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'File đính kèm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Pending submission blocker
          if (_isPendingSubmission)
            _buildWarningBanner(
              Icons.hourglass_empty,
              'Bài nộp của bạn đang được xử lý. Vui lòng chờ mentor chấm điểm.',
              Colors.orange,
            ),

          // Submission form (if can submit)
          if (_canSubmit) ...[
            Text(
              'Nộp bài',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Text input
            if (subType == SubmissionType.text ||
                subType == SubmissionType.textAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _textController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Nội dung bài làm',
                    hintText: _getSubmissionTypeHint(subType),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Link input
            if (subType == SubmissionType.link ||
                subType == SubmissionType.linkAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    labelText: 'Đường dẫn',
                    hintText: _getSubmissionTypeHint(subType),
                    prefixIcon: const Icon(Icons.link),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // File picker
            if (subType == SubmissionType.file ||
                subType == SubmissionType.textAndFile ||
                subType == SubmissionType.linkAndFile) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Text(
                          'File đính kèm',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_selectedFile != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_selectedFile!.size > 0)
                                    Text(
                                      _formatFileSize(_selectedFile!.size),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  setState(() => _selectedFile = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Chọn file'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                    // Upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đang tải lên: ${(_uploadProgress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _isUploading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.themeOrangeStart,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting || _isUploading
                    ? CommonLoading.button()
                    : const Text(
                        'Nộp bài',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ] else if (latest?.isPassed == true) ...[
            // Already passed
            _buildSuccessBanner(
              'Bài tập đã hoàn thành!',
              'Bạn đã đạt yêu cầu và không thể nộp thêm.',
            ),
          ],

          const SizedBox(height: 24),

          // Toggle to history
          if (_submissions.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _showHistory = true),
              icon: const Icon(Icons.history),
              label: Text(
                'Xem lịch sử nộp bài (${_submissions.length})',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Chưa có bài nộp nào'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _showHistory = false),
              child: const Text('Quay lại nộp bài'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toggle back
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextButton.icon(
            onPressed: () => setState(() => _showHistory = false),
            icon: const Icon(Icons.edit_note),
            label: const Text('Quay lại bài nộp mới nhất'),
          ),
        ),

        // Submission timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              final sub = _submissions[index];
              return _buildSubmissionHistoryItem(sub, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionHistoryItem(
    AssignmentSubmissionDetailDto sub,
    int attemptNumber,
  ) {
    final statusColor = _getStatusColor(sub.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$attemptNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Line connector (only if not last)
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              borderColor: statusColor.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(sub.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusLabel(sub.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (sub.score != null)
                        Text(
                          '${sub.score}/${_assignment?.maxScore ?? 100}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (sub.isPassed ?? false)
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sub.submittedAt != null
                            ? DateTimeHelper.formatSmart(sub.submittedAt!)
                            : '—',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (sub.isLate == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Muộn',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Grader info
                  if (sub.graderName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Chấm bởi ${sub.graderName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  // Grading criteria
                  if (sub.criteriaScores != null &&
                      sub.criteriaScores!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...sub.criteriaScores!.map((cs) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            cs.passed == true
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 14,
                            color: cs.passed == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cs.criteriaName ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${cs.score ?? 0}/${cs.maxPoints ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],

                  // Feedback preview
                  if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: 12,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sub.feedback!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildMetaChip(IconData icon, String label, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.accentCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(IconData icon, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime dueAt) {
    return DateTime.now().isAfter(dueAt);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
