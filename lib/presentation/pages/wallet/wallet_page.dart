import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/wallet_models.dart';
import '../../../data/services/wallet_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/error_state_widget.dart';
import '../../../core/utils/number_formatter.dart';
import 'deposit_sheet.dart';
import 'buy_coin_sheet.dart';
import 'withdraw_sheet.dart';
import 'setup_wallet_sheet.dart';
import 'withdrawal_history_sheet.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletService _walletService = WalletService();
  final Set<int> _downloadingInvoices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SkillVerseAppBar(
        title: 'VÍ VŨ TRỤ',
        icon: Icons.account_balance_wallet,
        useGradientTitle: true,
        onBack: () => context.go('/dashboard'),
      ),
      body: SafeArea(
        top: false,
        child: Consumer<WalletProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return _buildSkeleton(isDark);
            }

            if (provider.errorMessage != null) {
              return ErrorStateWidget(
                message: provider.errorMessage!,
                onRetry: () => provider.refresh(),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance card
                    _buildBalanceSection(context, provider, isDark),
                    const SizedBox(height: 20),

                    // Warning Banner for missing PIN or Bank Account
                    _buildWarningBanner(context, provider, isDark),
                    const SizedBox(height: 10),

                    // Action buttons
                    _buildActionButtons(context, isDark),
                    const SizedBox(height: 28),

                    // Statistics
                    _buildStatsSection(context, provider, isDark),
                    const SizedBox(height: 28),

                    // Recent transactions
                    _buildTransactionsSection(context, provider, isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== SKELETON ====================

  Widget _buildSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CardSkeleton(imageHeight: 200),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: CardSkeleton(
                  imageHeight: 60,
                  hasSubtitle: false,
                  hasFooter: false,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: CardSkeleton(
                  imageHeight: 60,
                  hasSubtitle: false,
                  hasFooter: false,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: CardSkeleton(
                  imageHeight: 60,
                  hasSubtitle: false,
                  hasFooter: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const CardSkeleton(imageHeight: 160),
        ],
      ),
    );
  }

  // ==================== BALANCE SECTION ====================

  Widget _buildBalanceSection(
    BuildContext context,
    WalletProvider provider,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppTheme.primaryBlueDark.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with eye toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Số Dư Tài Khoản',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => provider.toggleBalance(),
                icon: Icon(
                  provider.showBalance
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: 20,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // KPI chips
          Row(
            children: [
              _buildKpiChip(
                'TIỀN MẶT',
                provider.showBalance
                    ? '${provider.cashPercent.toStringAsFixed(1)}%'
                    : '•••',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildKpiChip(
                'XU',
                provider.showBalance
                    ? '${provider.coinPercent.toStringAsFixed(1)}%'
                    : '•••',
                isDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiChip(
                  'TỔNG TÀI SẢN',
                  provider.showBalance
                      ? _formatVnd(provider.totalAssets)
                      : '••••••',
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cash balance
          _buildBalanceRow(
            icon: Icons.attach_money,
            label: 'Tiền Mặt',
            value: provider.showBalance
                ? _formatVnd(provider.cashBalance)
                : '••••••',
            percentText: provider.showBalance
                ? '${provider.cashPercent.toStringAsFixed(1)}% tổng tài sản'
                : null,
            color: AppTheme.themeGreenStart,
            isDark: isDark,
          ),
          const Divider(height: 24),

          // Coin balance
          _buildBalanceRow(
            icon: Icons.monetization_on,
            label: 'SkillCoin',
            value: provider.showBalance
                ? '${NumberFormatter.formatNumber(provider.coinBalance)} xu'
                : '••••••',
            percentText: provider.showBalance
                ? '${provider.coinPercent.toStringAsFixed(1)}% tổng tài sản  ≈ ${_formatVnd(provider.coinValueInVnd.toDouble())}'
                : null,
            color: AppTheme.accentGold,
            isDark: isDark,
          ),

          if (provider.showBalance) ...[
            const SizedBox(height: 16),
            // Total assets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueDark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 18,
                    color: AppTheme.themeGreenStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng tài sản:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatVnd(provider.totalAssets),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      fontFamily: 'monospace',
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

  Widget _buildKpiChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    String? percentText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (percentText != null) ...[
          const SizedBox(height: 6),
          Text(
            percentText,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    final provider = context.read<WalletProvider>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.add,
                label: 'Nạp tiền',
                color: AppTheme.themeGreenStart,
                onTap: () => _openDepositSheet(context, provider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.rocket_launch,
                label: 'Mua xu',
                color: AppTheme.themeOrangeStart,
                onTap: () => _openBuyCoinSheet(context, provider),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.remove,
                label: 'Rút tiền',
                color: AppTheme.errorColor,
                onTap: () => _openWithdrawSheet(context, provider),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Secondary row: Withdrawal history
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => WithdrawalHistorySheet.show(context),
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Lịch sử rút tiền'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _openDepositSheet(BuildContext context, WalletProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DepositSheet(onSuccess: () => provider.refresh()),
    );
  }

  void _openBuyCoinSheet(BuildContext context, WalletProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuyCoinSheet(
        currentCashBalance: provider.cashBalance,
        onSuccess: () => provider.refresh(),
      ),
    );
  }

  void _openWithdrawSheet(BuildContext context, WalletProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WithdrawSheet(
        currentCashBalance: provider.cashBalance,
        hasBankAccount: provider.hasBankAccount,
        onSuccess: () => provider.refresh(),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context, WalletProvider provider, bool isDark) {
    final needsPin = !provider.hasTransactionPin;
    final needsBank = !provider.hasBankAccount;

    if (!needsPin && !needsBank) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.themeOrangeStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.themeOrangeStart.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.themeOrangeStart, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yêu Cầu Thiết Lập Ví',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      needsPin && needsBank
                          ? 'Bạn chưa thiết lập tài khoản ngân hàng và mã PIN giao dịch. Hãy thiết lập để có thể rút tiền.'
                          : (needsPin
                              ? 'Bạn chưa thiết lập mã PIN giao dịch. Hãy thiết lập để bảo vệ các giao dịch rút tiền.'
                              : 'Bạn chưa thiết lập tài khoản ngân hàng liên kết. Hãy cập nhật để thực hiện rút tiền.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openSetupWalletSheet(context, provider, needsPin, needsBank),
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Thiết lập ngay'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.themeOrangeStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSetupWalletSheet(
    BuildContext context,
    WalletProvider provider,
    bool needsPin,
    bool needsBank,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetupWalletSheet(
        needsPin: needsPin,
        needsBank: needsBank,
        onSuccess: () => provider.refresh(),
      ),
    );
  }

  // ==================== STATS SECTION ====================

  Widget _buildStatsSection(
    BuildContext context,
    WalletProvider provider,
    bool isDark,
  ) {
    final categories = provider.transactionCategorySummaries;
    final weeklyFlow = provider.weeklyTransactionFlow;
    final hasWeeklyActivity = weeklyFlow.any(
      (point) => point.deposit > 0 || point.withdraw > 0 || point.coins > 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thống kê giao dịch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              icon: Icons.trending_up,
              label: 'TỔNG NẠP',
              value: _formatVnd(provider.statsTotalDeposited),
              color: AppTheme.themeGreenStart,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.trending_down,
              label: 'TỔNG RÚT',
              value: _formatVnd(provider.statsTotalWithdrawn),
              color: AppTheme.errorColor,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.account_balance,
              label: 'DÒNG TIỀN RÒNG',
              value: _formatVnd(provider.netCashFlow),
              color: AppTheme.themeBlueStart,
              isDark: isDark,
            ),
            _buildStatCard(
              icon: Icons.monetization_on,
              label: 'XU KIẾM ĐƯỢC',
              value:
                  '${NumberFormatter.formatNumber(provider.statsTotalCoinsEarned)} xu',
              color: AppTheme.accentGold,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildQuickStatsGrid(provider, isDark),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildCategoryBreakdown(categories, isDark),
        ],
        if (hasWeeklyActivity) ...[
          const SizedBox(height: 16),
          _buildWeeklyFlow(weeklyFlow, isDark),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsGrid(WalletProvider provider, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.15,
      children: [
        _buildMiniStatTile(
          icon: Icons.arrow_downward,
          label: 'Giao dịch nạp',
          value: NumberFormatter.formatNumber(provider.depositTransactionCount),
          color: AppTheme.themeGreenStart,
          isDark: isDark,
        ),
        _buildMiniStatTile(
          icon: Icons.arrow_upward,
          label: 'Giao dịch rút',
          value:
              NumberFormatter.formatNumber(provider.withdrawalTransactionCount),
          color: AppTheme.errorColor,
          isDark: isDark,
        ),
        _buildMiniStatTile(
          icon: Icons.savings_outlined,
          label: 'Xu đã chi',
          value:
              '${NumberFormatter.formatNumber(provider.statsTotalCoinsSpent)} xu',
          color: AppTheme.themePurpleStart,
          isDark: isDark,
        ),
        _buildMiniStatTile(
          icon: Icons.receipt_long_outlined,
          label: 'Tổng giao dịch',
          value: NumberFormatter.formatNumber(
            provider.statsTransactionCount > 0
                ? provider.statsTransactionCount
                : provider.transactions.length,
          ),
          color: AppTheme.themeBlueStart,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMiniStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'monospace',
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
  }

  Widget _buildCategoryBreakdown(
    List<WalletTransactionCategorySummary> categories,
    bool isDark,
  ) {
    final maxCount = categories.fold<int>(
      1,
      (max, category) => category.count > max ? category.count : max,
    );

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.accentCyan.withValues(alpha: 0.24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 18, color: AppTheme.accentCyan),
              const SizedBox(width: 8),
              Text(
                'Phân loại giao dịch',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (category) => _buildCategoryRow(category, maxCount, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    WalletTransactionCategorySummary category,
    int maxCount,
    bool isDark,
  ) {
    final color = _categoryColor(category.key);
    final progress = maxCount > 0 ? category.count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_categoryIcon(category.key), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category.count} GD',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCategoryAmount(category),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyFlow(
    List<WalletTransactionFlowPoint> weeklyFlow,
    bool isDark,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppTheme.themeBlueStart.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: AppTheme.themeBlueStart),
              const SizedBox(width: 8),
              Text(
                'Dòng tiền 7 ngày',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weeklyFlow
                  .map((point) => _buildFlowDay(point, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowDay(WalletTransactionFlowPoint point, bool isDark) {
    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          _buildFlowLine(
            'Nạp',
            point.deposit > 0 ? _formatVnd(point.deposit) : '0 đ',
            AppTheme.themeGreenStart,
          ),
          const SizedBox(height: 4),
          _buildFlowLine(
            'Rút',
            point.withdraw > 0 ? _formatVnd(point.withdraw) : '0 đ',
            AppTheme.errorColor,
          ),
          const SizedBox(height: 4),
          _buildFlowLine(
            'Xu',
            NumberFormatter.formatNumber(point.coins),
            AppTheme.accentGold,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowLine(String label, String value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== TRANSACTIONS SECTION ====================

  Widget _buildTransactionsSection(
    BuildContext context,
    WalletProvider provider,
    bool isDark,
  ) {
    if (provider.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 18, color: AppTheme.accentGold),
            const SizedBox(width: 6),
            Text(
              'Giao dịch gần đây',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...provider.recentTransactions.map(
          (tx) => _buildTransactionItem(tx, isDark),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx, bool isDark) {
    final isCredit = tx.cashAmount != null && tx.cashAmount != 0
        ? tx.isCreditTransaction
        : tx.isCoinCreditTransaction;
    final color = isCredit ? AppTheme.themeGreenStart : Colors.redAccent;
    // Prefer transactionTypeName for the label; fall back to description
    final label = tx.transactionTypeName?.isNotEmpty == true
        ? tx.transactionTypeName!
        : tx.description;
    final canDownloadInvoice = _canDownloadInvoice(tx);
    final isDownloadingInvoice = _downloadingInvoices.contains(tx.transactionId);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTransactionIcon(tx.transactionType),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.createdAt.length >= 10
                      ? tx.createdAt.substring(0, 10)
                      : tx.createdAt,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ..._buildTransactionAmountLines(tx),
              const SizedBox(height: 2),
              StatusBadge(status: tx.status),
              if (canDownloadInvoice) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: isDownloadingInvoice
                      ? null
                      : () => _downloadInvoice(tx.transactionId),
                  icon: isDownloadingInvoice
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentCyan,
                          ),
                        )
                      : const Icon(Icons.download_outlined, size: 14),
                  label: const Text('Hóa đơn'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatVnd(double amount) {
    return NumberFormatter.formatCurrency(amount, currency: 'đ');
  }

  String _formatCategoryAmount(WalletTransactionCategorySummary category) {
    final parts = <String>[];
    if (category.cashAmount > 0) {
      parts.add(_formatVnd(category.cashAmount));
    }
    if (category.coinAmount > 0) {
      parts.add('${NumberFormatter.formatNumber(category.coinAmount)} xu');
    }
    return parts.isEmpty ? '0 đ' : parts.join(' / ');
  }

  List<Widget> _buildTransactionAmountLines(WalletTransaction tx) {
    final lines = <Widget>[];
    final cashAmount = tx.cashAmount ?? 0;
    final coinAmount = tx.coinAmount ?? 0;

    if (cashAmount != 0) {
      final isCredit = tx.isCreditTransaction;
      lines.add(
        _buildAmountLine(
          '${isCredit ? '+' : '-'}${_formatVnd(cashAmount.abs())}',
          isCredit ? AppTheme.themeGreenStart : Colors.redAccent,
        ),
      );
    }

    if (coinAmount != 0) {
      final isCredit = tx.isCoinCreditTransaction;
      lines.add(
        _buildAmountLine(
          '${isCredit ? '+' : '-'}${NumberFormatter.formatNumber(coinAmount.abs())} xu',
          isCredit ? AppTheme.themeGreenStart : Colors.redAccent,
        ),
      );
    }

    if (lines.isEmpty) {
      lines.add(_buildAmountLine('0 đ', Colors.grey));
    }

    return lines;
  }

  Widget _buildAmountLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: 'monospace',
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'DEPOSIT':
      case 'DEPOSIT_CASH':
        return Icons.arrow_downward;
      case 'WITHDRAWAL':
      case 'WITHDRAWAL_CASH':
        return Icons.arrow_upward;
      case 'COIN_PURCHASE':
      case 'PURCHASE_COINS':
        return Icons.monetization_on;
      case 'COIN_EARN':
      case 'EARN_COINS':
        return Icons.card_giftcard;
      case 'COIN_SPEND':
      case 'SPEND_COINS':
        return Icons.flash_on;
      case 'REFUND':
      case 'REFUND_CASH':
        return Icons.replay;
      case 'MENTOR_BOOKING':
        return Icons.school_outlined;
      case 'JOB_POSTING_FEE':
        return Icons.work_outline;
      case 'ESCROW_HOLD':
        return Icons.lock_outline;
      case 'ESCROW_RELEASE':
        return Icons.lock_open_outlined;
      case 'JOB_PAYOUT':
        return Icons.payments_outlined;
      case 'ADMIN_ADJUSTMENT':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.swap_horiz;
    }
  }

  IconData _categoryIcon(WalletTransactionCategoryKey key) {
    switch (key) {
      case WalletTransactionCategoryKey.deposit:
        return Icons.arrow_downward;
      case WalletTransactionCategoryKey.withdrawal:
        return Icons.arrow_upward;
      case WalletTransactionCategoryKey.coinPurchase:
        return Icons.monetization_on;
      case WalletTransactionCategoryKey.premiumPurchase:
        return Icons.workspace_premium_outlined;
      case WalletTransactionCategoryKey.coursePurchase:
        return Icons.menu_book_outlined;
      case WalletTransactionCategoryKey.mentorTip:
        return Icons.volunteer_activism_outlined;
      case WalletTransactionCategoryKey.mentorIncome:
        return Icons.school_outlined;
      case WalletTransactionCategoryKey.jobPayout:
        return Icons.payments_outlined;
      case WalletTransactionCategoryKey.jobEscrow:
        return Icons.lock_outline;
      case WalletTransactionCategoryKey.refund:
        return Icons.replay;
      case WalletTransactionCategoryKey.coinReward:
        return Icons.card_giftcard;
      case WalletTransactionCategoryKey.adminAdjustment:
        return Icons.admin_panel_settings_outlined;
      case WalletTransactionCategoryKey.otherIncome:
        return Icons.add_circle_outline;
      case WalletTransactionCategoryKey.otherExpense:
        return Icons.remove_circle_outline;
    }
  }

  Color _categoryColor(WalletTransactionCategoryKey key) {
    switch (key) {
      case WalletTransactionCategoryKey.deposit:
      case WalletTransactionCategoryKey.mentorIncome:
      case WalletTransactionCategoryKey.jobPayout:
      case WalletTransactionCategoryKey.refund:
      case WalletTransactionCategoryKey.otherIncome:
        return AppTheme.themeGreenStart;
      case WalletTransactionCategoryKey.withdrawal:
      case WalletTransactionCategoryKey.jobEscrow:
      case WalletTransactionCategoryKey.otherExpense:
        return AppTheme.errorColor;
      case WalletTransactionCategoryKey.coinPurchase:
      case WalletTransactionCategoryKey.coinReward:
        return AppTheme.accentGold;
      case WalletTransactionCategoryKey.premiumPurchase:
      case WalletTransactionCategoryKey.mentorTip:
        return AppTheme.themePurpleStart;
      case WalletTransactionCategoryKey.coursePurchase:
      case WalletTransactionCategoryKey.adminAdjustment:
        return AppTheme.themeBlueStart;
    }
  }

  bool _canDownloadInvoice(WalletTransaction tx) {
    if (tx.status.toUpperCase() != 'COMPLETED') return false;

    const purchaseTypes = [
      'PURCHASE_PREMIUM',
      'PURCHASE_COINS',
      'PURCHASE_COURSE',
    ];
    final type = tx.transactionType.toUpperCase();
    return purchaseTypes.any(type.contains);
  }

  Future<void> _downloadInvoice(int transactionId) async {
    if (_downloadingInvoices.contains(transactionId)) return;

    setState(() => _downloadingInvoices.add(transactionId));
    try {
      final bytes = await _walletService.downloadTransactionInvoice(
        transactionId,
      );
      final path = await _saveInvoice(transactionId, bytes);

      if (!mounted) return;
      ErrorHandler.showSuccessSnackBar(
        context,
        'Đã tải hóa đơn: $path',
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _downloadingInvoices.remove(transactionId));
      }
    }
  }

  Future<String> _saveInvoice(int transactionId, List<int> bytes) async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getDownloadsDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final filename =
        'invoice-$transactionId-${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
