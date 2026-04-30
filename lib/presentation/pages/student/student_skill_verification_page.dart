import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/validation_helper.dart';
import '../../../data/models/student_skill_verification_models.dart';
import '../../providers/student_skill_verification_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/animated_success_overlay.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/common_loading.dart';

class StudentSkillVerificationPage extends StatefulWidget {
  const StudentSkillVerificationPage({super.key});

  @override
  State<StudentSkillVerificationPage> createState() =>
      _StudentSkillVerificationPageState();
}

class _StudentSkillVerificationPageState
    extends State<StudentSkillVerificationPage> {
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentSkillVerificationProvider>().loadVerifications();
    });
  }

  void _openSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<StudentSkillVerificationProvider>(),
        child: _SubmitVerificationSheet(
          onSuccess: () {
            setState(() => _showSuccess = true);
            context.read<StudentSkillVerificationProvider>().loadVerifications();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'XÁC THỰC KỸ NĂNG',
        icon: Icons.verified_outlined,
        useGradientTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            Consumer<StudentSkillVerificationProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (_, __) => const CardSkeleton(),
                  );
                }
                if (provider.hasError) {
                  return ErrorStateWidget(
                    message: provider.error!,
                    onRetry: () => provider.loadVerifications(),
                  );
                }
                if (provider.verifications.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.verified_outlined,
                    title: 'Chưa có yêu cầu xác thực',
                    subtitle:
                        'Gửi yêu cầu xác thực kỹ năng của bạn để nổi bật hơn trong portfolio.',
                    ctaLabel: 'Gửi yêu cầu xác thực',
                    onCtaPressed: _openSubmitSheet,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.loadVerifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: provider.verifications.length,
                    itemBuilder: (context, index) {
                      final item = provider.verifications[index];
                      return AnimatedListItem(
                        index: index,
                        child: _VerificationCard(
                          item: item,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_showSuccess)
              AnimatedSuccessOverlay(
                title: 'Đã gửi yêu cầu xác thực!',
                subtitle: 'Chúng tôi sẽ xét duyệt trong thời gian sớm nhất.',
                onClose: () => setState(() => _showSuccess = false),
              ),
          ],
        ),
      ),
      floatingActionButton: Consumer<StudentSkillVerificationProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading || provider.verifications.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: _openSubmitSheet,
            icon: const Icon(Icons.add),
            label: const Text('Gửi yêu cầu'),
            backgroundColor: AppTheme.primaryBlue,
          );
        },
      ),
    );
  }
}

