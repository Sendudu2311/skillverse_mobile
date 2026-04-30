import '../../core/exceptions/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/course_models.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get paginated list of courses
  Future<PageResponse<CourseSummaryDto>> getCourses({
    int page = 0,
    int size = 10,
    String? search,
    CourseStatus? status,
    CourseLevel? level,
    String? sortField,
    String sortDirection = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (search != null && search.isNotEmpty) queryParams['q'] = search;
      if (status != null) queryParams['status'] = status.name.toUpperCase();
      if (level != null) queryParams['level'] = level.name.toUpperCase();
      if (sortField != null) {
        queryParams['sort'] = '$sortField,$sortDirection';
      }

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/courses',
        queryParameters: queryParams,
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return PageResponse<CourseSummaryDto>.fromJson(
        response.data!,
        (json) => CourseSummaryDto.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách khóa học thất bại');
    }
  }

  /// Get course details by ID (summary)
  Future<CourseSummaryDto> getCourseById(int courseId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/courses/$courseId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return CourseSummaryDto.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin khóa học thất bại');
    }
  }

  /// Get full course detail by ID (includes learningObjectives, requirements, etc.)
  Future<CourseDetailDto> getCourseDetail(int courseId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/courses/$courseId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return CourseDetailDto.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin khóa học thất bại');
    }
  }

  /// Get courses by author
  Future<PageResponse<CourseSummaryDto>> getCoursesByAuthor(
    int authorId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/courses/author/$authorId',
        queryParameters: {'page': page, 'size': size},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return PageResponse<CourseSummaryDto>.fromJson(
        response.data!,
        (json) => CourseSummaryDto.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy khóa học của tác giả thất bại');
    }
  }

  /// Search courses - uses the same endpoint as getCourses with 'q' parameter
  Future<PageResponse<CourseSummaryDto>> searchCourses(
    String query, {
    int page = 0,
    int size = 10,
    CourseStatus? status,
  }) async {
    // Just use getCourses with search parameter
    return getCourses(page: page, size: size, search: query, status: status);
  }

  /// Purchase course with wallet balance
  /// POST /api/course-purchases/wallet
  /// Backend auto-enrolls the user after successful wallet deduction
  Future<Map<String, dynamic>> purchaseCourseWithWallet({
    required int courseId,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/course-purchases/wallet',
        data: {'courseId': courseId},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Mua khóa học bằng ví thất bại');
    }
  }
}
