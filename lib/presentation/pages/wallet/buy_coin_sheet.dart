import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../widgets/common_loading.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/services/wallet_service.dart';

/// Coin package data model (matching backend CoinService)
class CoinPackage {
  final String id;
  final int coins;
  final int price;
  final int bonus;
  final int discount;
  final String title;
  final String description;
  final bool popular;
  final bool special;
  final Color color;

  const CoinPackage({
    required this.id,
    required this.coins,
    required this.price,
    required this.bonus,
    required this.discount,
    required this.title,
    required this.description,
    this.popular = false,
    this.special = false,
    required this.color,
  });

  int get totalCoins => coins + bonus;
}

/// Default coin packages (fallback, same as web BuyCoinModal)
const List<CoinPackage> _defaultPackages = [
  CoinPackage(
    id: 'starter',
    coins: 50,
    price: 4500,
    bonus: 5,
    discount: 10,
    title: 'Gói Khởi Đầu',
    description: 'Bắt đầu hành trình',
    color: Color(0xFF22D3EE),
  ),
  CoinPackage(
    id: 'popular',
    coins: 500,
    price: 40000,
    bonus: 75,
    discount: 20,
    title: 'Gói Phổ Biến',
    description: 'Giá trị tốt nhất',
    popular: true,
    color: Color(0xFFF59E0B),
  ),
  CoinPackage(
    id: 'premium',
    coins: 1000,
    price: 80000,
    bonus: 200,
    discount: 20,
    title: 'Gói Premium',
    description: 'Dành cho cao cấp',
    color: Color(0xFF7C3AED),
  ),
  CoinPackage(
    id: 'mega',
    coins: 2500,
    price: 190000,
    bonus: 600,
    discount: 24,
    title: 'Gói Mega',
    description: 'Sức mạnh vượt trội',
    color: Color(0xFF10B981),
  ),
  CoinPackage(
    id: 'ultimate',
    coins: 5000,
    price: 350000,
    bonus: 1500,
    discount: 30,
    title: 'Gói Ultimate',
    description: 'Đỉnh cao sức mạnh',
    special: true,
    color: Color(0xFFEC4899),
  ),
  CoinPackage(
    id: 'legendary',
    coins: 10000,
    price: 650000,
    bonus: 3500,
    discount: 35,
    title: 'Gói Huyền Thoại',
    description: 'Gói đặc biệt nhất',
    special: true,
    color: Color(0xFFF59E0B),
  ),
];

/// Bottom sheet for purchasing SkillCoins with wallet cash
class BuyCoinSheet extends StatefulWidget {
  final int currentCashBalance;
  final VoidCallback onSuccess;

  const BuyCoinSheet({
    super.key,
    required this.currentCashBalance,
    required this.onSuccess,
  });

  @override
  State<BuyCoinSheet> createState() => _BuyCoinSheetState();
}

class _BuyCoinSheetState extends State<BuyCoinSheet> {
  final _walletService = WalletService();

  CoinPackage? _selectedPackage;
  bool _isLoading = false;
  String? _error;

  Future<void> _handleBuy() async {
    if (_selectedPackage == null) {
      setState(() => _error = 'Vui lòng chọn gói xu');
      return;
    }

    if (widget.currentCashBalance < _selectedPackage!.price) {
      setState(() => _error = 'Số dư không đủ. Vui lòng nạp thêm tiền!');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _walletService.purchaseCoinsWithCash(
        coinAmount: _selectedPackage!.coins,
        packageId: _selectedPackage!.id,
      );

      if (!mounted) return;

      widget.onSuccess();
      Navigator.pop(context);
      ErrorHandler.showSuccessSnackBar(context, '🪙 Mua thành công ${_selectedPackage!.totalCoins} xu!');
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mua SkillCoin',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số dư: ${NumberFormatter.formatCurrency(widget.currentCashBalance.toDouble(), currency: 'đ')}',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Package list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _defaultPackages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pkg = _defaultPackages[index];
                return _buildPackageCard(pkg, isDark);
              },
            ),
          ),

          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

          // Summary & Buy button
          if (_selectedPackage != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gói:', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                      Text(_selectedPackage!.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nhận:', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                      Text(
                        '${NumberFormatter.formatNumber(_selectedPackage!.totalCoins)} xu',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số dư sau mua:', style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
                      Text(
                        NumberFormatter.formatCurrency((widget.currentCashBalance - _selectedPackage!.price).toDouble(), currency: 'đ'),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || widget.currentCashBalance < _selectedPackage!.price ? null : _handleBuy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? CommonLoading.small()
                          : const Text('🪙 Mua Ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedPackage == null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Chọn một gói xu để tiếp tục',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CoinPackage pkg, bool isDark) {
    final isSelected = _selectedPackage?.id == pkg.id;
    final canAfford = widget.currentCashBalance >= pkg.price;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = pkg;
          _error = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? pkg.color.withValues(alpha: 0.1)
              : (isDark ? AppTheme.darkBackgroundSecondary : AppTheme.lightBackgroundSecondary),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? pkg.color : (isDark ? AppTheme.darkBorderColor : AppTheme.lightBorderColor),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Coin icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: pkg.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.monetization_on, color: pkg.color, size: 28),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pkg.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      if (pkg.popular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🔥 HOT',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                        ),
                      ],
                      if (pkg.special) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✨ ĐẶC BIỆT',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumberFormatter.formatNumber(pkg.coins)} xu + ${pkg.bonus} thưởng',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormatter.formatCurrency(pkg.price.toDouble(), currency: 'đ'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: canAfford ? pkg.color : AppTheme.errorColor,
                  ),
                ),
                if (!canAfford)
                  Text(
                    'Không đủ',
                    style: TextStyle(fontSize: 10, color: AppTheme.errorColor),
                  ),
                if (pkg.discount > 0)
                  Text(
                    '-${pkg.discount}%',
                    style: TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
