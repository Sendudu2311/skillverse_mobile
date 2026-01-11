import 'package:flutter/material.dart';
import '../../../../data/models/skin_models.dart';
import '../../../themes/app_theme.dart';

class PurchaseDialog extends StatelessWidget {
  final MeowlSkin skin;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const PurchaseDialog({
    super.key,
    required this.skin,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF1a1a2e) : Colors.white,
              isDark ? const Color(0xFF16213e) : Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorderColor
                : AppTheme.lightBorderColor,
          ),
        ),
        child: Row(
          children: [
            // Left - Skin image
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: skin.imageUrl != null
                    ? Image.network(
                        skin.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Right - Info
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content with padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'XÁC NHẬN GIAO DỊCH',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppTheme.primaryBlueDark,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Bạn có chắc chắn muốn sở hữu skin ',
                              ),
                              TextSpan(
                                text: skin.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlueDark,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    ' vào bộ sưu tập của mình? Hệ thống sẽ khấu trừ số dư tương ứng từ ví của bạn.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Price box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: skin.isFree
                                  ? [
                                      AppTheme.successColor.withOpacity(0.2),
                                      AppTheme.successColor.withOpacity(0.1),
                                    ]
                                  : [
                                      AppTheme.primaryBlueDark.withOpacity(0.2),
                                      AppTheme.primaryBlue.withOpacity(0.1),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: skin.isFree
                                  ? AppTheme.successColor.withOpacity(0.3)
                                  : AppTheme.primaryBlueDark.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            skin.isFree
                                ? 'MIỄN PHÍ'
                                : '₿ ${skin.price.toInt()}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: skin.isFree
                                  ? AppTheme.successColor
                                  : AppTheme.primaryBlueDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Buttons - full width without padding
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark
                                    ? AppTheme.darkBorderColor
                                    : AppTheme.lightBorderColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'HỦY BỎ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Confirm button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.primaryBlueDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'XÁC NHẬN\nMUA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.pets,
        size: 50,
        color: AppTheme.primaryBlueDark.withOpacity(0.5),
      ),
    );
  }
}
