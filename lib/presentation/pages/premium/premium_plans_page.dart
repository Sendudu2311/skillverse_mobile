import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/premium_models.dart';
import '../../../data/models/payment_models.dart';
import '../../../core/utils/number_formatter.dart';
import '../../providers/premium_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../payment/payment_webview_page.dart';
import 'subscription_management_sheet.dart';

class PremiumPlansPage extends StatefulWidget {
  const PremiumPlansPage({super.key});

  @override
  State<PremiumPlansPage> createState() => _PremiumPlansPageState();
}

class _PremiumPlansPageState extends State<PremiumPlansPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PremiumProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: AppTheme.accentGold, size: 28),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.accentGold, AppTheme.themeOrangeStart],
              ).createShader(bounds),
              child: const Text(
                'PREMIUM',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.availablePlans.isEmpty) {
            return _buildSkeleton(isDark);
          }

          if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty) {
            return _buildError(context, provider, isDark);
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current subscription banner
                  if (provider.currentSubscription != null &&
                      provider.currentSubscription!.isActive)
                    _buildCurrentSubscriptionBanner(
                      context, provider, isDark,
                    ),

                  // Header text
                  if (provider.currentSubscription == null ||
                      !provider.currentSubscription!.isActive) ...[
                    _buildPromoHeader(isDark),
                    const SizedBox(height: 24),
                  ],

                  // Plan cards
                  ...provider.displayPlans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PlanCard(
                      plan: plan,
                      isCurrentPlan: provider.currentSubscription != null &&
                          provider.currentSubscription!.plan.id == plan.id,
                      hasActivePlan: provider.hasPremium,
                      onPayOS: () => _handlePayOS(plan),
                      onWallet: () => _handleWalletPay(plan),
                    ),
                  )),

                  const SizedBox(height: 16),

                  // Benefits section
                  _buildBenefitsSection(isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildPromoHeader(bool isDark) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentGold.withValues(alpha: 0.15),
              AppTheme.themeOrangeStart.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.accentGold, size: 48),
            const SizedBox(height: 12),
            Text(
              'Nâng Cấp Premium',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Truy cập không giới hạn khóa học, AI Chatbot & Roadmap cá nhân hóa',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CURRENT SUBSCRIPTION ====================

  Widget _buildCurrentSubscriptionBanner(
    BuildContext context,
    PremiumProvider provider,
    bool isDark,
  ) {
    final sub = provider.currentSubscription!;
    final daysLeft = sub.daysRemaining ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.successColor.withValues(alpha: 0.15),
                AppTheme.themeGreenStart.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified, color: AppTheme.successColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.plan.displayName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Còn $daysLeft ngày',
                              style: TextStyle(
                                fontSize: 13,
                                color: daysLeft <= 7
                                    ? AppTheme.errorColor
                                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                fontWeight: daysLeft <= 7 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Auto-renewal info
              Row(
                children: [
                  Icon(
                    sub.autoRenew == true ? Icons.repeat : Icons.repeat_one,
                    size: 16,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sub.autoRenew == true ? 'Tự động gia hạn' : 'Không tự động gia hạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openManagementSheet(context),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Quản lý', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentCyan,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BENEFITS ====================

  Widget _buildBenefitsSection(bool isDark) {
    const benefits = [
      _Benefit(Icons.school, 'Truy cập tất cả khóa học', 'Học không giới hạn mọi chủ đề'),
      _Benefit(Icons.psychology, 'AI Chatbot & Roadmap', 'Trợ lý AI cá nhân hóa lộ trình'),
      _Benefit(Icons.verified, 'Chứng chỉ hoàn thành', 'Chứng nhận chính thức khi tốt nghiệp'),
      _Benefit(Icons.support_agent, 'Hỗ trợ ưu tiên', 'Phản hồi nhanh từ đội ngũ hỗ trợ'),
    ];

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✨ Lợi ích Premium',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(b.icon, color: AppTheme.accentGold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          b.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ==================== SKELETON/ERROR ====================

  Widget _buildSkeleton(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildError(BuildContext context, PremiumProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PAYMENT ACTIONS ====================

  Future<void> _handlePayOS(PremiumPlanDto plan) async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final paymentProvider = context.read<PaymentProvider>();
    const successUrl = 'https://skillverse.vn/payment/transactional';
    const cancelUrl = 'https://skillverse.vn/payment/transactional?cancel=1';

    final paymentResponse = await paymentProvider.createPayment(
      amount: plan.price,
      type: PaymentType.premiumSubscription,
      paymentMethod: PaymentMethod.payos,
      description: 'Đăng ký gói ${plan.displayName}',
      planId: plan.id,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
    );

    if (mounted) Navigator.pop(context); // close loading

    if (paymentResponse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage ?? 'Lỗi tạo thanh toán'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentWebViewPage(
          checkoutUrl: paymentResponse.checkoutUrl,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
        ),
      ),
    );

    if (!mounted) return;

    // Refresh regardless — backend PayOS callback handles activation
    final premiumProvider = context.read<PremiumProvider>();
    await premiumProvider.loadAll();

    if (!mounted) return;
    final isSuccess = result != null && result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSuccess
            ? '🎉 Đăng ký Premium thành công!'
            : '⏳ Đang xử lý thanh toán...'),
        backgroundColor: isSuccess ? AppTheme.successColor : AppTheme.accentCyan,
      ),
    );
  }

  Future<void> _handleWalletPay(PremiumPlanDto plan) async {
    if (!mounted) return;

    // Ensure wallet is loaded before showing dialog
    final walletProvider = context.read<WalletProvider>();
    await walletProvider.refresh();

    if (!mounted) return;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final balance = walletProvider.cashBalance;
        final enough = balance >= plan.price;

        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppTheme.accentGold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Thanh toán bằng Ví',
                  style: TextStyle(fontSize: 17),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Gói:', plan.displayName, isDark),
              _infoRow('Giá:', NumberFormatter.formatCurrency(plan.price, currency: 'đ'), isDark),
              _infoRow('Số dư ví:', NumberFormatter.formatCurrency(balance.toDouble(), currency: 'đ'), isDark),
              if (!enough)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '⚠️ Số dư không đủ. Vui lòng nạp thêm tiền!',
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: enough ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final premiumProvider = context.read<PremiumProvider>();

    try {
      final subscription = await premiumProvider.purchaseWithWallet(planId: plan.id);

      if (mounted) Navigator.pop(context); // close loading
      if (!mounted) return;

      if (subscription != null) {
        context.read<WalletProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Đã kích hoạt ${plan.displayName}!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Reload plans to update current subscription
        premiumProvider.loadAll();
      } else {
        final errorMsg = premiumProvider.errorMessage ?? 'Thanh toán thất bại';
        // Clear provider error so page doesn't show error view
        premiumProvider.resetState();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      premiumProvider.resetState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _openManagementSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionManagementSheet(
        onRefresh: () => context.read<PremiumProvider>().loadAll(),
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
        ],
      ),
    );
  }
}

// ==================== PLAN CARD ====================

class _PlanCard extends StatelessWidget {
  final PremiumPlanDto plan;
  final bool isCurrentPlan;
  final bool hasActivePlan;
  final VoidCallback onPayOS;
  final VoidCallback onWallet;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.hasActivePlan,
    required this.onPayOS,
    required this.onWallet,
  });

  Color get _tierColor {
    switch (plan.planType) {
      case PlanType.studentPack:
        return AppTheme.accentCyan;
      case PlanType.premiumBasic:
        return AppTheme.accentGold;
      case PlanType.premiumPlus:
        return const Color(0xFF7C3AED);
      case PlanType.recruiterPro:
        return AppTheme.themeOrangeStart;
      default:
        return AppTheme.primaryBlueDark;
    }
  }

  String _tierIcon() {
    switch (plan.planType) {
      case PlanType.studentPack:
        return '🎓';
      case PlanType.premiumBasic:
        return '⭐';
      case PlanType.premiumPlus:
        return '💎';
      case PlanType.recruiterPro:
        return '🚀';
      default:
        return '📦';
    }
  }

  String _formatDuration(int months) {
    if (months > 1000) return 'Vĩnh viễn';
    return '$months tháng';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _tierColor;

    return GlassCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isCurrentPlan
              ? Border.all(color: AppTheme.successColor, width: 2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_tierIcon(), style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        if (plan.description != null)
                          Text(
                            plan.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '✅ Đang dùng',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormatter.formatCurrency(plan.price, currency: 'đ'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${_formatDuration(plan.durationMonths)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),

              // Student discount
              if (plan.studentDiscountPercent != null && plan.studentDiscountPercent! > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🎓 Sinh viên giảm ${plan.studentDiscountPercent!.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Features
              if (plan.features != null && plan.features!.isNotEmpty) ...[
                ...plan.features!.take(5).map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Action buttons
              if (!isCurrentPlan) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onWallet,
                        icon: const Icon(Icons.account_balance_wallet, size: 18),
                        label: const Text('Ví'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onPayOS,
                        icon: const Icon(Icons.qr_code, size: 18),
                        label: const Text('PayOS (QR)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isCurrentPlan) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('✅ Gói hiện tại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== HELPER ====================

class _Benefit {
  final IconData icon;
  final String title;
  final String description;
  const _Benefit(this.icon, this.title, this.description);
}
