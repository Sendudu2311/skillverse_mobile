import '../../../core/exceptions/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';
import '../models/wallet_models.dart';

/// Service for Wallet-specific API calls
class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== WALLET INFO ====================

  /// Get current user's wallet
  /// GET /wallet/my-wallet
  Future<WalletResponse> getMyWallet() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/wallet/my-wallet',
      );

      if (response.data == null) {
        throw ApiException('No wallet data received');
      }

      return WalletResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch wallet: ${e.toString()}');
    }
  }

  // ==================== STATISTICS ====================

  /// Get wallet statistics
  /// GET /wallet/statistics
  Future<WalletStatistics> getStatistics() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/wallet/statistics',
      );

      if (response.data == null) {
        throw ApiException('No statistics data received');
      }

      return WalletStatistics.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch wallet statistics: ${e.toString()}');
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Get transaction history with pagination
  /// GET /wallet/transactions?page={page}&size={size}
  Future<List<WalletTransaction>> getTransactions({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/wallet/transactions',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data == null) {
        return [];
      }

      final content = response.data!['content'] as List<dynamic>?;
      if (content == null) return [];

      return content
          .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch transactions: ${e.toString()}');
    }
  }

  // ==================== DEPOSIT ====================

  /// Create deposit payment via PayOS
  /// POST /wallet/deposit
  Future<Map<String, dynamic>> createDeposit({
    required double amount,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/wallet/deposit',
        data: {
          'amount': amount,
          'paymentMethod': 'PAYOS',
          'returnUrl': returnUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.data == null) {
        throw ApiException('No deposit response received');
      }

      return response.data!;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create deposit: ${e.toString()}');
    }
  }

  // ==================== COIN PURCHASE ====================

  /// Get available coin packages
  /// GET /wallet/coins/packages
  Future<List<Map<String, dynamic>>> getCoinPackages() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/wallet/coins/packages',
      );

      if (response.data == null) return [];

      return response.data!.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch coin packages: ${e.toString()}');
    }
  }

  /// Purchase coins with wallet cash
  /// POST /wallet/coins/purchase-with-cash
  Future<Map<String, dynamic>> purchaseCoinsWithCash({
    required int coinAmount,
    String? packageId,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/wallet/coins/purchase-with-cash',
        data: {
          'coinAmount': coinAmount,
          'paymentMethod': 'WALLET_CASH',
          if (packageId != null) 'packageId': packageId,
        },
      );

      if (response.data == null) {
        throw ApiException('No purchase response received');
      }

      return response.data!;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to purchase coins: ${e.toString()}');
    }
  }

  // ==================== WITHDRAWAL ====================

  /// Create withdrawal request
  /// POST /wallet/withdraw/request
  Future<Map<String, dynamic>> createWithdrawalRequest({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    String? bankBranch,
    required String transactionPin,
    String? twoFactorCode,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/wallet/withdraw/request',
        data: {
          'amount': amount,
          'bankName': bankName,
          'bankAccountNumber': bankAccountNumber,
          'bankAccountName': bankAccountName,
          if (bankBranch != null) 'bankBranch': bankBranch,
          'transactionPin': transactionPin,
          if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.data == null) {
        throw ApiException('No withdrawal response received');
      }

      return response.data!;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create withdrawal request: ${e.toString()}');
    }
  }
}
