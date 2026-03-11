import 'package:flutter/material.dart';
import '../../core/mixins/provider_loading_mixin.dart';
import '../../data/models/skin_models.dart';
import '../../data/services/skin_service.dart';
import '../../core/utils/error_handler.dart';

/// Skin Provider
///
/// Uses [LoadingStateProviderMixin] to auto-manage primary loading state:
/// - `isLoading` / `setLoading(bool)` — primary loading state (loadAllSkins)
/// - `hasError` / `errorMessage` / `setError(String?)` — error state
/// - `executeAsync()` — try/catch/loading wrapper
/// - `resetState()` — clear loading + error
///
/// Secondary loading (`_isLoadingLeaderboard`) managed separately.
class SkinProvider extends ChangeNotifier with LoadingStateProviderMixin {
  final SkinService _skinService = SkinService();

  // State (chỉ giữ domain data — primary loading/error do mixin quản lý)
  List<MeowlSkin> _allSkins = [];
  List<MeowlSkin> _mySkins = [];
  List<MeowlSkin> _leaderboard = [];
  MeowlSkin? _selectedSkin;

  bool _isLoadingLeaderboard = false;
  String? _successMessage;

  // Getters
  List<MeowlSkin> get allSkins => _allSkins;
  List<MeowlSkin> get mySkins => _mySkins;
  List<MeowlSkin> get leaderboard => _leaderboard;
  MeowlSkin? get selectedSkin => _selectedSkin;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get error => errorMessage; // Alias for backward compatibility
  String? get successMessage => _successMessage;

  // Filtered getters
  List<MeowlSkin> get freeSkins => _allSkins.where((s) => s.isFree).toList();

  List<MeowlSkin> get commonSkins =>
      _allSkins.where((s) => s.rarity == SkinRarity.common).toList();

  List<MeowlSkin> get rareSkins =>
      _allSkins.where((s) => s.rarity == SkinRarity.rare).toList();

  List<MeowlSkin> get legendarySkins =>
      _allSkins.where((s) => s.rarity == SkinRarity.legendary).toList();

  List<MeowlSkin> get ownedSkins => _allSkins.where((s) => s.owned).toList();

  // Top 3 for Hall of Fame
  List<MeowlSkin> get hallOfFame => _leaderboard.take(3).toList();

  // #4-#10 for Rising Stars
  List<MeowlSkin> get risingStars => _leaderboard.skip(3).take(7).toList();

  /// Load all skins
  Future<void> loadAllSkins() async {
    await executeAsync(() async {
      _allSkins = await _skinService.getAllSkins();
      _selectedSkin = _allSkins.cast<MeowlSkin?>().firstWhere(
        (s) => s?.selected == true,
        orElse: () => null,
      );
      notifyListeners();
    }, errorMessageBuilder: (e) {
      debugPrint('Error loading skins: $e');
      return ErrorHandler.getErrorMessage(e);
    });
  }

  /// Load my skins only
  Future<void> loadMySkins() async {
    try {
      _mySkins = await _skinService.getMySkins();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my skins: $e');
    }
  }

  /// Load leaderboard
  Future<void> loadLeaderboard() async {
    _isLoadingLeaderboard = true;
    notifyListeners();

    try {
      _leaderboard = await _skinService.getLeaderboard();
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  /// Purchase a skin
  Future<bool> purchaseSkin(String skinCode) async {
    clearError();
    _successMessage = null;

    try {
      final message = await _skinService.purchaseSkin(skinCode);
      _successMessage = message;

      // Update local state
      final index = _allSkins.indexWhere((s) => s.skinCode == skinCode);
      if (index != -1) {
        _allSkins[index] = _allSkins[index].copyWith(owned: true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  /// Select/equip a skin
  Future<bool> selectSkin(String skinCode) async {
    clearError();
    _successMessage = null;

    try {
      final message = await _skinService.selectSkin(skinCode);
      _successMessage = message;

      // Update local state - deselect current, select new
      for (int i = 0; i < _allSkins.length; i++) {
        if (_allSkins[i].selected) {
          _allSkins[i] = _allSkins[i].copyWith(selected: false);
        }
        if (_allSkins[i].skinCode == skinCode) {
          _allSkins[i] = _allSkins[i].copyWith(selected: true);
          _selectedSkin = _allSkins[i];
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      setError(ErrorHandler.getErrorMessage(e));
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    clearError();
    _successMessage = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadAllSkins(), loadLeaderboard()]);
  }
}
