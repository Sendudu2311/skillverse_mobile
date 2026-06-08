import 'package:flutter/material.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/wallet_service.dart';
import '../../core/utils/error_handler.dart';

enum WalletTransactionCategoryKey {
  deposit,
  withdrawal,
  coinPurchase,
  premiumPurchase,
  coursePurchase,
  mentorTip,
  mentorIncome,
  jobPayout,
  jobEscrow,
  refund,
  coinReward,
  adminAdjustment,
  otherIncome,
  otherExpense,
}

class WalletTransactionCategorySummary {
  final WalletTransactionCategoryKey key;
  final String label;
  final int count;
  final double cashAmount;
  final int coinAmount;

  const WalletTransactionCategorySummary({
    required this.key,
    required this.label,
    required this.count,
    required this.cashAmount,
    required this.coinAmount,
  });

  WalletTransactionCategorySummary add(WalletTransaction tx) {
    return WalletTransactionCategorySummary(
      key: key,
      label: label,
      count: count + 1,
      cashAmount: cashAmount + (tx.cashAmount ?? 0).abs(),
      coinAmount: coinAmount + (tx.coinAmount ?? 0).abs(),
    );
  }
}

class WalletTransactionFlowPoint {
  final String dateKey;
  final String label;
  final double deposit;
  final double withdraw;
  final int coins;

  const WalletTransactionFlowPoint({
    required this.dateKey,
    required this.label,
    required this.deposit,
    required this.withdraw,
    required this.coins,
  });

  WalletTransactionFlowPoint copyWith({
    double? deposit,
    double? withdraw,
    int? coins,
  }) {
    return WalletTransactionFlowPoint(
      dateKey: dateKey,
      label: label,
      deposit: deposit ?? this.deposit,
      withdraw: withdraw ?? this.withdraw,
      coins: coins ?? this.coins,
    );
  }
}

