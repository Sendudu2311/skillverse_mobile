import 'package:dio/dio.dart';
import '../models/skin_models.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/error_handler.dart';

class SkinService {
  final ApiClient _apiClient = ApiClient();

  /// Get all skins with ownership status
  Future<List<MeowlSkin>> getAllSkins() async {
    try {
      final response = await _apiClient.get('/skins');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MeowlSkin.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get only skins owned by the user
  Future<List<MeowlSkin>> getMySkins() async {
    try {
      final response = await _apiClient.get('/skins/my-skins');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MeowlSkin.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get skins leaderboard sorted by purchase count
  Future<List<MeowlSkin>> getLeaderboard() async {
    try {
      final response = await _apiClient.get('/skins/leaderboard');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => MeowlSkin.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Purchase a skin using wallet balance
  Future<String> purchaseSkin(String skinCode) async {
    try {
      final response = await _apiClient.post(
        '/skins/$skinCode/purchase',
        options: Options(responseType: ResponseType.plain),
      );
      // API returns plain text on success
      if (response.data is String) {
        return response.data as String;
      }
      return 'Mua skin thành công';
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Select/equip a skin
  Future<String> selectSkin(String skinCode) async {
    try {
      final response = await _apiClient.post(
        '/skins/$skinCode/select',
        options: Options(responseType: ResponseType.plain),
      );
      // API returns plain text on success
      if (response.data is String) {
        return response.data as String;
      }
      return 'Đã chọn skin';
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle errors
  Exception _handleError(dynamic error) {
    return Exception(ErrorHandler.getErrorMessage(error));
  }
}
