import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../widgets/common_loading.dart';
import '../../../../data/models/task_board_models.dart';

/// Task Detail Bottom Sheet — Create / Edit / Delete
/// Mirrors web TaskDetailModal.tsx
class TaskDetailSheet extends StatefulWidget {
  final Task? task; // null = create mode
  final String columnId;

  const TaskDetailSheet({super.key, this.task, required this.columnId});

  /// Show the sheet
  static Future<void> show(
    BuildContext context, {
    Task? task,
    required String columnId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: task, columnId: columnId),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  DateTime? _startDate;
  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;
  double _progress = 0;
  String _satisfaction = 'Neutral';
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.userNotes ?? '');
    _startDate = t?.startDate;
    _deadline = t?.deadline;
    _priority = t?.priority ?? TaskPriority.medium;
    _progress = (t?.userProgress ?? 0).toDouble();
    _satisfaction = t?.satisfactionLevel ?? 'Neutral';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.galaxyDark : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(isDark),
          Flexible(child: _buildFormContent(isDark)),
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit_note : Icons.add_task,
            color: AppTheme.primaryBlueDark,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
              ).createShader(bounds),
              child: Text(
                isEditMode ? 'CHI TIẾT NHIỆM VỤ' : 'NHIỆM VỤ MỚI',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.close,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Tên Nhiệm Vụ',
                prefixIcon: Icon(
                  Icons.task_alt,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Vui lòng nhập tên nhiệm vụ'
                  : null,
            ),
            const SizedBox(height: 16),

            // Start / Deadline
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'BẮT ĐẦU',
                    Icons.calendar_today,
                    _startDate,
                    (d) => setState(() => _startDate = d),
                    lastDate: _deadline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'HẠN CHÓT',
                    Icons.flag,
                    _deadline,
                    (d) => setState(() => _deadline = d),
                    firstDate: _startDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Priority
            _buildSectionLabel('ƯU TIÊN', Icons.flag),
            const SizedBox(height: 8),
            _buildPrioritySelector(isDark),
            const SizedBox(height: 16),

            // Progress (edit mode only)
            if (isEditMode) ...[
              _buildSectionLabel(
                'TIẾN ĐỘ: ${_progress.toInt()}%',
                Icons.trending_up,
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.primaryBlueDark,
                  thumbColor: AppTheme.accentCyan,
                  inactiveTrackColor: AppTheme.primaryBlueDark.withValues(
                    alpha: 0.2,
                  ),
                ),
                child: Slider(
                  value: _progress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_progress.toInt()}%',
                  onChanged: (v) => setState(() => _progress = v),
                ),
              ),
              const SizedBox(height: 12),

              // Satisfaction
              _buildSectionLabel('MỨC ĐỘ HÀI LÒNG', Icons.mood),
              const SizedBox(height: 8),
              _buildSatisfactionPicker(isDark),
              const SizedBox(height: 16),
            ],

            // Description
            _buildSectionLabel('MÔ TẢ & TÀI NGUYÊN', Icons.edit),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết, liên kết học liệu...',
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            _buildSectionLabel('GHI CHÚ CÁ NHÂN', Icons.sticky_note_2),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Suy ngẫm, trở ngại hoặc ghi chú nhanh...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryBlueDark),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: AppTheme.primaryBlueDark,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    IconData icon,
    DateTime? date,
    ValueChanged<DateTime> onPicked, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, icon),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? (firstDate ?? DateTime.now()),
              firstDate:
                  firstDate ??
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate:
                  lastDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? AppTheme.darkBorderColor
                    : AppTheme.lightBorderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'dd/mm/yyyy',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: date != null
                          ? (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary)
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = p == _priority;
        final color = _colorForPriority(p);
        final label = _labelForPriority(p);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppTheme.darkBorderColor
                            : AppTheme.lightBorderColor),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSatisfactionPicker(bool isDark) {
    const levels = [
      ('Satisfied', Icons.sentiment_satisfied, 'Hài lòng'),
      ('Neutral', Icons.sentiment_neutral, 'Bình thường'),
      ('Unsatisfied', Icons.sentiment_dissatisfied, 'Chưa hài lòng'),
    ];

    return Row(
      children: levels.map((item) {
        final isSelected = _satisfaction == item.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _satisfaction = item.$1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlueDark.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlueDark
                      : (isDark
                            ? AppTheme.darkBorderColor
                            : AppTheme.lightBorderColor),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    item.$2,
                    size: 22,
                    color: isSelected
                        ? AppTheme.primaryBlueDark
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$3,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: isSelected
                          ? AppTheme.primaryBlueDark
                          : (isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Delete button (edit mode)
          if (isEditMode)
            TextButton.icon(
              onPressed: _isDeleting ? null : _deleteTask,
              icon: _isDeleting
                  ? CommonLoading.small()
                  : const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveTask,
            icon: _isSaving
                ? CommonLoading.small()
                : Icon(isEditMode ? Icons.save : Icons.add_task, size: 18),
            label: Text(isEditMode ? 'Lưu' : 'Tạo'),
          ),
        ],
      ),
    );
  }

  // === Actions ===

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate date logic
    if (_startDate != null && _deadline != null) {
      if (_deadline!.isBefore(_startDate!)) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Hạn chót không được trước ngày bắt đầu!',
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final provider = context.read<TaskBoardProvider>();
    final navigator = Navigator.of(context);

    try {
      if (isEditMode) {
        final request = UpdateTaskRequest(
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          startDate: _startDate?.toIso8601String(),
          endDate: _deadline?.toIso8601String(),
          deadline: _deadline?.toIso8601String(),
          priority: _priority.name.toUpperCase(),
          userProgress: _progress.toInt(),
          satisfactionLevel: _satisfaction,
          userNotes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );
        await provider.updateTask(widget.task!.id, request);
      } else {
        final request = CreateTaskRequest(
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          startDate: _startDate?.toIso8601String(),
          endDate: _deadline?.toIso8601String(),
          deadline: _deadline?.toIso8601String(),
          priority: _priority.name.toUpperCase(),
          userNotes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
          columnId: widget.columnId,
        );
        await provider.createTask(request);
      }

      if (mounted) {
        navigator.pop();
        ErrorHandler.showSuccessSnackBar(
          context,
          isEditMode ? 'Đã cập nhật nhiệm vụ!' : 'Đã tạo nhiệm vụ mới!',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTask() async {
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhiệm vụ'),
        content: const Text('Bạn có chắc chắn muốn xóa nhiệm vụ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _isDeleting = true);

    try {
      final provider = context.read<TaskBoardProvider>();
      await provider.deleteTask(widget.task!.id);
      if (mounted) {
        navigator.pop();
        ErrorHandler.showSuccessSnackBar(context, 'Đã xóa nhiệm vụ!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // === Helpers ===

  Color _colorForPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String _labelForPriority(TaskPriority p) {
    switch (p) {
      case TaskPriority.high:
        return 'CAO';
      case TaskPriority.medium:
        return 'TB';
      case TaskPriority.low:
        return 'THẤP';
    }
  }
}
