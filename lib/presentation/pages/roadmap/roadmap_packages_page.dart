import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/roadmap_package_models.dart';
import '../../providers/roadmap_package_provider.dart';
import '../../themes/app_theme.dart';

/// Learner page: browse active roadmap offerings & manage purchases.
class RoadmapPackagesPage extends StatefulWidget {
  const RoadmapPackagesPage({super.key});

  @override
  State<RoadmapPackagesPage> createState() => _RoadmapPackagesPageState();
}

class _RoadmapPackagesPageState extends State<RoadmapPackagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoadmapPackageProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói Roadmap'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Khám phá'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Gói của tôi'),
          ],
        ),
      ),
      body: Consumer<RoadmapPackageProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _OfferingsTab(provider: provider, isDark: isDark),
              _PurchasesTab(provider: provider, isDark: isDark),
            ],
          );
        },
      ),
    );
  }
}

// ─── Offerings Tab ─────────────────────────────────────────────────────────

class _OfferingsTab extends StatelessWidget {
  final RoadmapPackageProvider provider;
  final bool isDark;

  const _OfferingsTab({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingOfferings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.offerings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(height: 16),
            Text('Chưa có gói roadmap nào',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Các gói mentor sẽ xuất hiện ở đây khi có sẵn',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadOfferings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.offerings.length,
        itemBuilder: (context, index) {
          final offering = provider.offerings[index];
          final alreadyPurchased =
              provider.purchasedOfferingIds.contains(offering.id);

          return _OfferingCard(
            offering: offering,
            alreadyPurchased: alreadyPurchased,
            isPurchasing: provider.isPurchasing,
            isDark: isDark,
            onPurchase: () => _handlePurchase(context, offering),
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    RoadmapOfferingResponse offering,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận mua gói'),
        content: Text(
          'Bạn muốn mua gói "${offering.title}" với giá '
          '${_formatPrice(offering.price, offering.currency)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result =
          await context.read<RoadmapPackageProvider>().purchaseOffering(
                offering.id,
              );
      if (context.mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mua gói thành công!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<RoadmapPackageProvider>().error ??
                    'Mua gói thất bại',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}

// ─── Purchases Tab ─────────────────────────────────────────────────────────

class _PurchasesTab extends StatelessWidget {
  final RoadmapPackageProvider provider;
  final bool isDark;

  const _PurchasesTab({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingPurchases) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color),
            const SizedBox(height: 16),
            Text('Bạn chưa mua gói nào',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Khám phá các gói roadmap ở tab "Khám phá"',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadPurchases,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.purchases.length,
        itemBuilder: (context, index) {
          final purchase = provider.purchases[index];
          return _PurchaseCard(
            purchase: purchase,
            isDark: isDark,
            onCancel: purchase.status == RoadmapPurchaseStatus.active ||
                    purchase.status == RoadmapPurchaseStatus.pendingPayment
                ? () => _handleCancel(context, purchase)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    RoadmapPurchaseResponse purchase,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận huỷ gói'),
        content: const Text('Bạn chắc chắn muốn huỷ gói này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ gói'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await context
          .read<RoadmapPackageProvider>()
          .cancelPurchase(purchase.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã huỷ gói thành công' : 'Huỷ gói thất bại'),
          ),
        );
      }
    }
  }
}

// ─── Offering Card Widget ──────────────────────────────────────────────────

class _OfferingCard extends StatelessWidget {
  final RoadmapOfferingResponse offering;
  final bool alreadyPurchased;
  final bool isPurchasing;
  final bool isDark;
  final VoidCallback onPurchase;

  const _OfferingCard({
    required this.offering,
    required this.alreadyPurchased,
    required this.isPurchasing,
    required this.isDark,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeCount = offering.template?.nodes.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offering.title,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (offering.mentorName != null)
                        Text('Mentor: ${offering.mentorName}',
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),

            if (offering.description != null &&
                offering.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(offering.description!,
                  style: theme.textTheme.bodyMedium, maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],

            const SizedBox(height: 12),

            // Meta chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.account_tree_outlined,
                  label: '$nodeCount nodes',
                  isDark: isDark,
                ),
                if (offering.template?.targetRoleSnapshot != null)
                  _MetaChip(
                    icon: Icons.work_outline,
                    label: offering.template!.targetRoleSnapshot!,
                    isDark: isDark,
                  ),
                if (offering.maxStudents != null)
                  _MetaChip(
                    icon: Icons.people_outline,
                    label: 'Tối đa ${offering.maxStudents} học viên',
                    isDark: isDark,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Price & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatPrice(offering.price, offering.currency),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.themeGreenStart,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (alreadyPurchased)
                  Chip(
                    label: const Text('Đã mua'),
                    backgroundColor: AppTheme.themeGreenStart.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                        color: AppTheme.themeGreenStart,
                        fontWeight: FontWeight.w600),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isPurchasing ? null : onPurchase,
                    icon: isPurchasing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_outlined, size: 18),
                    label: Text(isPurchasing ? 'Đang xử lý...' : 'Mua gói'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Purchase Card Widget ──────────────────────────────────────────────────

class _PurchaseCard extends StatelessWidget {
  final RoadmapPurchaseResponse purchase;
  final bool isDark;
  final VoidCallback? onCancel;

  const _PurchaseCard({
    required this.purchase,
    required this.isDark,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(purchase.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    purchase.offering?.title ?? 'Gói #${purchase.id}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    purchase.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Info rows
            _InfoRow(
              label: 'Giá',
              value: _formatPrice(purchase.price, purchase.currency),
            ),
            if (purchase.journeyId != null)
              _InfoRow(
                label: 'Journey ID',
                value: '#${purchase.journeyId}',
              ),
            if (purchase.createdAt != null)
              _InfoRow(
                label: 'Ngày mua',
                value: DateFormat('dd/MM/yyyy HH:mm')
                    .format(purchase.createdAt!),
              ),

            if (onCancel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Huỷ gói'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(RoadmapPurchaseStatus status) {
    switch (status) {
      case RoadmapPurchaseStatus.active:
        return AppTheme.successColor;
      case RoadmapPurchaseStatus.completed:
        return AppTheme.infoColor;
      case RoadmapPurchaseStatus.pendingPayment:
        return AppTheme.warningColor;
      case RoadmapPurchaseStatus.cancelled:
      case RoadmapPurchaseStatus.refunded:
        return AppTheme.errorColor;
    }
  }
}

// ─── Helper Widgets ────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Price Formatter ───────────────────────────────────────────────────────

String _formatPrice(double price, String currency) {
  if (currency.toUpperCase() == 'VND') {
    final formatted = NumberFormat('#,###', 'vi_VN').format(price.toInt());
    return '$formatted₫';
  }
  return NumberFormat.currency(symbol: currency).format(price);
}
