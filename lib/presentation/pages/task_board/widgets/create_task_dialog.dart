import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/task_board_models.dart';

/// Create Task Dialog
class CreateTaskDialog extends StatefulWidget {
  final String columnId;

  const CreateTaskDialog({super.key, required this.columnId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _startDate;
  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: isDark
          ? AppTheme.galaxyDark
          : AppTheme.lightCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        width: size.width * 0.9,
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.primaryBlueDark, AppTheme.accentCyan],
                      ).createShader(bounds),
                      child: const Text(
                        'NHIỆM VỤ MỚI',
                        style: TextStyle(
                          fontSize: 20,
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
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Name
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Tên Nhiệm Vụ',
                          prefixIcon: Icon(
                            Icons.task_alt,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên nhiệm vụ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Start Date
                      _buildSectionLabel('BẮT ĐẦU', Icons.calendar_today),
                      const SizedBox(height: 8),
                      _buildDatePicker(
                        context,
                        _startDate,
                        'dd/mm/yyyy, --:--',
                        (date) => setState(() => _startDate = date),
                      ),
                      const SizedBox(height: 16),

                      // Deadline
                      _buildSectionLabel('HẠN CHÓT', Icons.flag),
                      const SizedBox(height: 8),
                      _buildDatePicker(
                        context,
                        _deadline,
                        'dd/mm/yyyy, --:--',
                        (date) => setState(() => _deadline = date),
                      ),
                      const SizedBox(height: 16),

                      // Priority
                      _buildSectionLabel('ƯU TIÊN', Icons.flag),
                      const SizedBox(height: 8),
                      _buildPriorityDropdown(context),
                      const SizedBox(height: 20),

                      // Description
                      _buildSectionLabel('MÔ TẢ & TÀI NGUYÊN', Icons.edit),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(hintText: 'Chưa có mô tả'),
                      ),
                      const SizedBox(height: 16),

                      // Note
                      _buildSectionLabel(
                        'GHI CHÚ CÁ NHÂN',
                        Icons.sticky_note_2,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Suy ngẫm, trở ngại hoặc ghi chú nhanh...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('HỦY'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTask,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_task, size: 18),
                    label: const Text('TẠO NHIỆM VỤ'),
                  ),
                ],
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

  Widget _buildDatePicker(
    BuildContext context,
    DateTime? date,
    String placeholder,
    ValueChanged<DateTime> onDateSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    : placeholder,
                style: TextStyle(
                  fontSize: 14,
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
              size: 18,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority>(
          value: _priority,
          isExpanded: true,
          dropdownColor: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          items: [
            DropdownMenuItem(
              value: TaskPriority.low,
              child: Text('Thấp', style: TextStyle(color: Colors.green)),
            ),
            DropdownMenuItem(
              value: TaskPriority.medium,
              child: Text('Trung Bình', style: TextStyle(color: Colors.orange)),
            ),
            DropdownMenuItem(
              value: TaskPriority.high,
              child: Text('Cao', style: TextStyle(color: Colors.red)),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _priority = value);
            }
          },
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TaskBoardProvider>();

      final request = CreateTaskRequest(
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        userNotes: _noteController.text.isNotEmpty
            ? _noteController.text
            : null,
        priority: _priority.name.toUpperCase(),
        startDate: _startDate?.toIso8601String(),
        endDate: _deadline?.toIso8601String(),
        deadline: _deadline?.toIso8601String(),
        columnId: widget.columnId,
        linkedSessionIds: [],
      );

      await provider.createTask(request);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
