import 'package:flutter/material.dart';
import '../../data/models/dashboard_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/wallet_service.dart';

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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showBalance => _showBalance;

  // Computed getters
  int get cashBalance => _wallet?.cashBalance ?? 0;
  int get coinBalance => _wallet?.coinBalance ?? 0;
  int get totalDeposited => _wallet?.totalDeposited ?? 0;
  int get totalWithdrawn => _wallet?.totalWithdrawn ?? 0;
  int get totalCoinsEarned => _wallet?.totalCoinsEarned ?? 0;
  int get totalCoinsSpent => _wallet?.totalCoinsSpent ?? 0;
  String get walletStatus => _wallet?.status ?? 'UNKNOWN';
  bool get hasBankAccount => _wallet?.hasBankAccount ?? false;

  /// Total assets in VND (cash + coin value)
  int get totalAssets => cashBalance + (coinBalance * coinToVndRate);

  /// Cash percentage of total assets
  double get cashPercent =>
      totalAssets > 0 ? (cashBalance / totalAssets) * 100 : 0;

  /// Coin percentage of total assets
  double get coinPercent =>
      totalAssets > 0
          ? ((coinBalance * coinToVndRate) / totalAssets) * 100
          : 0;

  /// Coin value in VND
  int get coinValueInVnd => coinBalance * coinToVndRate;

  /// Net cash flow
  int get netCashFlow => totalDeposited - totalWithdrawn;

  // Stats getters (from statistics API)
  int get statsTotalDeposited => _statistics?.totalDeposited ?? totalDeposited;
  int get statsTotalWithdrawn => _statistics?.totalWithdrawn ?? totalWithdrawn;
  int get statsTotalCoinsEarned =>
      _statistics?.totalCoinsEarned ?? totalCoinsEarned;
  int get statsTotalCoinsSpent =>
      _statistics?.totalCoinsSpent ?? totalCoinsSpent;
  int get statsTransactionCount => _statistics?.transactionCount ?? 0;

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
        _walletService.getStatistics().then<WalletStatistics?>((v) => v).catchError((_) => null),
        _walletService.getTransactions(page: 0, size: 5).catchError((_) => <WalletTransaction>[]),
      ]);

      _wallet = results[0] as WalletResponse;
      _statistics = results[1] as WalletStatistics?;
      _transactions = results[2] as List<WalletTransaction>;
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu ví: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    await loadAll();
  }
}
