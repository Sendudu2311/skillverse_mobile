import 'package:json_annotation/json_annotation.dart';

part 'skin_models.g.dart';

/// Skin rarity enum based on isPremium and price
enum SkinRarity {
  @JsonValue('COMMON')
  common,
  @JsonValue('RARE')
  rare,
  @JsonValue('LEGENDARY')
  legendary,
}

/// Meowl Skin model from GET /api/skins
@JsonSerializable()
class MeowlSkin {
  final int id;
  final String skinCode;
  final String name;
  final String? nameVi;
  final String? imageUrl;

  @JsonKey(name: 'isPremium')
  final bool isPremium;

  final double price;
  final int? purchaseCount;

  @JsonKey(name: 'isOwned')
  final bool owned;

  @JsonKey(name: 'isSelected')
  final bool selected;

  final DateTime? createdAt;

  MeowlSkin({
    required this.id,
    required this.skinCode,
    required this.name,
    this.nameVi,
    this.imageUrl,
    this.isPremium = false,
    this.price = 0,
    this.purchaseCount,
    this.owned = false,
    this.selected = false,
    this.createdAt,
  });

  factory MeowlSkin.fromJson(Map<String, dynamic> json) =>
      _$MeowlSkinFromJson(json);
  Map<String, dynamic> toJson() => _$MeowlSkinToJson(this);

  /// Get display name (Vietnamese if available, else English)
  String get displayName => nameVi ?? name;

  /// Get formatted price
  String get formattedPrice {
    if (price == 0) return 'MIỄN PHÍ';
    if (isPremium) return 'PREMIUM';
    return '₿ ${price.toInt()}';
  }

  /// Determine rarity based on isPremium and price
  SkinRarity get rarity {
    if (isPremium) return SkinRarity.legendary;
    if (price > 50) return SkinRarity.rare;
    return SkinRarity.common;
  }

  /// Get rarity display text
  String get rarityText {
    switch (rarity) {
      case SkinRarity.legendary:
        return 'LEGENDARY';
      case SkinRarity.rare:
        return 'RARE';
      case SkinRarity.common:
        return 'COMMON';
    }
  }

  /// Check if skin is free
  bool get isFree => price == 0 && !isPremium;

  /// Copy with method
  MeowlSkin copyWith({
    int? id,
    String? skinCode,
    String? name,
    String? nameVi,
    String? imageUrl,
    bool? isPremium,
    double? price,
    int? purchaseCount,
    bool? owned,
    bool? selected,
    DateTime? createdAt,
  }) {
    return MeowlSkin(
      id: id ?? this.id,
      skinCode: skinCode ?? this.skinCode,
      name: name ?? this.name,
      nameVi: nameVi ?? this.nameVi,
      imageUrl: imageUrl ?? this.imageUrl,
      isPremium: isPremium ?? this.isPremium,
      price: price ?? this.price,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      owned: owned ?? this.owned,
      selected: selected ?? this.selected,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
