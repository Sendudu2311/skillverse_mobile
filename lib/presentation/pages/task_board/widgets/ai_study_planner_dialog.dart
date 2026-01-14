import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/task_board_provider.dart';
import '../../../themes/app_theme.dart';
import '../../../../data/models/study_planner_models.dart';

/// AI Study Planner Dialog
class AIStudyPlannerDialog extends StatefulWidget {
  const AIStudyPlannerDialog({super.key});

  @override
  State<AIStudyPlannerDialog> createState() => _AIStudyPlannerDialogState();
}

class _AIStudyPlannerDialogState extends State<AIStudyPlannerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _topicsController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _durationController = TextEditingController(text: '600');
  final _breakController = TextEditingController(text: '15');

  DateTime _startDate = DateTime.now();
  DateTime _deadline = DateTime.now().add(const Duration(days: 90));
  String _studyMethod = 'POMODORO';
  String _chronotype = 'BEAR';
  bool _avoidLateNight = true;
  bool _allowLateNight = false;
  bool _isLoading = false;

  final List<String> _selectedDays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
  ];
  String _timeWindowStart = '09:00';
  String _timeWindowEnd = '17:00';

  final List<String> _topics = [];

  static const Map<String, String> studyMethods = {
    'POMODORO': 'Pomodoro (25/5)',
    'TIME_BLOCKING': 'Time Blocking',
    'SPACED_REPETITION': 'Spaced Repetition',
  };

  static const Map<String, String> chronotypes = {
    'BEAR': 'Gấu (Ngày)',
    'LION': 'Sư Tử (Sáng sớm)',
    'WOLF': 'Sói (Đêm)',
    'DOLPHIN': 'Cá Heo (Nhạy cảm)',
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _topicsController.dispose();
    _outcomeController.dispose();
    _durationController.dispose();
    _breakController.dispose();
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
        side: BorderSide(color: const Color(0xFFFFA500).withValues(alpha: 0.3)),
      ),
      child: Container(
        width: size.width * 0.95,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
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
                    Icons.smart_toy,
                    color: const Color(0xFFFFA500),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                          ).createShader(bounds),
                          child: const Text(
                            'AI STUDY PLANNER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFA500,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚡ MISTRAL LARGE (PREMIUM)',
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Section
                      _buildSectionHeader(
                        'THÔNG TIN CƠ BẢN',
                        Icons.info_outline,
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Môn Học / Chủ Đề Chính'),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          hintText: 'VD: Lập trình Java, IELTS Reading...',
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Các Chủ Đề Con (Nhấn Enter để thêm)'),
                      TextFormField(
                        controller: _topicsController,
                        decoration: const InputDecoration(
                          hintText: 'VD: OOP, Collections, Streams...',
                        ),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _topics.add(value);
                              _topicsController.clear();
                            });
                          }
                        },
                      ),
                      if (_topics.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _topics
                              .map(
                                (topic) => Chip(
                                  label: Text(
                                    topic,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () =>
                                      setState(() => _topics.remove(topic)),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      _buildLabel('Mục Tiêu Đầu Ra'),
                      TextFormField(
                        controller: _outcomeController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText:
                              'VD: Nắm vững kiến thức cơ bản và làm được bài tập...',
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Bắt buộc' : null,
                      ),
                      const SizedBox(height: 20),

                      // Time & Schedule Section
                      _buildSectionHeader(
                        'THỜI GIAN & LỊCH TRÌNH',
                        Icons.calendar_month,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Ngày Bắt Đầu'),
                                _buildDateButton(
                                  _startDate,
                                  (d) => setState(() => _startDate = d),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Hạn Chót (Deadline)'),
                                _buildDateButton(
                                  _deadline,
                                  (d) => setState(() => _deadline = d),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tổng Thời Gian (Phút)'),
                                TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Nghỉ Giữa Các Phiên (Phút)'),
                                TextFormField(
                                  controller: _breakController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildLabel('Ngày Học Ưu Tiên'),
                      _buildDaySelector(),
                      const SizedBox(height: 12),

                      _buildLabel('Khung Giờ Rảnh'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeButton(
                              _timeWindowStart,
                              (t) => setState(() => _timeWindowStart = t),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('-'),
                          ),
                          Expanded(
                            child: _buildTimeButton(
                              _timeWindowEnd,
                              (t) => setState(() => _timeWindowEnd = t),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Preferences Section
                      _buildSectionHeader('THÓI QUEN & SỞ THÍCH', Icons.tune),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Phương Pháp Học'),
                                _buildDropdown(
                                  _studyMethod,
                                  studyMethods,
                                  (v) => setState(() => _studyMethod = v!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Chronotype (Nhịp sinh học)'),
                                _buildDropdown(
                                  _chronotype,
                                  chronotypes,
                                  (v) => setState(() => _chronotype = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: _avoidLateNight,
                        onChanged: (v) => setState(() => _avoidLateNight = v!),
                        title: const Text(
                          'Tránh học khuya (sau 23h)',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFFFA500),
                      ),
                      CheckboxListTile(
                        value: _allowLateNight,
                        onChanged: (v) => setState(() => _allowLateNight = v!),
                        title: const Text(
                          'Cho phép học khuya nếu cần',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFFFA500),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
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
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateProposal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: Colors.black,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Tạo Đề Xuất Lịch Trình'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFFA500)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: Color(0xFFFFA500),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildDateButton(DateTime date, ValueChanged<DateTime> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: AppTheme.primaryBlueDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String time, ValueChanged<String> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final parts = time.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
        if (picked != null) {
          onChanged(
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                time,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            Icon(Icons.access_time, size: 16, color: AppTheme.primaryBlueDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const dayValues = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];

    return Wrap(
      spacing: 6,
      children: List.generate(7, (i) {
        final isSelected = _selectedDays.contains(dayValues[i]);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayValues[i]);
              } else {
                _selectedDays.add(dayValues[i]);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlueDark : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlueDark
                    : AppTheme.darkBorderColor,
              ),
            ),
            child: Text(
              days[i],
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.darkTextSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDropdown(
    String value,
    Map<String, String> items,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _generateProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<TaskBoardProvider>();

      final request = GenerateScheduleRequest(
        subjectName: _subjectController.text,
        topics: _topics.isEmpty ? [_subjectController.text] : _topics,
        desiredOutcome: _outcomeController.text,
        studyMethod: _studyMethod,
        startDate:
            '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        deadline:
            '${_deadline.year}-${_deadline.month.toString().padLeft(2, '0')}-${_deadline.day.toString().padLeft(2, '0')}',
        durationMinutes: int.tryParse(_durationController.text) ?? 600,
        breakMinutesBetweenSessions: int.tryParse(_breakController.text) ?? 15,
        preferredDays: _selectedDays,
        preferredTimeWindows: ['$_timeWindowStart-$_timeWindowEnd'],
        chronotype: _chronotype,
        avoidLateNight: _avoidLateNight,
        allowLateNight: _allowLateNight,
      );

      final sessions = await provider.generateProposal(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo ${sessions.length} phiên học!'),
            backgroundColor: Colors.green,
          ),
        );
        // Switch to Timeline view
        provider.setSelectedTab(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
