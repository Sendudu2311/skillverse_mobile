import 'package:dio/dio.dart';
import '../../core/exceptions/api_exception.dart';
import 'api_client.dart';
import '../models/roadmap_models.dart';

class RoadmapService {
  static final RoadmapService _instance = RoadmapService._internal();
  factory RoadmapService() => _instance;
  RoadmapService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get all roadmaps
  Future<List<Roadmap>> getRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/roadmaps',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!.map((json) => Roadmap.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy danh sách roadmap thất bại: ${e.toString()}');
    }
  }

  /// Get roadmap by ID
  Future<Roadmap> getRoadmapById(int roadmapId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/roadmaps/$roadmapId',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return Roadmap.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy thông tin roadmap thất bại: ${e.toString()}');
    }
  }

  /// Get roadmaps by category
  Future<List<Roadmap>> getRoadmapsByCategory(String category) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/roadmaps/category/$category',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!.map((json) => Roadmap.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy roadmap theo danh mục thất bại: ${e.toString()}');
    }
  }

  /// Update roadmap progress
  Future<Roadmap> updateRoadmapProgress(int roadmapId, int completedSteps) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/roadmaps/$roadmapId/progress',
        data: {'completedSteps': completedSteps},
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return Roadmap.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cập nhật tiến độ roadmap thất bại: ${e.toString()}');
    }
  }

  /// Get user's roadmap progress
  Future<List<Roadmap>> getUserRoadmaps() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/roadmaps/user',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return response.data!.map((json) => Roadmap.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Lấy roadmap của người dùng thất bại: ${e.toString()}');
    }
  }

  /// Start a roadmap for user
  Future<Roadmap> startRoadmap(int roadmapId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/roadmaps/$roadmapId/start',
      );

      if (response.data == null) {
        throw ApiException('Không có dữ liệu phản hồi');
      }

      return Roadmap.fromJson(response.data!);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bắt đầu roadmap thất bại: ${e.toString()}');
    }
  }
}