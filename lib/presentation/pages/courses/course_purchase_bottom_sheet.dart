import 'package:flutter/material.dart';
import '../../../data/models/course_models.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/services/course_service.dart';
import '../../themes/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../widgets/common_loading.dart';

class CoursePurchaseBottomSheet extends StatefulWidget {
  final CourseDetailDto course;
  final String courseId;
  final double price;
  final bool isDark;
  final VoidCallback onWalletSuccess;
  final VoidCallback onPayOSSelected;

  const CoursePurchaseBottomSheet({
    super.key,
    required this.course,
    required this.courseId,
    required this.price,
    required this.isDark,
    required this.onWalletSuccess,
    required this.onPayOSSelected,
  });

  @override
  State<CoursePurchaseBottomSheet> createState() =>
      _CoursePurchaseBottomSheetState();
}

class _CoursePurchaseBottomSheetState
    extends State<CoursePurchaseBottomSheet> {
  final WalletService _walletService = WalletService();
  final CourseService _courseService = CourseService();

  bool _isLoadingWallet = true;
  bool _isPurchasing = false;
  int _walletBalance = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await _walletService.getMyWallet();
      if (mounted) {
        setState(() {
          _walletBalance = wallet.cashBalance;
          _isLoadingWallet = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWallet = false;
          _error = 'Không thể tải số dư ví';
        });
      }
    }
  }

  Future<void> _handleWalletPurchase() async {
    setState(() {
      _isPurchasing = true;
      _error = null;
    });

    try {
      await _courseService.purchaseCourseWithWallet(
        courseId: int.parse(widget.courseId),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onWalletSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = _walletBalance >= widget.price.toInt();
    final remaining = _walletBalance - widget.price.toInt();

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mua khóa học',
                    style: TextStyle(
                      color: widget.isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildCourseInfo(),
              const SizedBox(height: 16),

              _buildWalletSection(canAfford, remaining),
              const SizedBox(height: 12),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Wallet payment button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoadingWallet || _isPurchasing || !canAfford
                      ? null
                      : _handleWalletPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canAfford ? AppTheme.successColor : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canAfford ? 4 : 0,
                  ),
                  child: _isPurchasing
                      ? CommonLoading.small(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              canAfford
                                  ? Icons.account_balance_wallet
                                  : Icons.warning_amber_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              canAfford
                                  ? 'Thanh toán bằng Ví'
                                  : 'Số dư không đủ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // PayOS button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _isPurchasing
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onPayOSSelected();
                        },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.primaryBlueDark.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 18,
                        color: AppTheme.primaryBlueDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thanh toán qua PayOS',
                        style: TextStyle(
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isLoadingWallet && !canAfford) ...[
                const SizedBox(height: 10),
                Text(
                  'Vui lòng nạp thêm tiền vào ví hoặc dùng PayOS.',
                  style: TextStyle(
                    color: widget.isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    final imageUrl =
        widget.course.thumbnailUrl ?? widget.course.thumbnail?.url;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImage(),
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormatter.formatCurrency(widget.price, currency: 'đ'),
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() => Container(
        width: 60,
        height: 45,
        color: AppTheme.primaryBlueDark.withValues(alpha: 0.2),
        child: const Icon(Icons.school, color: Colors.white54, size: 20),
      );

  Widget _buildWalletSection(bool canAfford, int remaining) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Số dư ví',
                style: TextStyle(
                  color: widget.isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: widget.isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_isLoadingWallet)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CommonLoading.small(),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                NumberFormatter.formatCurrency(
                  _walletBalance.toDouble(),
                  currency: 'đ',
                ),
                style: TextStyle(
                  color: canAfford
                      ? (widget.isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary)
                      : AppTheme.errorColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _summaryRow(
              'Giá khóa học',
              NumberFormatter.formatCurrency(widget.price, currency: 'đ'),
            ),
            const SizedBox(height: 4),
            Divider(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 4),
            _summaryRow(
              'Số dư còn lại',
              NumberFormatter.formatCurrency(
                remaining.toDouble(),
                currency: 'đ',
              ),
              isBold: true,
              valueColor:
                  remaining >= 0 ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (widget.isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
