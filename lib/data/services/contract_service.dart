import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/contract_models.dart';

class ContractService {
  static final ContractService _instance = ContractService._internal();
  factory ContractService() => _instance;
  ContractService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== CONTRACT QUERIES ====================

  /// Get contracts for current user by role (CANDIDATE or EMPLOYER).
  Future<List<ContractResponse>> getMyContracts(String role) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/contracts/my',
        queryParameters: {'role': role},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) =>
              ContractResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách hợp đồng thất bại');
    }
  }

  /// Get contract detail by ID.
  Future<ContractResponse> getContractById(int id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/contracts/$id',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ContractResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy chi tiết hợp đồng thất bại');
    }
  }

  // ==================== CONTRACT ACTIONS ====================

  /// Sign or reject a contract.
  Future<ContractResponse> signContract(
    int id,
    SignContractRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/contracts/$id/sign',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ContractResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Ký hợp đồng thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ký hợp đồng thất bại');
    }
  }

  /// Reject a contract.
  Future<ContractResponse> rejectContract(int id, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/contracts/$id/reject',
        queryParameters: reason != null ? {'reason': reason} : null,
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ContractResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e, 'Từ chối hợp đồng thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Từ chối hợp đồng thất bại');
    }
  }

  // ==================== ONBOARDING ====================

  /// Submit onboarding info (CCCD text + bank account).
  Future<OnboardingInfoResponse> submitOnboardingInfo(
    int applicationId,
    OnboardingInfoRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/contracts/applications/$applicationId/onboarding',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return OnboardingInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e, 'Cập nhật thông tin Onboarding thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cập nhật thông tin Onboarding thất bại');
    }
  }

  /// Get onboarding info for an application.
  Future<OnboardingInfoResponse?> getOnboardingInfo(int applicationId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/contracts/applications/$applicationId/onboarding',
      );

      if (response.data == null) return null;

      return OnboardingInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, '');
      if (message.contains('No onboarding data found')) {
        return null;
      }
      throw ApiException(
        _extractErrorMessage(e, 'Lấy thông tin Onboarding thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin Onboarding thất bại');
    }
  }

  /// Get the most recently submitted onboarding info for the candidate to reuse.
  Future<OnboardingInfoResponse?> getLatestOnboardingInfo() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/contracts/onboarding-info/me',
      );

      if (response.data == null) return null;

      return OnboardingInfoResponse.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204 || e.response?.statusCode == 404) {
        return null;
      }
      throw ApiException(
        _extractErrorMessage(e, 'Lấy thông tin Onboarding gần nhất thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin Onboarding gần nhất thất bại');
    }
  }

  // ==================== HELPERS ====================

  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? fallback;
      }
    } catch (_) {}
    final statusCode = e.response?.statusCode;
    if (statusCode == 400) return 'Dữ liệu không hợp lệ';
    if (statusCode == 403) return 'Không có quyền thực hiện';
    if (statusCode == 404) return 'Không tìm thấy hợp đồng';
    if (statusCode == 409) return 'Hợp đồng đã được xử lý trước đó';
    return fallback;
  }
}
