import 'package:flutter/material.dart';
import '../../widgets/skeleton_loaders.dart';
import 'package:provider/provider.dart';
import '../../../data/models/payment_models.dart';
import '../../../core/utils/number_formatter.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/skillverse_app_bar.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/animated_list_item.dart';
import '../../themes/app_theme.dart';
import '../../widgets/status_badge.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final paymentProvider = context.read<PaymentProvider>();
    await paymentProvider.loadPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SkillVerseAppBar(title: 'Lịch sử thanh toán'),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading &&
              paymentProvider.paymentHistory.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => const ListItemSkeleton(hasTrailing: true),
            );
          }

          if (paymentProvider.errorMessage != null) {
            return ErrorStateWidget(
              message: paymentProvider.errorMessage!,
              onRetry: _loadHistory,
            );
          }

          final history = paymentProvider.paymentHistory;

          if (history.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'Chưa có giao dịch nào',
              subtitle: 'Các giao dịch thanh toán sẽ hiển thị ở đây',
              iconGradient: AppTheme.blueGradient,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final transaction = history[index];
                return AnimatedListItem(
                  index: index,
                  child: _PaymentHistoryCard(transaction: transaction),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentTransactionDto transaction;

  const _PaymentHistoryCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showTransactionDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTypeDisplayName(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description ?? 'Không có mô tả',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${NumberFormatter.formatAmount(transaction.amount)} ${transaction.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        status: transaction.status.name.toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPaymentMethodIcon(),
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getPaymentMethodName(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case PaymentType.premiumSubscription:
        icon = Icons.workspace_premium;
        color = Colors.amber;
        break;
      case PaymentType.coursePurchase:
        icon = Icons.school;
        color = Colors.blue;
        break;
      case PaymentType.walletTopup:
        icon = Icons.account_balance_wallet;
        color = Colors.green;
        break;
      case PaymentType.refund:
        icon = Icons.replay;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTypeDisplayName() {
    switch (transaction.type) {
      case PaymentType.premiumSubscription:
        return 'Đăng ký Premium';
      case PaymentType.coursePurchase:
        return 'Mua khóa học';
      case PaymentType.walletTopup:
        return 'Nạp tiền ví';
      case PaymentType.refund:
        return 'Hoàn tiền';
    }
  }

  IconData _getPaymentMethodIcon() {
    switch (transaction.paymentMethod) {
      case PaymentMethod.payos:
        return Icons.payment;
      case PaymentMethod.momo:
        return Icons.phone_android;
      case PaymentMethod.vnpay:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
    }
  }

  String _getPaymentMethodName() {
    switch (transaction.paymentMethod) {
      case PaymentMethod.payos:
        return 'PayOS';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.vnpay:
        return 'VNPay';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTransactionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: _buildTypeIcon()),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _getTypeDisplayName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: StatusBadge(
                    status: transaction.status.name.toUpperCase(),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  label: 'Số tiền',
                  value:
                      '${NumberFormatter.formatAmount(transaction.amount)} ${transaction.currency}',
                ),
                _DetailRow(
                  label: 'Mã giao dịch',
                  value: transaction.internalReference ?? 'N/A',
                ),
                _DetailRow(
                  label: 'Phương thức',
                  value: _getPaymentMethodName(),
                ),
                _DetailRow(
                  label: 'Mô tả',
                  value: transaction.description ?? 'Không có mô tả',
                ),
                _DetailRow(
                  label: 'Ngày tạo',
                  value: _formatDate(transaction.createdAt),
                ),
                _DetailRow(
                  label: 'Cập nhật',
                  value: _formatDate(transaction.updatedAt),
                ),
                if (transaction.failureReason != null)
                  _DetailRow(
                    label: 'Lý do thất bại',
                    value: transaction.failureReason!,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
