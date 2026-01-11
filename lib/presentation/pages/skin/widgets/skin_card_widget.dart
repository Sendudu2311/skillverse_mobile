import 'package:flutter/material.dart';
import '../../../../data/models/skin_models.dart';
import '../../../themes/app_theme.dart';

class SkinCard extends StatelessWidget {
  final MeowlSkin skin;
  final VoidCallback? onTap;
  final VoidCallback? onPurchase;
  final bool showPurchaseButton;

  const SkinCard({
    super.key,
    required this.skin,
    this.onTap,
    this.onPurchase,
    this.showPurchaseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCardBackground
              : AppTheme.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(),
            width: skin.selected ? 2 : 1,
          ),
          boxShadow: [
            if (skin.selected)
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rarity badge
            _buildRarityBadge(),

            // Skin image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    // Image
                    Center(
                      child: skin.imageUrl != null
                          ? Image.network(
                              skin.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),

                    // Owned indicator (centered overlay)
                    if (skin.owned)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, size: 16, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                'ĐÃ SỞ HỮU',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Name and price section
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    skin.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Price and action
                  Row(
                    children: [
                      // Price
                      Text(
                        skin.formattedPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getPriceColor(),
                        ),
                      ),
                      const Spacer(),

                      // Action button - only show if not owned
                      if (showPurchaseButton && !skin.owned)
                        GestureDetector(
                          onTap: onPurchase,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppTheme.primaryBlueDark,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'MUA NGAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlueDark,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _getRarityGradient()),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Text(
        skin.rarityText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.pets,
        size: 40,
        color: AppTheme.primaryBlueDark.withOpacity(0.5),
      ),
    );
  }

  Color _getBorderColor() {
    if (skin.selected) return AppTheme.successColor;
    switch (skin.rarity) {
      case SkinRarity.legendary:
        return Colors.amber;
      case SkinRarity.rare:
        return Colors.purple;
      case SkinRarity.common:
        return Colors.grey.withOpacity(0.3);
    }
  }

  List<Color> _getRarityGradient() {
    switch (skin.rarity) {
      case SkinRarity.legendary:
        return [Colors.amber.shade700, Colors.orange.shade600];
      case SkinRarity.rare:
        return [Colors.purple.shade700, Colors.purple.shade500];
      case SkinRarity.common:
        return [Colors.grey.shade600, Colors.grey.shade500];
    }
  }

  Color _getPriceColor() {
    if (skin.isFree) return AppTheme.successColor;
    if (skin.isPremium) return Colors.amber;
    return AppTheme.primaryBlueDark;
  }
}
