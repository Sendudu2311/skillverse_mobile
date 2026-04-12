import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/contract_models.dart';
import '../../providers/contract_provider.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/themed_scaffold.dart';
import '../../widgets/skillverse_app_bar.dart';

class ContractDetailPage extends StatefulWidget {
  final int contractId;

  const ContractDetailPage({super.key, required this.contractId});

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  static final _currencyFmt =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context
          .read<ContractProvider>()
          .loadContractDetail(widget.contractId),
    );
  }

  @override
  void dispose() {
    // Clear stale selection so next open doesn't flash old data
    context.read<ContractProvider>().clearSelection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SkillVerseAppBar(
          title: 'Chi tiết hợp đồng',
          onBack: () => context.pop(),
          actions: [
            Consumer<ContractProvider>(
              builder: (context, provider, _) {
                if (provider.selectedContract == null) return const SizedBox.shrink();
                
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'download') {
                      if (provider.isDownloadingPDF) return;
                      await provider.downloadPDF();
                      if (!context.mounted) return;
                      if (provider.lastSavedPdfPath != null) {
                        ErrorHandler.showSuccessSnackBar(context, 'Đã lưu PDF vào thư mục Downloads!');
                      } else {
                        ErrorHandler.showErrorSnackBar(context, 'Không thể lưu PDF. Vui lòng thử lại.');
                      }
                    } else if (value == 'share') {
                      if (provider.isSharingPDF) return;
                      await provider.sharePDF();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'download',
                      child: Row(
                        children: [
                          provider.isDownloadingPDF 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.download_rounded, color: AppTheme.primaryBlueDark, size: 20),
                          const SizedBox(width: 12),
                          Text(provider.isDownloadingPDF ? 'Đang tải...' : 'Tải PDF', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          provider.isSharingPDF
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.share_rounded, color: AppTheme.primaryBlueDark, size: 20),
                          const SizedBox(width: 12),
                          Text(provider.isSharingPDF ? 'Đang xử lý...' : 'Chia sẻ HĐ', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<ContractProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingDetail) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                onRetry: () =>
                    provider.loadContractDetail(widget.contractId),
              );
            }

            final contract = provider.selectedContract;
            if (contract == null) {
              return const Center(
                  child: Text('Không tìm thấy hợp đồng'));
            }

            return _buildBody(contract, isDark, provider);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    ContractResponse contract,
    bool isDark,
    ContractProvider provider,
  ) {
    final canAct = contract.status == ContractStatus.pendingSigner;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                provider.loadContractDetail(widget.contractId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(contract, isDark),
                const SizedBox(height: 12),
                _buildPartiesCard(contract, isDark),
                const SizedBox(height: 12),
                _buildCompensationCard(contract, isDark),
                const SizedBox(height: 12),
                if (_hasWorkingConditions(contract)) ...[
                  _buildWorkingConditionsCard(contract, isDark),
                  const SizedBox(height: 12),
                ],
                if (_hasBenefits(contract)) ...[
                  _buildBenefitsCard(contract, isDark),
                  const SizedBox(height: 12),
                ],
                if (_hasLegalClauses(contract)) ...[
                  _buildLegalCard(contract, isDark),
                  const SizedBox(height: 12),
                ],
                _buildSignaturesCard(contract, isDark),
                // Extra space for bottom action bar
                SizedBox(height: canAct ? 80 : 24),
              ],
            ),
          ),
        ),

        // Bottom action bar
        if (canAct) _buildBottomActions(contract, provider, isDark),
      ],
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeaderCard(ContractResponse contract, bool isDark) {
    final statusColor = _statusColor(contract.status);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.contractNumber ??
                          'HĐ #${contract.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (contract.contractType != null)
                      Text(
                        contract.contractType!.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  contract.status?.label ?? 'N/A',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (contract.jobTitle != null) ...[
            const SizedBox(height: 16),
            Text(
              contract.jobTitle!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ],
          if (contract.candidatePosition != null) ...[
            const SizedBox(height: 4),
            Text(
              'Vị trí: ${contract.candidatePosition}',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _infoChip(Icons.calendar_today,
                  _formatDate(contract.startDate), isDark),
              if (contract.endDate != null)
                _infoChip(Icons.event,
                    _formatDate(contract.endDate), isDark),
              if (contract.workingLocation != null)
                _infoChip(Icons.location_on_outlined,
                    contract.workingLocation!, isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PARTIES ====================

  Widget _buildPartiesCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Các bên hợp đồng',
      Icons.people_outline,
      isDark,
      children: [
        _sectionLabel('BÊN A — Nhà tuyển dụng', isDark),
        _infoRow('Tên', contract.employerName, isDark),
        _infoRow('Công ty', contract.employerCompanyName, isDark),
        _infoRow('Email', contract.employerEmail, isDark),
        if (contract.employerAddress != null)
          _infoRow('Địa chỉ', contract.employerAddress, isDark),
        const SizedBox(height: 12),
        _sectionLabel('BÊN B — Ứng viên', isDark),
        _infoRow('Tên', contract.candidateName, isDark),
        _infoRow('Email', contract.candidateEmail, isDark),
        if (contract.candidatePhone != null)
          _infoRow(
              'Điện thoại', contract.candidatePhone, isDark),
        if (contract.candidateAddress != null)
          _infoRow('Địa chỉ', contract.candidateAddress, isDark),
      ],
    );
  }

  // ==================== COMPENSATION ====================

  Widget _buildCompensationCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Chế độ lương thưởng',
      Icons.payments_outlined,
      isDark,
      children: [
        _infoRow(
          'Lương chính',
          contract.salary != null
              ? _currencyFmt.format(contract.salary)
              : null,
          isDark,
          valueColor: AppTheme.successColor,
        ),
        if (contract.salaryText != null)
          _infoRow('Bằng chữ', contract.salaryText, isDark),
        if (contract.salaryPaymentDate != null)
          _infoRow(
            'Ngày trả lương',
            'Ngày ${contract.salaryPaymentDate} hàng tháng',
            isDark,
          ),
        if (contract.paymentMethod != null)
          _infoRow('Hình thức', contract.paymentMethod, isDark),
        if (contract.probationSalary != null) ...[
          const SizedBox(height: 8),
          _sectionLabel('Thử việc', isDark),
          _infoRow(
            'Lương thử việc',
            _currencyFmt.format(contract.probationSalary),
            isDark,
          ),
          if (contract.probationMonths != null)
            _infoRow('Thời gian',
                '${contract.probationMonths} tháng', isDark),
        ],
        if (contract.mealAllowance != null ||
            contract.transportAllowance != null ||
            contract.housingAllowance != null) ...[
          const SizedBox(height: 8),
          _sectionLabel('Phụ cấp', isDark),
          if (contract.mealAllowance != null)
            _infoRow('Ăn trưa',
                _currencyFmt.format(contract.mealAllowance), isDark),
          if (contract.transportAllowance != null)
            _infoRow(
                'Đi lại',
                _currencyFmt
                    .format(contract.transportAllowance),
                isDark),
          if (contract.housingAllowance != null)
            _infoRow(
                'Nhà ở',
                _currencyFmt
                    .format(contract.housingAllowance),
                isDark),
        ],
        if (contract.otherAllowances != null)
          _infoRow(
              'Phụ cấp khác', contract.otherAllowances, isDark),
        if (contract.bonusPolicy != null)
          _infoRow('Thưởng', contract.bonusPolicy, isDark),
      ],
    );
  }

  // ==================== WORKING CONDITIONS ====================

  bool _hasWorkingConditions(ContractResponse c) =>
      c.workingHoursPerDay != null ||
      c.workingSchedule != null ||
      c.annualLeaveDays != null;

  Widget _buildWorkingConditionsCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Thời gian làm việc',
      Icons.schedule,
      isDark,
      children: [
        if (contract.workingHoursPerDay != null)
          _infoRow('Giờ/ngày',
              '${contract.workingHoursPerDay} giờ', isDark),
        if (contract.workingHoursPerWeek != null)
          _infoRow('Giờ/tuần',
              '${contract.workingHoursPerWeek} giờ', isDark),
        if (contract.workingSchedule != null)
          _infoRow(
              'Lịch làm việc', contract.workingSchedule, isDark),
        if (contract.remoteWorkPolicy != null)
          _infoRow(
              'Remote', contract.remoteWorkPolicy, isDark),
        if (contract.annualLeaveDays != null)
          _infoRow('Ngày phép',
              '${contract.annualLeaveDays} ngày/năm', isDark),
        if (contract.leavePolicy != null)
          _infoRow('Chính sách nghỉ', contract.leavePolicy, isDark),
      ],
    );
  }

  // ==================== BENEFITS ====================

  bool _hasBenefits(ContractResponse c) =>
      c.insurancePolicy != null ||
      c.trainingPolicy != null ||
      c.otherBenefits != null;

  Widget _buildBenefitsCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Phúc lợi & Bảo hiểm',
      Icons.health_and_safety,
      isDark,
      children: [
        if (contract.insurancePolicy != null)
          _infoRow('Bảo hiểm', contract.insurancePolicy, isDark),
        if (contract.healthCheckupAnnual == true)
          _infoRow(
              'Khám sức khỏe', 'Định kỳ hàng năm', isDark),
        if (contract.trainingPolicy != null)
          _infoRow('Đào tạo', contract.trainingPolicy, isDark),
        if (contract.otherBenefits != null)
          _infoRow(
              'Phúc lợi khác', contract.otherBenefits, isDark),
      ],
    );
  }

  // ==================== LEGAL ====================

  bool _hasLegalClauses(ContractResponse c) =>
      c.confidentialityClause != null ||
      c.nonCompeteClause != null ||
      c.terminationClause != null ||
      c.legalText != null;

  Widget _buildLegalCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Điều khoản pháp lý',
      Icons.gavel,
      isDark,
      children: [
        if (contract.confidentialityClause != null)
          _infoRow(
              'Bảo mật', contract.confidentialityClause, isDark),
        if (contract.ipClause != null)
          _infoRow(
              'Sở hữu trí tuệ', contract.ipClause, isDark),
        if (contract.nonCompeteClause != null) ...[
          _infoRow('Không cạnh tranh',
              contract.nonCompeteClause, isDark),
          if (contract.nonCompeteDurationMonths != null)
            _infoRow(
                'Thời hạn',
                '${contract.nonCompeteDurationMonths} tháng',
                isDark),
        ],
        if (contract.terminationNoticeDays != null)
          _infoRow(
            'Báo trước',
            '${contract.terminationNoticeDays} ngày',
            isDark,
          ),
        if (contract.terminationClause != null)
          _infoRow('Chấm dứt HĐ',
              contract.terminationClause, isDark),
        if (contract.legalText != null) ...[
          const SizedBox(height: 8),
          _sectionLabel('Điều khoản chung', isDark),
          Text(
            contract.legalText!,
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ==================== SIGNATURES ====================

  Widget _buildSignaturesCard(
      ContractResponse contract, bool isDark) {
    return _buildSectionCard(
      'Chữ ký',
      Icons.draw,
      isDark,
      children: [
        _buildSignatureSlot(
          'Bên A — Nhà tuyển dụng',
          contract.employerSignature,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildSignatureSlot(
          'Bên B — Ứng viên',
          contract.candidateSignature,
          isDark,
        ),
      ],
    );
  }

  Widget _buildSignatureSlot(
    String title,
    ContractSignatureResponse? sig,
    bool isDark,
  ) {
    final isSigned = sig?.status == 'SIGNED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black)
            .withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSigned
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : (isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSigned
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isSigned
                    ? AppTheme.successColor
                    : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (sig != null && sig.signedByName != null) ...[
            const SizedBox(height: 8),
            Text(
              '${sig.signedByName}${sig.signedAt != null ? ' · ${_formatDate(sig.signedAt)}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
          if (sig?.signatureImageUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Image.network(
                  sig!.signatureImageUrl!,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey),
                ),
              ),
            ),
          ],
          if (!isSigned)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Chưa ký',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== BOTTOM ACTIONS ====================

  Widget _buildBottomActions(
    ContractResponse contract,
    ContractProvider provider,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white)
            .withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () =>
                        _showRejectDialog(contract, provider),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Từ chối'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(
                      color: AppTheme.errorColor
                          .withValues(alpha: 0.5)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: provider.isSubmitting
                    ? null
                    : () => context.push(
                        '/contracts/${contract.id}/sign'),
                icon: const Icon(Icons.draw, size: 18),
                label: const Text('Ký hợp đồng'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REJECT DIALOG ====================

  Future<void> _showRejectDialog(
    ContractResponse contract,
    ContractProvider provider,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối hợp đồng?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Bạn có chắc muốn từ chối hợp đồng này không?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do (tùy chọn)',
                hintText: 'Nhập lý do từ chối...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      final success = await provider.rejectContract(
        contract.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã từ chối hợp đồng')),
        );
      } else if (!success &&
          mounted &&
          provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      }
    }
    reasonController.dispose();
  }

  // ==================== HELPERS ====================

  Widget _buildSectionCard(
    String title,
    IconData icon,
    bool isDark, {
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18, color: AppTheme.accentCyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.accentCyan,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Responsive info row: Column layout for long labels on small screens.
  Widget _infoRow(String label, String? value, bool isDark,
      {Color? valueColor}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use Column layout for long values (>60 chars) for better readability
    final useColumn = value.length > 60;

    if (useColumn) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 80,
              maxWidth: 110,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ??
                    (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(ContractStatus? status) {
    return switch (status) {
      ContractStatus.draft => Colors.grey,
      ContractStatus.pendingSigner =>
        AppTheme.themeBlueStart,
      ContractStatus.pendingEmployer =>
        AppTheme.themeOrangeStart,
      ContractStatus.signed => AppTheme.successColor,
      ContractStatus.rejected => AppTheme.errorColor,
      ContractStatus.cancelled => Colors.grey,
      null => Colors.grey,
    };
  }
}
