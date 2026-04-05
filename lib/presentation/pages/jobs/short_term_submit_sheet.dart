import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../../data/models/job_models.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/error_handler.dart';

/// Bottom sheet để Learner nộp bài (submit deliverables) cho short-term job.
class ShortTermSubmitSheet extends StatefulWidget {
  final int applicationId;
  final String jobTitle;
  final List<JobDeliverableResponse>? existingDeliverables;

  const ShortTermSubmitSheet({
    super.key,
    required this.applicationId,
    required this.jobTitle,
    this.existingDeliverables,
  });

  @override
  State<ShortTermSubmitSheet> createState() => _ShortTermSubmitSheetState();
}

class _ShortTermSubmitSheetState extends State<ShortTermSubmitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _workNoteController = TextEditingController();

  final List<_DeliverableField> _deliverables = [];
  bool _isFinalSubmission = false;

  static const _deliverableTypes = [
    ('LINK', 'Link', Icons.link),
    ('DOCUMENT', 'Tài liệu', Icons.description_outlined),
    ('IMAGE', 'Hình ảnh', Icons.image_outlined),
    ('VIDEO', 'Video', Icons.videocam_outlined),
    ('CODE', 'Code', Icons.code),
    ('FILE', 'File', Icons.attach_file),
    ('OTHER', 'Khác', Icons.folder_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _deliverables.add(_DeliverableField());
  }

  @override
  void dispose() {
    _workNoteController.dispose();
    for (final d in _deliverables) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDeliverable() {
    setState(() => _deliverables.add(_DeliverableField()));
  }

  void _removeDeliverable(int index) {
    setState(() {
      _deliverables[index].dispose();
      _deliverables.removeAt(index);
    });
  }

  /// Validate URL format — must start with http:// or https://
  String? _validateUrl(String? val, {bool required = false}) {
    final trimmed = val?.trim() ?? '';
    if (trimmed.isEmpty) {
      return required ? 'Vui lòng nhập ít nhất 1 link' : null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !trimmed.startsWith('http')) {
      return 'URL không hợp lệ (phải bắt đầu bằng https://)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validDeliverables = _deliverables
        .where((d) => d.urlController.text.trim().isNotEmpty)
        .map(
          (d) => DeliverablePayload(
            type: d.selectedType,
            fileName: d.nameController.text.trim().isEmpty
                ? d.urlController.text.trim()
                : d.nameController.text.trim(),
            fileUrl: d.urlController.text.trim(),
          ),
        )
        .toList();

    if (validDeliverables.isEmpty) {
      ErrorHandler.showWarningSnackBar(
        context,
        'Vui lòng thêm ít nhất 1 link bàn giao',
      );
      return;
    }

    final request = SubmitDeliverableRequest(
      applicationId: widget.applicationId,
      workNote: _workNoteController.text.trim().isEmpty
          ? null
          : _workNoteController.text.trim(),
      deliverables: validDeliverables,
      finalSubmission: _isFinalSubmission,
    );

    final provider = context.read<JobProvider>();
    final success = await provider.submitDeliverables(request);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ErrorHandler.showSuccessSnackBar(context, 'Đã nộp bài thành công!');
    } else {
      ErrorHandler.showErrorSnackBar(
        context,
        provider.errorMessage ?? 'Nộp bài thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.upload_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nộp bài',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.jobTitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      // ── Existing deliverables ──
                      if (widget.existingDeliverables != null &&
                          widget.existingDeliverables!.isNotEmpty) ...[
                        _buildSectionTitle('Đã nộp trước đó'),
                        const SizedBox(height: 8),
                        _buildExistingDeliverables(widget.existingDeliverables!),
                        const SizedBox(height: 20),
                      ],

                      // ── Work note ──
                      _buildSectionTitle('Ghi chú công việc'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _workNoteController,
                        maxLines: 4,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Mô tả những gì bạn đã hoàn thành...',
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── New deliverables ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Link bàn giao *'),
                          TextButton.icon(
                            onPressed: _addDeliverable,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Thêm',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.themeBlueStart,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      ...List.generate(
                        _deliverables.length,
                        (i) => _buildDeliverableRow(i),
                      ),

                      const SizedBox(height: 16),

                      // ── isFinalSubmission toggle ──
                      _buildFinalSubmissionToggle(),

                      // ── Final submission warning ──
                      if (_isFinalSubmission) ...[
                        const SizedBox(height: 12),
                        _buildFinalSubmissionWarning(),
                      ],

                      const SizedBox(height: 24),

                      // ── Submit button ──
                      Consumer<JobProvider>(
                        builder: (context, provider, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: provider.isSubmittingDeliverable
                                  ? null
                                  : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFinalSubmission
                                    ? AppTheme.themeGreenStart
                                    : AppTheme.themePurpleStart,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: provider.isSubmittingDeliverable
                                  ? CommonLoading.button()
                                  : Text(
                                      _isFinalSubmission
                                          ? 'Nộp bài lần cuối'
                                          : 'Nộp bài',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Section title helper ──
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  // ── Existing deliverables display ──
  Widget _buildExistingDeliverables(List<JobDeliverableResponse> deliverables) {
    return Column(
      children: deliverables.map((d) {
        final icon = _iconForType(d.type ?? 'LINK');
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.themePurpleStart.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.themePurpleStart.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.themePurpleStart),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.fileName ?? d.fileUrl ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.description != null && d.description!.isNotEmpty)
                      Text(
                        d.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Deliverable input row ──
  Widget _buildDeliverableRow(int index) {
    final d = _deliverables[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Type + remove
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: d.selectedType,
                    isExpanded: true,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: _deliverableTypes.map((t) {
                      return DropdownMenuItem(
                        value: t.$1,
                        child: Row(
                          children: [
                            Icon(t.$3, size: 16),
                            const SizedBox(width: 6),
                            Text(t.$2, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => d.selectedType = val);
                    },
                  ),
                ),
              ),
              if (_deliverables.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeDeliverable(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // URL (with validation)
          TextFormField(
            controller: d.urlController,
            decoration: const InputDecoration(
              labelText: 'URL / Link *',
              hintText: 'https://...',
              isDense: true,
            ),
            keyboardType: TextInputType.url,
            validator: (val) => _validateUrl(val, required: index == 0),
          ),
          const SizedBox(height: 8),

          // File name (optional)
          TextFormField(
            controller: d.nameController,
            decoration: const InputDecoration(
              labelText: 'Tên file / mô tả (tùy chọn)',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── isFinalSubmission checkbox row ──
  Widget _buildFinalSubmissionToggle() {
    return InkWell(
      onTap: () => setState(() => _isFinalSubmission = !_isFinalSubmission),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isFinalSubmission
              ? AppTheme.themeGreenStart.withValues(alpha: 0.08)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFinalSubmission
                ? AppTheme.themeGreenStart.withValues(alpha: 0.3)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _isFinalSubmission,
              onChanged: (val) =>
                  setState(() => _isFinalSubmission = val ?? false),
              activeColor: AppTheme.themeGreenStart,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đây là lần nộp cuối cùng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _isFinalSubmission
                          ? AppTheme.themeGreenStart
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    'Đánh dấu khi bạn đã hoàn thành toàn bộ công việc',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Final submission warning banner ──
  Widget _buildFinalSubmissionWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.themeOrangeStart.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.themeOrangeStart,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sau khi nộp, bạn sẽ không thể chỉnh sửa trừ khi nhà tuyển dụng yêu cầu sửa lại.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.themeOrangeStart,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Icon helper for deliverable type ──
  IconData _iconForType(String type) {
    return switch (type.toUpperCase()) {
      'IMAGE' => Icons.image_outlined,
      'VIDEO' => Icons.videocam_outlined,
      'DOCUMENT' => Icons.description_outlined,
      'CODE' => Icons.code,
      'LINK' => Icons.link,
      _ => Icons.attach_file,
    };
  }
}

class _DeliverableField {
  String selectedType = 'LINK';
  final TextEditingController urlController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  void dispose() {
    urlController.dispose();
    nameController.dispose();
  }
}
