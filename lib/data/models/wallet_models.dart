import 'package:json_annotation/json_annotation.dart';

part 'wallet_models.g.dart';

double _toDouble(dynamic v) => (v as num).toDouble();
double? _toDoubleOrNull(dynamic v) => v == null ? null : (v as num).toDouble();

// ============================================================================
// WALLET STATISTICS
// ============================================================================

@JsonSerializable()
class WalletStatistics {
  @JsonKey(fromJson: _toDouble)
  final double totalDeposited;
  @JsonKey(fromJson: _toDouble)
  final double totalWithdrawn;
  final int totalCoinsEarned;
  final int totalCoinsSpent;
  final int transactionCount;
  final int withdrawalCount;
  @JsonKey(fromJson: _toDouble)
  final double avgTransactionAmount;
  final String? lastTransactionDate;
  final String? lastWithdrawalDate;

  WalletStatistics({
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.totalCoinsEarned,
    required this.totalCoinsSpent,
    required this.transactionCount,
    required this.withdrawalCount,
    required this.avgTransactionAmount,
    this.lastTransactionDate,
    this.lastWithdrawalDate,
  });

  factory WalletStatistics.fromJson(Map<String, dynamic> json) =>
      _$WalletStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$WalletStatisticsToJson(this);

  /// Net cash flow = totalDeposited - totalWithdrawn
  double get netCashFlow => totalDeposited - totalWithdrawn;
}

// ============================================================================
// WALLET TRANSACTION
// ============================================================================

@JsonSerializable()
class WalletTransaction {
  final int transactionId;
  final int walletId;
  final String transactionType;
  final String? transactionTypeName;
  final String currencyType;
  @JsonKey(fromJson: _toDoubleOrNull)
  final double? cashAmount;
  final int? coinAmount;
  @JsonKey(fromJson: _toDoubleOrNull)
  final double? cashBalanceAfter;
  final int? coinBalanceAfter;
  final String description;
  final String? notes;
  final String? referenceType;
  final String? referenceId;
  final String status;
  @JsonKey(fromJson: _toDoubleOrNull)
  final double? fee;
  final String createdAt;
  final String? processedAt;
  final bool? isCredit;
  final bool? isDebit;

  WalletTransaction({
    required this.transactionId,
    required this.walletId,
    required this.transactionType,
    this.transactionTypeName,
    required this.currencyType,
    this.cashAmount,     // double?
    this.coinAmount,
    this.cashBalanceAfter,   // double?
    this.coinBalanceAfter,
    required this.description,
    this.notes,
    this.referenceType,
    this.referenceId,
    required this.status,
    this.fee,            // double?
    required this.createdAt,
    this.processedAt,
    this.isCredit,
    this.isDebit,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  /// Display amount: prefer cashAmount, fallback to coinAmount
  double get displayAmount => cashAmount ?? (coinAmount ?? 0).toDouble();

  /// Whether this transaction is a credit (money in)
  bool get isCreditTransaction {
    if (isCredit != null) return isCredit!;
    const creditTypes = [
      'DEPOSIT',
      'DEPOSIT_CASH',
      'REFUND',
      'REFUND_CASH',
      'EARN_COINS',
      'RECEIVE_TIP',
      'BONUS_COINS',
      'REWARD_ACHIEVEMENT',
      'DAILY_LOGIN_BONUS',
      'COURSE_PAYOUT',
      'ADMIN_ADJUSTMENT',
    ];
    return creditTypes.any(
      (t) => transactionType.toUpperCase().contains(t),
    );
  }
}
