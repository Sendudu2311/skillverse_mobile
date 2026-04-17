import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/number_formatter.dart';
import 'package:provider/provider.dart';
import '../../../data/models/contract_models.dart';
import '../../providers/contract_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/themed_scaffold.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../widgets/status_badge.dart';

class MyContractsPage extends StatefulWidget {
  const MyContractsPage({super.key});

  @override
  State<MyContractsPage> createState() => _MyContractsPageState();
}

class _MyContractsPageState extends State<MyContractsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ContractProvider>().loadMyContracts());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ThemedScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SkillVerseAppBar(
          title: 'Hợp đồng của tôi',
          onBack: () => context.pop(),
        ),
        body: Consumer<ContractProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingList) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => const ListItemSkeleton(lineCount: 3),
              );
            }

            if (provider.errorMessage != null) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                onRetry: () => provider.loadMyContracts(),
              );
            }

            if (provider.contracts.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.description_outlined,
                title: 'Chưa có hợp đồng',
                subtitle:
                    'Khi nhà tuyển dụng gửi hợp đồng cho bạn, nó sẽ xuất hiện ở đây.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadMyContracts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.contracts.length,
                itemBuilder: (context, index) =>
                    _buildContractCard(provider.contracts[index], isDark),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContractCard(ContractResponse contract, bool isDark) {
    final statusName = contract.status?.jsonValue ?? 'N/A';
    final salaryFormatted = contract.salary != null
        ? NumberFormatter.formatCurrency(contract.salary!, currency: '₫')
        : 'Chưa xác định';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/contracts/${contract.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: contract number + status
          Row(
            children: [
              const Icon(
                Icons.description,
                size: 18,
                color: AppTheme.primaryBlueDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contract.contractNumber ?? 'HĐ #${contract.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              StatusBadge(status: statusName),
            ],
          ),
          const SizedBox(height: 12),

          // Job title
          if (contract.jobTitle != null)
            Text(
              contract.jobTitle!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),

          // Company + type
          Row(
            children: [
              Icon(
                Icons.business,
                size: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  contract.employerCompanyName ??
                      contract.employerName ??
                      'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (contract.contractType != null)
                Text(
                  contract.contractType!.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentCyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Salary + dates
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 14,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 4),
              Text(
                salaryFormatted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
              const Spacer(),
              if (contract.startDate != null)
                Text(
                  _formatDate(contract.startDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
            ],
          ),

          // Action hint for pending contracts
          if (contract.status == ContractStatus.pendingSigner) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.themeBlueStart.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.themeBlueStart.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 16,
                    color: AppTheme.themeBlueStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cần xem xét và ký hợp đồng',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.themeBlueStart,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTimeHelper.tryParseIso8601(dateStr);
    return dt != null ? DateTimeHelper.formatDate(dt) : dateStr;
  }
}
