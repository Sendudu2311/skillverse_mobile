import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/premium_models.dart';
import '../../../data/models/payment_models.dart';
import '../../providers/premium_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../payment/payment_webview_page.dart';

class PremiumPlansPage extends StatefulWidget {
  const PremiumPlansPage({super.key});

  @override
  State<PremiumPlansPage> createState() => _PremiumPlansPageState();
}

class _PremiumPlansPageState extends State<PremiumPlansPage> {
  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final premiumProvider = context.read<PremiumProvider>();
    await premiumProvider.loadAvailablePlans();
    await premiumProvider.loadCurrentSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói Premium'),
        elevation: 0,
      ),
      body: Consumer<PremiumProvider>(
        builder: (context, premiumProvider, child) {
          if (premiumProvider.isLoading && premiumProvider.availablePlans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (premiumProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    premiumProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadPlans,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final plans = premiumProvider.availablePlans;
          final currentSubscription = premiumProvider.currentSubscription;

          if (plans.isEmpty) {
            return const Center(
              child: Text('Không có gói Premium nào'),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPlans,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nâng cấp Premium',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Truy cập không giới hạn khóa học & tính năng AI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Current Subscription Status
                  if (currentSubscription != null &&
                      currentSubscription.isActive)
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bạn đang dùng ${currentSubscription.plan.displayName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Còn ${currentSubscription.daysRemaining ?? 0} ngày',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Plans List (filter out FREE_TIER)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: plans.where((p) => p.planType != PlanType.freeTier).length,
                    itemBuilder: (context, index) {
                      final filteredPlans = plans.where((p) => p.planType != PlanType.freeTier).toList();
                      final plan = filteredPlans[index];
                      final isCurrentPlan = currentSubscription != null &&
                          currentSubscription.plan.id == plan.id;

                      return _PlanCard(
                        plan: plan,
                        isCurrentPlan: isCurrentPlan,
                        onSubscribe: () => _handleSubscribe(plan),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Benefits Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lợi ích Premium',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            _BenefitItem(
                              icon: Icons.school,
                              title: 'Truy cập tất cả khóa học',
                              description: 'Học không giới hạn',
                            ),
                            _BenefitItem(
                              icon: Icons.psychology,
                              title: 'AI Chatbot & Roadmap',
                              description: 'Trợ lý AI cá nhân hóa',
                            ),
                            _BenefitItem(
                              icon: Icons.verified,
                              title: 'Chứng chỉ hoàn thành',
                              description: 'Chứng nhận chính thức',
                            ),
                            _BenefitItem(
                              icon: Icons.support_agent,
                              title: 'Hỗ trợ ưu tiên',
                              description: 'Phản hồi nhanh chóng',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSubscribe(PremiumPlanDto plan) async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đăng ký')),
        );
      }
      return;
    }

    final price = plan.price;

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng ký'),
        content: Text(
          'Bạn muốn đăng ký gói ${plan.displayName}?\n\n'
          'Giá: ${price.toStringAsFixed(0)} ${plan.currency}/${plan.durationMonths} tháng',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final paymentProvider = context.read<PaymentProvider>();

    // Create payment for premium subscription
    final paymentResponse = await paymentProvider.createPayment(
      amount: price,
      type: PaymentType.premiumSubscription,
      paymentMethod: PaymentMethod.payos,
      description: 'Đăng ký gói ${plan.displayName}',
      planId: plan.id,
      successUrl: 'https://skillverse.app/payment/success',
      cancelUrl: 'https://skillverse.app/payment/cancel',
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (paymentResponse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentProvider.errorMessage ?? 'Lỗi tạo thanh toán',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate to payment webview
    if (!mounted) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewPage(
          checkoutUrl: paymentResponse.checkoutUrl,
          successUrl: 'https://skillverse.app/payment/success',
          cancelUrl: 'https://skillverse.app/payment/cancel',
        ),
      ),
    );

    // Handle payment result
    if (!mounted) return;
    if (result != null && result['success'] == true) {
      // Payment successful - verify and reload subscription
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanh toán thành công! Đang kích hoạt gói Premium...'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload premium subscription data
      final premiumProvider = context.read<PremiumProvider>();
      await premiumProvider.loadCurrentSubscription();
      await _loadPlans();

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('Đăng ký thành công!'),
            content: Text(
              'Bạn đã đăng ký thành công gói ${plan.displayName}.\n'
              'Hãy tận hưởng các tính năng Premium ngay bây giờ!',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tuyệt vời!'),
              ),
            ],
          ),
        );
      }
    } else if (result != null && result['cancelled'] == true) {
      // Payment cancelled by user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanh toán đã bị hủy'),
          backgroundColor: Colors.orange,
        ),
      );

      // Cancel the payment on backend
      if (paymentResponse.transactionReference.isNotEmpty) {
        await paymentProvider.cancelPayment(
          paymentResponse.transactionReference,
          reason: 'Người dùng hủy thanh toán',
        );
      }
    } else {
      // Payment failed or unknown result
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanh toán không thành công. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  final PremiumPlanDto plan;
  final bool isCurrentPlan;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  String _formatDuration(int months) {
    // Handle MAX_INT or very large values (permanent/lifetime)
    if (months > 1000) {
      return 'Vĩnh viễn';
    }
    return '$months tháng';
  }

  @override
  Widget build(BuildContext context) {
    final price = plan.price;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: isCurrentPlan ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrentPlan
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Name & Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isCurrentPlan)
                  Chip(
                    label: const Text('Đang dùng'),
                    backgroundColor: Colors.green[100],
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            if (plan.description != null)
              Text(
                plan.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${price.toStringAsFixed(0)}đ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ ${_formatDuration(plan.durationMonths)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Features
            if (plan.features != null && plan.features!.isNotEmpty) ...[
              ...plan.features!.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan ? null : onSubscribe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCurrentPlan ? 'Gói hiện tại' : 'Đăng ký ngay',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
