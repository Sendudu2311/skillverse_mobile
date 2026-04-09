import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/skeleton_loaders.dart';
import '../../themes/app_theme.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../../core/utils/number_formatter.dart';
import 'deposit_sheet.dart';
import 'buy_coin_sheet.dart';
import 'withdraw_sheet.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
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
      body: Consumer<WalletProvider>(
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
                ? '${provider.coinPercent.toStringAsFixed(1)}% tổng tài sản  ≈ ${_formatVnd(provider.coinValueInVnd)}'
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
    return Row(
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

  // ==================== STATS SECTION ====================

  Widget _buildStatsSection(
    BuildContext context,
    WalletProvider provider,
    bool isDark,
  ) {
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
        ...provider.transactions.map((tx) => _buildTransactionItem(tx, isDark)),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic tx, bool isDark) {
    final isCredit = tx.isCreditTransaction;
    final amount = tx.cashAmount ?? tx.coinAmount ?? 0;
    final sign = isCredit ? '+' : '-';
    final color = isCredit ? AppTheme.themeGreenStart : Colors.redAccent;
    final isCash = tx.cashAmount != null && tx.cashAmount != 0;

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
                  tx.description,
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
                  tx.createdAt.toString().substring(0, 10),
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
              Text(
                '$sign${isCash ? _formatVnd(amount.abs()) : '${NumberFormatter.formatNumber(amount.abs())} xu'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              _buildStatusChip(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        color = AppTheme.themeGreenStart;
        label = 'Hoàn thành';
        break;
      case 'PENDING':
        color = AppTheme.accentGold;
        label = 'Đang xử lý';
        break;
      case 'FAILED':
        color = Colors.redAccent;
        label = 'Thất bại';
        break;
      default:
        color = AppTheme.darkTextSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatVnd(int amount) {
    return NumberFormatter.formatCurrency(amount.toDouble(), currency: 'đ');
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'DEPOSIT':
      case 'DEPOSIT_CASH':
        return Icons.arrow_downward;
      case 'WITHDRAWAL':
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
        return Icons.refresh;
      default:
        return Icons.swap_horiz;
    }
  }
}
