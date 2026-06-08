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
      'MENTOR_BOOKING',
      'COURSE_SALE',
      'SEMINAR_PAYOUT',
      'JOB_PAYOUT',
      'ESCROW_REFUND',
      'REFUND',
      'REFUND_CASH',
      'REFUND_COINS',
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

  /// Whether this transaction decreases a balance.
  bool get isDebitTransaction {
    if (isCoinPurchaseCredit) return false;
    if (isDebit != null) return isDebit!;
    return !isCreditTransaction && status.toUpperCase() == 'COMPLETED';
  }

  /// Coin purchase creates one cash debit and one coin credit transaction.
  /// Backend may reuse PURCHASE_COINS for the coin row, so guard by currency.
  bool get isCoinPurchaseCredit {
    final type = transactionType.toUpperCase();
    final currency = currencyType.toUpperCase();
    final reference = referenceType?.toUpperCase();
    return currency == 'COIN' &&
        reference == 'COIN_PURCHASE' &&
        coinAmount != null &&
        coinAmount! > 0 &&
        (type == 'PURCHASE_COINS' || type == 'BONUS_COINS');
  }

  bool get isCoinCreditTransaction {
    if (isCoinPurchaseCredit) return true;
    if (isCredit != null) return isCredit!;
    return isCreditTransaction;
  }
}

// ============================================================================
// WITHDRAWAL REQUEST (lịch sử rút tiền)
// ============================================================================

/// Maps to WithdrawalRequestResponse DTO from backend.
/// Manual fromJson — no build_runner needed.
class WithdrawalRequest {
  final int id;
  final String? requestCode;
  final double amount;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountName;
  final String? bankBranch;
  final String status; // PENDING | PROCESSING | APPROVED | REJECTED | CANCELLED
  final String? rejectionReason;
  final String? notes;
  final String? adminNotes;
  final String createdAt;
  final String? processedAt;
  final double? fee;
  final double? netAmount;
  final bool? canCancel;

  const WithdrawalRequest({
    required this.id,
    this.requestCode,
    required this.amount,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.bankBranch,
    required this.status,
    this.rejectionReason,
    this.notes,
    this.adminNotes,
    required this.createdAt,
    this.processedAt,
    this.fee,
    this.netAmount,
    this.canCancel,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    double? tryDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    int tryInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return WithdrawalRequest(
      id: tryInt(json['requestId'] ?? json['id']),
      requestCode: json['requestCode'] as String?,
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bankName'] as String? ?? '',
      bankAccountNumber: json['bankAccountNumber'] as String? ?? '',
      bankAccountName: json['bankAccountName'] as String? ?? '',
      bankBranch: json['bankBranch'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['userNotes'] as String? ?? json['notes'] as String?,
      adminNotes: json['adminNotes'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      processedAt:
          json['processedAt'] as String? ?? json['completedAt'] as String?,
      fee: tryDouble(json['fee']),
      netAmount: tryDouble(json['netAmount']),
      canCancel: json['canCancel'] as bool?,
    );
  }

  /// Returns true if this withdrawal is in a terminal state
  bool get isFinished =>
      status == 'APPROVED' || status == 'REJECTED' || status == 'CANCELLED';

  /// Returns true if money is pending / being processed
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';
}
