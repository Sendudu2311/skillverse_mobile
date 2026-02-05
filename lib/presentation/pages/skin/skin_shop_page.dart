import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/models/skin_models.dart';
import '../../providers/skin_provider.dart';
import '../../themes/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'widgets/skin_card_widget.dart';
import 'widgets/purchase_dialog.dart';

class SkinShopPage extends StatefulWidget {
  const SkinShopPage({super.key});

  @override
  State<SkinShopPage> createState() => _SkinShopPageState();
}

class _SkinShopPageState extends State<SkinShopPage> {
  String _selectedFilter = 'all';
  int _displayedCount = 6; // Show 6 skins initially
  static const int _itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkinProvider>().refreshAll();
    });
  }

  void _loadMore() {
    setState(() {
      _displayedCount += _itemsPerPage;
    });
  }

  void _resetPagination() {
    setState(() {
      _displayedCount = _itemsPerPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackgroundPrimary
          : AppTheme.lightBackgroundPrimary,
      body: SafeArea(
        child: Consumer<SkinProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.allSkins.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => provider.refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(isDark),
                    const SizedBox(height: 24),

                    // Hall of Fame
                    if (provider.hallOfFame.isNotEmpty) ...[
                      _buildHallOfFame(provider.hallOfFame, isDark),
                      const SizedBox(height: 24),
                    ],

                    // Rising Stars
                    if (provider.risingStars.isNotEmpty) ...[
                      _buildRisingStars(provider.risingStars, isDark),
                      const SizedBox(height: 24),
                    ],

                    // Filter chips
                    _buildFilterChips(isDark),
                    const SizedBox(height: 16),

                    // Skin grid
                    _buildSkinGrid(provider, isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              onPressed: () {
                // Use go_router to navigate back to profile
                context.go('/profile');
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [AppTheme.primaryBlueDark, AppTheme.primaryBlue],
              ).createShader(bounds),
              child: const Text(
                'MEOWL SKIN SHOP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlueDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v2.0',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            'Nâng cấp trợ lý Meowl của bạn với những bộ trang phục công nghệ cao từ tương lai.',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHallOfFame(List<MeowlSkin> skins, bool isDark) {
    return Column(
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ).createShader(bounds),
              child: const Text(
                'HALL OF FAME',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star_outline, color: Colors.amber, size: 20),
          ],
        ),
        const SizedBox(height: 20),

        // Podium
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // #2
            if (skins.length > 1) _buildPodiumItem(skins[1], 2, 100, isDark),
            const SizedBox(width: 8),
            // #1
            if (skins.isNotEmpty) _buildPodiumItem(skins[0], 1, 130, isDark),
            const SizedBox(width: 8),
            // #3
            if (skins.length > 2) _buildPodiumItem(skins[2], 3, 80, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumItem(
    MeowlSkin skin,
    int rank,
    double height,
    bool isDark,
  ) {
    return Column(
      children: [
        // Crown for #1
        if (rank == 1)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),

        // Skin image
        GestureDetector(
          onTap: () => _showPurchaseDialog(skin),
          child: Container(
            width: rank == 1 ? 100 : 80,
            height: rank == 1 ? 130 : 100,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: rank == 1
                    ? Colors.amber
                    : (rank == 2 ? Colors.grey : Colors.brown),
                width: 2,
              ),
            ),
            child: skin.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      skin.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    ),
                  )
                : _buildPlaceholder(),
          ),
        ),
        const SizedBox(height: 8),

        // Rank badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: rank == 1
                ? Colors.amber
                : (rank == 2 ? Colors.grey : Colors.brown),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '| $rank |',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRisingStars(List<MeowlSkin> skins, bool isDark) {
    return Column(
      children: [
        // Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppTheme.primaryBlueDark, AppTheme.primaryBlue],
          ).createShader(bounds),
          child: const Text(
            'RISING STARS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: skins.asMap().entries.map((entry) {
              final index = entry.key;
              final skin = entry.value;
              return _buildRisingStarItem(skin, index + 4, isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRisingStarItem(MeowlSkin skin, int rank, bool isDark) {
    return GestureDetector(
      onTap: () => _showPurchaseDialog(skin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? AppTheme.darkBorderColor
                  : AppTheme.lightBorderColor.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),

            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDark
                    ? AppTheme.darkCardBackground
                    : AppTheme.lightCardBackground,
              ),
              child: skin.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        skin.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildSmallPlaceholder(),
                      ),
                    )
                  : _buildSmallPlaceholder(),
            ),
            const SizedBox(width: 16),

            // Name and price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '₿ ${skin.purchaseCount ?? 0}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.primaryBlueDark,
                      ),
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

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'common', 'label': 'Common'},
      {'key': 'rare', 'label': 'Rare'},
      {'key': 'legendary', 'label': 'Legendary'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary),
                ),
              ),
              selectedColor: AppTheme.primaryBlueDark,
              backgroundColor: isDark
                  ? AppTheme.darkCardBackground
                  : AppTheme.lightCardBackground,
              checkmarkColor: Colors.white,
              onSelected: (_) {
                setState(() => _selectedFilter = f['key']!);
                _resetPagination();

                // Load my skins when "Đã sở hữu" is selected
                if (f['key'] == 'owned') {
                  context.read<SkinProvider>().loadMySkins();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkinGrid(SkinProvider provider, bool isDark) {
    List<MeowlSkin> skins;
    switch (_selectedFilter) {
      case 'owned':
        // Use mySkins from API for owned filter
        skins = provider.mySkins.isNotEmpty
            ? provider.mySkins
            : provider.ownedSkins;
        break;
      case 'common':
        skins = provider.commonSkins;
        break;
      case 'rare':
        skins = provider.rareSkins;
        break;
      case 'legendary':
        skins = provider.legendarySkins;
        break;
      default:
        skins = provider.allSkins;
    }

    if (skins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.pets,
                size: 48,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có skin nào',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Apply pagination
    final displayedSkins = skins.take(_displayedCount).toList();
    final hasMore = skins.length > _displayedCount;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: displayedSkins.length,
          itemBuilder: (context, index) {
            final skin = displayedSkins[index];
            return SkinCard(
              skin: skin,
              onTap: () {
                if (skin.owned) {
                  _selectSkin(skin);
                } else {
                  _showPurchaseDialog(skin);
                }
              },
              onPurchase: () => _showPurchaseDialog(skin),
            );
          },
        ),

        // Load More button
        if (hasMore) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(
                'XEM THÊM ${skins.length - _displayedCount} SKIN',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppTheme.primaryBlueDark, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPurchaseDialog(MeowlSkin skin) {
    // Only show purchase dialog for non-owned skins
    // Owned skins are handled by onTap in SkinCard
    showDialog(
      context: context,
      builder: (ctx) => PurchaseDialog(
        skin: skin,
        onConfirm: () {
          Navigator.of(ctx).pop();
          _purchaseSkin(skin);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _purchaseSkin(MeowlSkin skin) async {
    final provider = context.read<SkinProvider>();
    final success = await provider.purchaseSkin(skin.skinCode);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? AppTheme.successColor : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success ? 'Thành công' : 'Thất bại',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: success ? AppTheme.successColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            success
                ? 'Đã mua ${skin.displayName} thành công!'
                : provider.error ?? 'Có lỗi xảy ra',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      // Refresh data if purchase successful
      if (success) {
        provider.refreshAll();
      }
    }
  }

  Future<void> _selectSkin(MeowlSkin skin) async {
    final provider = context.read<SkinProvider>();
    final success = await provider.selectSkin(skin.skinCode);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? AppTheme.successColor : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success ? 'Thành công' : 'Thất bại',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: success ? AppTheme.successColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            success
                ? 'Đã chọn ${skin.displayName}!'
                : provider.error ?? 'Có lỗi xảy ra',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.pets,
        size: 40,
        color: AppTheme.primaryBlueDark.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSmallPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.pets,
        size: 24,
        color: AppTheme.primaryBlueDark.withOpacity(0.5),
      ),
    );
  }
}
