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

  /// Get all public (OPEN) long-term jobs (non-paginated)
  Future<List<JobPostingResponse>> getPublicJobs() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>('/jobs/public');

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map(
            (json) => JobPostingResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách việc làm thất bại');
    }
  }

  /// Get public long-term jobs with pagination
  /// GET /api/jobs/public/paged
  Future<JobPageResponse<JobPostingResponse>> getPublicJobsPaged({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/jobs/public/paged',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobPageResponse<JobPostingResponse>.fromJson(
        response.data!,
        (json) => JobPostingResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách việc làm thất bại');
    }
  }

  /// Get public short-term jobs with pagination
  /// GET /api/short-term-jobs/public/paged
  Future<JobPageResponse<ShortTermJobResponse>>
  getPublicShortTermJobsPaged({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/short-term-jobs/public/paged',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobPageResponse<ShortTermJobResponse>.fromJson(
        response.data!,
        (json) => ShortTermJobResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách việc ngắn hạn thất bại',
      );
    }
  }

  /// Get my short-term applications with pagination
  /// GET /api/short-term-jobs/my-applications/paged
  Future<JobPageResponse<ShortTermApplicationResponse>>
  getMyShortTermApplicationsPaged({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/short-term-jobs/my-applications/paged',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return JobPageResponse<ShortTermApplicationResponse>.fromJson(
        response.data!,
        (json) => ShortTermApplicationResponse.fromJson(
          json as Map<String, dynamic>,
        ),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách đơn ứng tuyển ngắn hạn thất bại',
      );
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
      throw ApiException('Lấy thông tin việc làm thất bại');
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
      throw ApiException('Ứng tuyển thất bại');
    }
  }

  /// Get current user's long-term applications (non-paginated)
  Future<List<JobApplicationResponse>> getMyApplications() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/jobs/my-applications',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!
          .map(
            (json) =>
                JobApplicationResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách đơn ứng tuyển thất bại',
      );
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
          .map(
            (json) =>
                ShortTermJobResponse.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách việc ngắn hạn thất bại',
      );
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
        (json) => ShortTermJobResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Tìm kiếm việc làm thất bại');
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
        'Lấy thông tin việc ngắn hạn thất bại',
      );
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
      throw ApiException('Ứng tuyển việc ngắn hạn thất bại');
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
          .map(
            (json) => ShortTermApplicationResponse.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Lấy danh sách đơn ứng tuyển ngắn hạn thất bại',
      );
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
      throw ApiException('Rút đơn ứng tuyển thất bại');
    }
  }

  // ==================== HANDOVER / WORK REVIEW ====================

  /// Submit deliverables (worker bàn giao công việc)
  /// POST /api/short-term-jobs/applications/submit-deliverables
  Future<ShortTermApplicationResponse> submitDeliverables(
    SubmitDeliverableRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/applications/submit-deliverables',
        data: request.toJson(),
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e, 'Bàn giao công việc thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bàn giao công việc thất bại');
    }
  }

  /// Candidate responds to an offer (OFFER_ACCEPTED or OFFER_REJECTED).
  /// When rejecting, counterSalaryAmount and counterAdditionalRequirements
  /// carry the candidate's structured counter-offer per the new backend schema.
  /// PATCH /api/jobs/applications/{applicationId}/status
  Future<JobApplicationResponse> respondToOffer({
    required int applicationId,
    required bool accept,
    String? candidateOfferResponse,
    int? counterSalaryAmount,
    String? counterAdditionalRequirements,
  }) async {
    try {
      final response = await _apiClient.dio.patch<Map<String, dynamic>>(
        '/jobs/applications/$applicationId/status',
        data: {
          'status': accept ? 'OFFER_ACCEPTED' : 'OFFER_REJECTED',
          if (candidateOfferResponse != null)
            'candidateOfferResponse': candidateOfferResponse,
          if (!accept && counterSalaryAmount != null)
            'counterSalaryAmount': counterSalaryAmount,
          if (!accept && counterAdditionalRequirements != null)
            'counterAdditionalRequirements': counterAdditionalRequirements,
        },
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return JobApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Phản hồi đề nghị thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Phản hồi đề nghị thất bại');
    }
  }

  /// Select a candidate for the job (recruiter)
  /// POST /api/short-term-jobs/{jobId}/select-candidate/{applicationId}
  Future<ShortTermApplicationResponse> selectCandidate(
    int jobId,
    int applicationId,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/$jobId/select-candidate/$applicationId',
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Chọn ứng viên thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chọn ứng viên thất bại');
    }
  }

  /// Approve submitted work (recruiter)
  /// POST /api/short-term-jobs/applications/{applicationId}/approve
  Future<ShortTermApplicationResponse> approveWork(
    int applicationId, {
    String? message,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (message != null) queryParams['message'] = message;

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/applications/$applicationId/approve',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Duyệt bàn giao thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Duyệt bàn giao thất bại');
    }
  }

  /// Request revision on submitted work (recruiter)
  /// POST /api/short-term-jobs/applications/request-revision
  Future<ShortTermApplicationResponse> requestRevision({
    required int applicationId,
    required String note,
    List<String>? specificIssues,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/applications/request-revision',
        data: {
          'applicationId': applicationId,
          'note': note,
          if (specificIssues != null) 'specificIssues': specificIssues,
        },
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Yêu cầu sửa thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Yêu cầu sửa thất bại');
    }
  }

  /// Request admin cancellation review after ≥5 revisions (recruiter)
  /// POST /api/short-term-jobs/applications/request-cancellation-review
  Future<ShortTermApplicationResponse> requestCancellationReview(
    int applicationId,
    String reason,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/applications/request-cancellation-review',
        data: {'applicationId': applicationId, 'reason': reason},
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Gửi yêu cầu hủy thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gửi yêu cầu hủy thất bại');
    }
  }

  /// Accept cancellation requested by recruiter (worker)
  /// POST /api/short-term-jobs/applications/{applicationId}/accept-cancellation
  Future<ShortTermApplicationResponse> acceptCancellation(
    int applicationId,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/applications/$applicationId/accept-cancellation',
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermApplicationResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Chấp nhận hủy thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Chấp nhận hủy thất bại');
    }
  }

  /// Mark job as completed (recruiter)
  /// POST /api/short-term-jobs/{jobId}/complete
  Future<ShortTermJobResponse> completeJob(int jobId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/$jobId/complete',
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermJobResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_extractErrorMessage(e, 'Hoàn tất job thất bại'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Hoàn tất job thất bại');
    }
  }

  /// Mark job as paid (recruiter)
  /// POST /api/short-term-jobs/{jobId}/mark-paid
  Future<ShortTermJobResponse> markAsPaid(int jobId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/short-term-jobs/$jobId/mark-paid',
      );
      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }
      return ShortTermJobResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e, 'Xác nhận thanh toán thất bại'),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Xác nhận thanh toán thất bại');
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