// ── Verification Card ─────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  final StudentSkillVerificationResponse item;
  final bool isDark;

  const _VerificationCard({required this.item, required this.isDark});

  Color _statusColor(StudentSkillVerificationStatus status) {
    switch (status) {
      case StudentSkillVerificationStatus.approved:
        return AppTheme.successColor;
      case StudentSkillVerificationStatus.rejected:
        return AppTheme.errorColor;
      case StudentSkillVerificationStatus.pending:
        return AppTheme.themeOrangeStart;
    }
  }

  IconData _statusIcon(StudentSkillVerificationStatus status) {
    switch (status) {
      case StudentSkillVerificationStatus.approved:
        return Icons.verified;
      case StudentSkillVerificationStatus.rejected:
        return Icons.cancel_outlined;
      case StudentSkillVerificationStatus.pending:
        return Icons.hourglass_empty;
    }
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(item: item, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.skillName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                  ),
                ),
                StatusBadge.custom(
                  label: item.status.displayName,
                  color: color,
                  icon: _statusIcon(item.status),
                ),
              ],
            ),
            if (item.requestedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Gửi lúc: ${DateTimeHelper.formatDateTime(item.requestedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
            if (item.evidences.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.evidences
                    .map(
                      (e) => Chip(
                        label: Text(
                          e.evidenceType ?? 'Evidence',
                          style: const TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                        ),
                        labelStyle: TextStyle(
                          color: isDark
                              ? AppTheme.primaryBlueDark
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (item.status == StudentSkillVerificationStatus.rejected &&
                item.reviewNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.feedback_outlined,
                      size: 14,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.reviewNote!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final StudentSkillVerificationResponse item;
  final bool isDark;

  const _DetailSheet({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBorderColor
                        : AppTheme.lightBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.skillName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusBadge.custom(
                        label: item.status.displayName,
                        color: _statusColor(item.status),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (item.githubUrl != null) ...[
                        _InfoRow(
                          icon: Icons.code,
                          label: 'GitHub',
                          value: item.githubUrl!,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (item.portfolioUrl != null) ...[
                        _InfoRow(
                          icon: Icons.link,
                          label: 'Portfolio',
                          value: item.portfolioUrl!,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (item.additionalNotes != null) ...[
                        _InfoRow(
                          icon: Icons.notes,
                          label: 'Ghi chú',
                          value: item.additionalNotes!,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (item.reviewNote != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: item.status ==
                                    StudentSkillVerificationStatus.rejected
                                ? AppTheme.errorColor.withValues(alpha: 0.08)
                                : AppTheme.successColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.status ==
                                      StudentSkillVerificationStatus.rejected
                                  ? AppTheme.errorColor.withValues(alpha: 0.3)
                                  : AppTheme.successColor
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.feedback_outlined,
                                    size: 16,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Nhận xét từ Admin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.reviewNote!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (item.evidences.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'BẰNG CHỨNG (${item.evidences.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...item.evidences.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.article_outlined,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        e.evidenceType ?? 'Evidence',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (e.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      e.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(StudentSkillVerificationStatus status) {
    switch (status) {
      case StudentSkillVerificationStatus.approved:
        return AppTheme.successColor;
      case StudentSkillVerificationStatus.rejected:
        return AppTheme.errorColor;
      case StudentSkillVerificationStatus.pending:
        return AppTheme.themeOrangeStart;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Submit Verification Bottom Sheet ──────────────────────────────────────

class _SubmitVerificationSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const _SubmitVerificationSheet({required this.onSuccess});

  @override
  State<_SubmitVerificationSheet> createState() =>
      _SubmitVerificationSheetState();
}

class _SubmitVerificationSheetState extends State<_SubmitVerificationSheet> {
  final _formKey = GlobalKey<FormState>();

  final _skillNameCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _portfolioCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<_EvidenceRowData> _evidenceRows = [];

  @override
  void dispose() {
    _skillNameCtrl.dispose();
    _githubCtrl.dispose();
    _portfolioCtrl.dispose();
    _notesCtrl.dispose();
    for (final r in _evidenceRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addEvidence() {
    setState(() => _evidenceRows.add(_EvidenceRowData()));
  }

  void _removeEvidence(int index) {
    _evidenceRows[index].dispose();
    setState(() => _evidenceRows.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final evidences = _evidenceRows
        .where((r) => r.selectedType != null)
        .map(
          (r) => SkillEvidenceItem(
            evidenceType: r.selectedType!,
            evidenceUrl: r.urlCtrl.text.trim().isEmpty
                ? null
                : r.urlCtrl.text.trim(),
            description: r.descCtrl.text.trim().isEmpty
                ? null
                : r.descCtrl.text.trim(),
          ),
        )
        .toList();

    final request = CreateStudentSkillVerificationRequest(
      skillName: _skillNameCtrl.text.trim(),
      githubUrl: _githubCtrl.text.trim().isEmpty
          ? null
          : _githubCtrl.text.trim(),
      portfolioUrl: _portfolioCtrl.text.trim().isEmpty
          ? null
          : _portfolioCtrl.text.trim(),
      additionalNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      evidences: evidences,
    );

    final provider = context.read<StudentSkillVerificationProvider>();
    final ok = await provider.submit(request);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      ErrorDialog.showSimple(
        context,
        provider.error ?? 'Có lỗi xảy ra. Vui lòng thử lại.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<StudentSkillVerificationProvider>();

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBorderColor
                          : AppTheme.lightBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined),
                        const SizedBox(width: 8),
                        Text(
                          'GỬI YÊU CẦU XÁC THỰC KỸ NĂNG',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Skill name
                          TextFormField(
                            controller: _skillNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên kỹ năng *',
                              hintText: 'VD: Flutter, Python, React...',
                              prefixIcon:
                                  Icon(Icons.workspace_premium_outlined),
                            ),
                            validator: (v) =>
                                ValidationHelper.required(
                                  v,
                                  fieldName: 'Tên kỹ năng',
                                ) ??
                                ValidationHelper.maxLength(v, 100),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          // GitHub URL
                          TextFormField(
                            controller: _githubCtrl,
                            decoration: const InputDecoration(
                              labelText: 'GitHub URL',
                              hintText: 'https://github.com/...',
                              prefixIcon: Icon(Icons.code),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return ValidationHelper.githubRepoUrl(v);
                            },
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          // Portfolio URL
                          TextFormField(
                            controller: _portfolioCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Portfolio URL',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.link),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              return ValidationHelper.url(v);
                            },
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          // Additional notes
                          TextFormField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Ghi chú thêm',
                              hintText:
                                  'Mô tả kinh nghiệm của bạn với kỹ năng này...',
                              prefixIcon: Icon(Icons.notes),
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                ValidationHelper.maxLength(v, 2000),
                          ),
                          const SizedBox(height: 20),
                          // Evidence section header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'BẰNG CHỨNG BỔ SUNG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addEvidence,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Thêm'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          ..._evidenceRows.asMap().entries.map(
                                (entry) => _EvidenceFormRow(
                                  key: ValueKey(entry.key),
                                  rowData: entry.value,
                                  onRemove: () => _removeEvidence(entry.key),
                                  isDark: isDark,
                                  onTypeChanged: (_) => setState(() {}),
                                ),
                              ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: provider.isBusy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: provider.isBusy
                                  ? CommonLoading.small(color: Colors.white)
                                  : const Text(
                                      'Gửi yêu cầu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Evidence Row data ──────────────────────────────────────────────────────

class _EvidenceRowData {
  String? selectedType;
  final urlCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  void dispose() {
    urlCtrl.dispose();
    descCtrl.dispose();
  }
}

class _EvidenceFormRow extends StatelessWidget {
  final _EvidenceRowData rowData;
  final VoidCallback onRemove;
  final bool isDark;
  final ValueChanged<String?> onTypeChanged;

  const _EvidenceFormRow({
    super.key,
    required this.rowData,
    required this.onRemove,
    required this.isDark,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryBlue.withValues(alpha: 0.05)
            : AppTheme.primaryBlue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: rowData.selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loại bằng chứng *',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GITHUB', child: Text('GitHub')),
                    DropdownMenuItem(
                      value: 'CERTIFICATE',
                      child: Text('Chứng chỉ'),
                    ),
                    DropdownMenuItem(
                      value: 'PORTFOLIO_LINK',
                      child: Text('Portfolio Link'),
                    ),
                    DropdownMenuItem(
                      value: 'WORK_EXPERIENCE',
                      child: Text('Kinh nghiệm'),
                    ),
                  ],
                  onChanged: (v) {
                    rowData.selectedType = v;
                    onTypeChanged(v);
                  },
                  validator: (_) => rowData.selectedType == null
                      ? 'Chọn loại bằng chứng'
                      : null,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                color: AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: rowData.urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: rowData.descCtrl,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
