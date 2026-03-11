import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/job_models.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== LONG-TERM JOBS ====================

  /// Get all public (OPEN) long-term jobs
  Future<List<JobPostingResponse>> getPublicJobs() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>('/jobs/public');

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) =>
              JobPostingResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách việc làm thất bại: ${e.toString()}');
    }
  }

  /// Get job details by ID
  Future<JobPostingResponse> getJobDetails(int jobId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/jobs/$jobId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobPostingResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Lấy thông tin việc làm thất bại: ${e.toString()}');
    }
  }

  /// Apply to a long-term job (USER only)
  Future<JobApplicationResponse> applyToJob(
    int jobId,
    ApplyJobRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/apply',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Ứng tuyển thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ứng tuyển thất bại: ${e.toString()}');
    }
  }

  /// Get current user's long-term job applications
  Future<List<JobApplicationResponse>> getMyApplications() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/jobs/my-applications',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) =>
              JobApplicationResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Lấy danh sách đơn ứng tuyển thất bại: ${e.toString()}');
    }
  }

  // ==================== SHORT-TERM JOBS ====================

  /// Get all published short-term jobs
  Future<List<ShortTermJobResponse>> getPublicShortTermJobs() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/short-term-jobs/public',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) =>
              ShortTermJobResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Lấy danh sách việc ngắn hạn thất bại: ${e.toString()}');
    }
  }

  /// Search short-term jobs with filters
  Future<JobPageResponse<ShortTermJobResponse>> searchShortTermJobs({
    String? search,
    double? minBudget,
    double? maxBudget,
    bool? isRemote,
    String? urgency,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minBudget != null) queryParams['minBudget'] = minBudget;
      if (maxBudget != null) queryParams['maxBudget'] = maxBudget;
      if (isRemote != null) queryParams['isRemote'] = isRemote;
      if (urgency != null) queryParams['urgency'] = urgency;

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/short-term-jobs/search',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobPageResponse<ShortTermJobResponse>.fromJson(
        response.data!,
        (json) =>
            ShortTermJobResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tìm kiếm việc làm thất bại: ${e.toString()}');
    }
  }

  /// Get short-term job details by ID
  Future<ShortTermJobResponse> getShortTermJobDetails(int jobId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/short-term-jobs/$jobId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ShortTermJobResponse.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Lấy thông tin việc ngắn hạn thất bại: ${e.toString()}');
    }
  }

  /// Apply to a short-term job (USER only)
  Future<ShortTermApplicationResponse> applyToShortTermJob(
    int jobId,
    ApplyShortTermJobRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/$jobId/apply',
        data: request.toJson(),
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Ứng tuyển thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Ứng tuyển việc ngắn hạn thất bại: ${e.toString()}');
    }
  }

  /// Get current user's short-term job applications
  Future<List<ShortTermApplicationResponse>>
      getMyShortTermApplications() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/short-term-jobs/my-applications',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map((json) => ShortTermApplicationResponse.fromJson(
              json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          'Lấy danh sách đơn ứng tuyển ngắn hạn thất bại: ${e.toString()}');
    }
  }

  /// Withdraw a short-term job application
  Future<void> withdrawShortTermApplication(int applicationId) async {
    try {
      await _apiClient.dio.delete(
        '/short-term-jobs/applications/$applicationId/withdraw',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Rút đơn ứng tuyển thất bại: ${e.toString()}');
    }
  }

  /// Extract a user-friendly error message from DioException
  String _extractErrorMessage(DioException e, String fallback) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        // Backend returns {"message": "..."}
        return data['message'] as String? ?? fallback;
      }
    } catch (_) {}
    
    // Map common HTTP status codes
    final statusCode = e.response?.statusCode;
    if (statusCode == 409 || statusCode == 500) {
      return 'Bạn đã ứng tuyển công việc này rồi';
    }
    if (statusCode == 400) return 'Dữ liệu không hợp lệ';
    if (statusCode == 403) return 'Không có quyền thực hiện';
    if (statusCode == 404) return 'Không tìm thấy công việc';
    return fallback;
  }
}
