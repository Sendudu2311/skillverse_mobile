import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/error/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/roadmap_package_models.dart';

/// Service for Roadmap Package (Offering / Purchase) API calls.
/// Learner-facing endpoints only.
class RoadmapPackageService {
  static final RoadmapPackageService _instance =
      RoadmapPackageService._internal();
  factory RoadmapPackageService() => _instance;
  RoadmapPackageService._internal();

  final ApiClient _apiClient = ApiClient();

  static const _offeringUrl = '/v1/roadmap-offerings';
  static const _purchaseUrl = '/v1/roadmap-purchases';

  // ─── Offerings (Read-only for Learner) ──────────────────────────────────

  /// Get all active offerings available for purchase.
  /// GET /v1/roadmap-offerings
  Future<List<RoadmapOfferingResponse>> getActiveOfferings() async {
    try {
      final response = await _apiClient.dio.get(_offeringUrl);
      if (response.data == null) return [];
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              RoadmapOfferingResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy danh sách gói roadmap thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get a single offering by ID.
  /// GET /v1/roadmap-offerings/{id}
  Future<RoadmapOfferingResponse> getOffering(int offeringId) async {
    try {
      final response = await _apiClient.dio
          .get<Map<String, dynamic>>('$_offeringUrl/$offeringId');
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu');
      }
      return RoadmapOfferingResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy chi tiết gói roadmap thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Purchases ─────────────────────────────────────────────────────────

  /// Purchase an offering.
  /// POST /v1/roadmap-purchases
  Future<RoadmapPurchaseResponse> purchase(
    CreateRoadmapPurchaseRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        _purchaseUrl,
        data: request.toJson(),
      );
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu phản hồi');
      }
      return RoadmapPurchaseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Mua gói roadmap thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get all my purchases.
  /// GET /v1/roadmap-purchases/my
  Future<List<RoadmapPurchaseResponse>> getMyPurchases() async {
    try {
      final response = await _apiClient.dio.get('$_purchaseUrl/my');
      if (response.data == null) return [];
      final list = response.data as List<dynamic>;
      return list
          .map((e) =>
              RoadmapPurchaseResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy danh sách gói đã mua thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Get a single purchase by ID.
  /// GET /v1/roadmap-purchases/{id}
  Future<RoadmapPurchaseResponse> getPurchase(int purchaseId) async {
    try {
      final response = await _apiClient.dio
          .get<Map<String, dynamic>>('$_purchaseUrl/$purchaseId');
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu');
      }
      return RoadmapPurchaseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Lấy chi tiết gói đã mua thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  /// Cancel a purchase.
  /// POST /v1/roadmap-purchases/{id}/cancel
  Future<RoadmapPurchaseResponse> cancelPurchase(int purchaseId) async {
    try {
      final response = await _apiClient.dio
          .post<Map<String, dynamic>>('$_purchaseUrl/$purchaseId/cancel');
      if (response.data == null) {
        throw UnknownException('Không có dữ liệu');
      }
      return RoadmapPurchaseResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Huỷ gói roadmap thất bại');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Lỗi không xác định');
    }
  }

  // ─── Error Handling ────────────────────────────────────────────────────

  AppException _handleDioError(DioException e, String defaultMessage) {
    debugPrint(
      '🛑 RoadmapPackageService Error: ${e.type} | ${e.response?.statusCode}',
    );
    if (e.error is AppException) return e.error as AppException;
    if (e.response?.data != null) {
      try {
        final dynamic data = e.response?.data;
        Map<String, dynamic>? errorMap;
        if (data is Map) {
          errorMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map) errorMap = Map<String, dynamic>.from(decoded);
        }
        if (errorMap != null) {
          final msg =
              errorMap['message'] ?? errorMap['error'] ?? errorMap['details'];
          if (msg != null) {
            return ServerException(
              msg.toString(),
              statusCode: e.response?.statusCode,
            );
          }
        }
      } catch (_) {}
    }
    return ServerException(defaultMessage, statusCode: e.response?.statusCode);
  }
}
