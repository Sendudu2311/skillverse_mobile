import 'package:flutter/material.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../data/models/wallet_models.dart';
import '../../../data/services/wallet_service.dart';
import '../../themes/app_theme.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_state_widget.dart';

/// Bottom sheet hiển thị lịch sử các yêu cầu rút tiền của người dùng.
/// Được mở từ WalletPage (nút "Lịch sử rút tiền").
class WithdrawalHistorySheet extends StatefulWidget {
  const WithdrawalHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WithdrawalHistorySheet(),
    );
  }

  @override
  State<WithdrawalHistorySheet> createState() => _WithdrawalHistorySheetState();
}

class _WithdrawalHistorySheetState extends State<WithdrawalHistorySheet> {
  final WalletService _service = WalletService();
  List<WithdrawalRequest> _items = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMore = true;
  int _page = 0;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 0;
    });
    try {
      final result = await _service.getWithdrawalHistory(page: 0, size: 20);
      if (mounted) {
        setState(() {
          _items = result;
          _isLoading = false;
          _hasMore = result.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải lịch sử rút tiền. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final next = await _service.getWithdrawalHistory(
        page: _page + 1,
        size: 20,
      );
      if (mounted) {
        setState(() {
          _items.addAll(next);
          _page++;
          _hasMore = next.length >= 20;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Lịch sử rút tiền',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadHistory,
      );
    }

    if (_items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Chưa có yêu cầu rút tiền',
        subtitle: 'Các yêu cầu rút tiền của bạn sẽ xuất hiện ở đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _WithdrawalTile(item: _items[index]);
        },
      ),
    );
  }
}

// ── Individual Tile ──────────────────────────────────────────────────────────

class _WithdrawalTile extends StatelessWidget {
  final WithdrawalRequest item;
  const _WithdrawalTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_statusIcon(item.status), color: statusColor, size: 20),
          ),

          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.requestCode?.isNotEmpty == true
                      ? 'Mã yêu cầu: ${item.requestCode}'
                      : 'Yêu cầu #${item.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCreatedAt(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                if (item.bankName.isNotEmpty ||
                    item.bankAccountNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${item.bankName}${item.bankAccountNumber.isNotEmpty ? ' ••${_last4(item.bankAccountNumber)}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.rejectionReason != null &&
                    item.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lý do từ chối: ${item.rejectionReason}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.errorColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Amount + status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_formatAmount(item.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(item.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }

  String _formatCreatedAt() {
    final createdAt = DateTimeHelper.tryParseIso8601(item.createdAt);
    if (createdAt == null) return 'Không rõ thời gian';
    return DateTimeHelper.formatSmart(createdAt);
  }

  String _last4(String value) {
    if (value.length <= 4) return value;
    return value.substring(value.length - 4);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PROCESSING':
        return Colors.blue;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'PROCESSING':
        return Icons.sync;
      case 'PENDING':
        return Icons.hourglass_top;
      case 'REJECTED':
        return Icons.cancel_outlined;
      case 'CANCELLED':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Đã duyệt';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'PENDING':
        return 'Chờ duyệt';
      case 'REJECTED':
        return 'Từ chối';
      case 'CANCELLED':
        return 'Đã huỷ';
      default:
        return status;
    }
  }
}