/// Provider for Wallet page state management
class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  // State
  WalletResponse? _wallet;
  WalletStatistics? _statistics;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showBalance = true;

  // Tỷ giá: 1 xu = 76 VNĐ (same as web client)
  static const int coinToVndRate = 76;

  // Getters
  WalletResponse? get wallet => _wallet;
  WalletStatistics? get statistics => _statistics;
  List<WalletTransaction> get transactions => _transactions;
  List<WalletTransaction> get recentTransactions =>
      _transactions.take(5).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showBalance => _showBalance;

  // Computed getters
  double get cashBalance => _wallet?.cashBalance ?? 0;
  int get coinBalance => _wallet?.coinBalance ?? 0;
  double get totalDeposited => _wallet?.totalDeposited ?? 0;
  double get totalWithdrawn => _wallet?.totalWithdrawn ?? 0;
  int get totalCoinsEarned => _wallet?.totalCoinsEarned ?? 0;
  int get totalCoinsSpent => _wallet?.totalCoinsSpent ?? 0;
  String get walletStatus => _wallet?.status ?? 'UNKNOWN';
  bool get hasBankAccount => _wallet?.hasBankAccount ?? false;
  String? get bankName => _wallet?.bankName;
  String? get bankAccountNumber => _wallet?.bankAccountNumber;
  String? get bankAccountName => _wallet?.bankAccountName;
  bool get hasTransactionPin => _wallet?.hasTransactionPin ?? false;

  /// Total assets in VND (cash + coin value)
  double get totalAssets => cashBalance + (coinBalance * coinToVndRate);

  /// Cash percentage of total assets
  double get cashPercent =>
      totalAssets > 0 ? (cashBalance / totalAssets) * 100 : 0;

  /// Coin percentage of total assets
  double get coinPercent =>
      totalAssets > 0 ? ((coinBalance * coinToVndRate) / totalAssets) * 100 : 0;

  /// Coin value in VND
  int get coinValueInVnd => coinBalance * coinToVndRate;

  /// Net cash flow
  double get netCashFlow => statsTotalDeposited - statsTotalWithdrawn;

  // Stats getters (from statistics API)
  double get statsTotalDeposited =>
      _statistics?.totalDeposited ?? totalDeposited;
  double get statsTotalWithdrawn =>
      _statistics?.totalWithdrawn ?? totalWithdrawn;
  int get statsTotalCoinsEarned =>
      _statistics?.totalCoinsEarned ?? totalCoinsEarned;
  int get statsTotalCoinsSpent =>
      _statistics?.totalCoinsSpent ?? totalCoinsSpent;
  int get statsTransactionCount => _statistics?.transactionCount ?? 0;
  int get statsWithdrawalCount => _statistics?.withdrawalCount ?? 0;

  int get depositTransactionCount =>
      _transactions.where(_isCashDeposit).length;
  int get withdrawalTransactionCount =>
      _transactions.where(_isCashWithdrawal).length;

  List<WalletTransactionCategorySummary> get transactionCategorySummaries {
    final summaries = <WalletTransactionCategoryKey,
        WalletTransactionCategorySummary>{};

    for (final tx in _transactions) {
      final key = _classifyTransaction(tx);
      final current = summaries[key] ?? _emptyCategorySummary(key);
      summaries[key] = current.add(tx);
    }

    return WalletTransactionCategoryKey.values
        .map((key) => summaries[key])
        .whereType<WalletTransactionCategorySummary>()
        .where((summary) => summary.count > 0)
        .toList();
  }

  List<WalletTransactionFlowPoint> get weeklyTransactionFlow {
    final today = DateTime.now();
    final points = <String, WalletTransactionFlowPoint>{};

    for (var i = 6; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);
      points[_dateKey(date)] = WalletTransactionFlowPoint(
        dateKey: _dateKey(date),
        label: _shortDateLabel(date),
        deposit: 0,
        withdraw: 0,
        coins: 0,
      );
    }

    for (final tx in _transactions) {
      final txDate = DateTime.tryParse(tx.createdAt)?.toLocal();
      if (txDate == null) continue;

      final point = points[_dateKey(txDate)];
      if (point == null) continue;

      if (tx.currencyType.toUpperCase() == 'CASH') {
        final amount = (tx.cashAmount ?? 0).abs();
        if (_isCashDeposit(tx)) {
          points[point.dateKey] = point.copyWith(
            deposit: point.deposit + amount,
          );
        } else if (_isCashWithdrawal(tx)) {
          points[point.dateKey] = point.copyWith(
            withdraw: point.withdraw + amount,
          );
        }
      } else if (tx.currencyType.toUpperCase() == 'COIN') {
        points[point.dateKey] = point.copyWith(
          coins: point.coins + (tx.coinAmount ?? 0).abs(),
        );
      }
    }

    return points.values.toList();
  }

  // ==================== ACTIONS ====================

  /// Toggle show/hide balance
  void toggleBalance() {
    _showBalance = !_showBalance;
    notifyListeners();
  }

  /// Load all wallet data
  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load in parallel
      final results = await Future.wait([
        _walletService.getMyWallet(),
        _walletService
            .getStatistics()
            .then<WalletStatistics?>((v) => v)
            .catchError((_) => null),
        _walletService
            .getTransactions(page: 0, size: 100)
            .catchError((_) => <WalletTransaction>[]),
      ]);

      _wallet = results[0] as WalletResponse;
      _statistics = results[1] as WalletStatistics?;
      _transactions = results[2] as List<WalletTransaction>;
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    await loadAll();
  }

  /// Cập nhật tài khoản ngân hàng và tải lại ví
  Future<void> updateBankAccount({
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _walletService.updateBankAccount(
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankAccountName: bankAccountName,
      );
      await loadAll();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cài đặt mã PIN giao dịch và tải lại ví
  Future<void> setTransactionPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _walletService.setTransactionPin(pin);
      await loadAll();
    } catch (e) {
      _errorMessage = ErrorHandler.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called by app-level logout listener to purge user data.
  void clearOnLogout() {
    _wallet = null;
    _statistics = null;
    _transactions = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  static WalletTransactionCategorySummary _emptyCategorySummary(
    WalletTransactionCategoryKey key,
  ) {
    return WalletTransactionCategorySummary(
      key: key,
      label: _categoryLabel(key),
      count: 0,
      cashAmount: 0,
      coinAmount: 0,
    );
  }

  static WalletTransactionCategoryKey _classifyTransaction(
    WalletTransaction tx,
  ) {
    final type = tx.transactionType.toUpperCase();
    final reference = tx.referenceType?.toUpperCase() ?? '';
    final description = tx.description.toUpperCase();

    if (_containsAny(type, ['PURCHASE_PREMIUM']) ||
        _containsAny(description, ['PREMIUM'])) {
      return WalletTransactionCategoryKey.premiumPurchase;
    }
    if (_containsAny(type, [
      'MENTOR_BOOKING',
      'COURSE_SALE',
      'SEMINAR_PAYOUT',
      'RECEIVE_TIP',
    ])) {
      return WalletTransactionCategoryKey.mentorIncome;
    }
    if (_containsAny(type, ['PURCHASE_COURSE']) ||
        _containsAny(reference, ['COURSE']) ||
        _containsAny(description, ['KHÓA HỌC', 'COURSE'])) {
      return WalletTransactionCategoryKey.coursePurchase;
    }
    if (_containsAny(type, ['PURCHASE_COINS', 'COIN_PURCHASE']) ||
        reference == 'COIN_PURCHASE') {
      return WalletTransactionCategoryKey.coinPurchase;
    }
    if (_containsAny(type, ['TIP_MENTOR'])) {
      return WalletTransactionCategoryKey.mentorTip;
    }
    if (_containsAny(type, ['JOB_PAYOUT', 'ESCROW_RELEASE'])) {
      return WalletTransactionCategoryKey.jobPayout;
    }
    if (_containsAny(type, [
      'ESCROW_FUND',
      'JOB_POSTING_FEE',
      'JOB_REOPEN_FEE',
      'PLATFORM_FEE',
    ])) {
      return WalletTransactionCategoryKey.jobEscrow;
    }
    if (_containsAny(type, ['REFUND', 'ESCROW_REFUND'])) {
      return WalletTransactionCategoryKey.refund;
    }
    if (_containsAny(type, [
      'EARN_COINS',
      'BONUS_COINS',
      'REWARD_ACHIEVEMENT',
      'DAILY_LOGIN_BONUS',
    ])) {
      return WalletTransactionCategoryKey.coinReward;
    }
    if (_containsAny(type, ['ADMIN_ADJUSTMENT', 'SYSTEM_CORRECTION'])) {
      return WalletTransactionCategoryKey.adminAdjustment;
    }
    if (_isCashDeposit(tx)) {
      return WalletTransactionCategoryKey.deposit;
    }
    if (_isCashWithdrawal(tx)) {
      return WalletTransactionCategoryKey.withdrawal;
    }
    if (tx.isCreditTransaction || tx.isCoinCreditTransaction) {
      return WalletTransactionCategoryKey.otherIncome;
    }
    return WalletTransactionCategoryKey.otherExpense;
  }

  static String _categoryLabel(WalletTransactionCategoryKey key) {
    switch (key) {
      case WalletTransactionCategoryKey.deposit:
        return 'Nạp tiền';
      case WalletTransactionCategoryKey.withdrawal:
        return 'Rút tiền';
      case WalletTransactionCategoryKey.coinPurchase:
        return 'Mua SkillCoin';
      case WalletTransactionCategoryKey.premiumPurchase:
        return 'Mua Premium';
      case WalletTransactionCategoryKey.coursePurchase:
        return 'Mua khóa học';
      case WalletTransactionCategoryKey.mentorTip:
        return 'Tip mentor';
      case WalletTransactionCategoryKey.mentorIncome:
        return 'Thu nhập mentor/course';
      case WalletTransactionCategoryKey.jobPayout:
        return 'Thu nhập job/escrow';
      case WalletTransactionCategoryKey.jobEscrow:
        return 'Phí job/ký quỹ';
      case WalletTransactionCategoryKey.refund:
        return 'Hoàn tiền/hoàn xu';
      case WalletTransactionCategoryKey.coinReward:
        return 'Thưởng xu';
      case WalletTransactionCategoryKey.adminAdjustment:
        return 'Điều chỉnh admin';
      case WalletTransactionCategoryKey.otherIncome:
        return 'Thu khác';
      case WalletTransactionCategoryKey.otherExpense:
        return 'Chi tiêu khác';
    }
  }

  static bool _isCashDeposit(WalletTransaction tx) {
    final type = tx.transactionType.toUpperCase();
    return tx.currencyType.toUpperCase() == 'CASH' &&
        (type.contains('DEPOSIT') || tx.isCreditTransaction);
  }

  static bool _isCashWithdrawal(WalletTransaction tx) {
    final type = tx.transactionType.toUpperCase();
    return tx.currencyType.toUpperCase() == 'CASH' &&
        (type.contains('WITHDRAWAL') ||
            type.contains('WITHDRAW') ||
            tx.isDebitTransaction);
  }

  static bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _shortDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}
