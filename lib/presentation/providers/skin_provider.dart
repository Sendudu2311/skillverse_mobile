import 'package:flutter/material.dart';
import '../../data/models/skin_models.dart';
import '../../data/services/skin_service.dart';
import '../../core/utils/error_handler.dart';

class SkinProvider extends ChangeNotifier {
  final SkinService _skinService = SkinService();

  // State
  List<MeowlSkin> _allSkins = [];
  List<MeowlSkin> _mySkins = [];
  List<MeowlSkin> _leaderboard = [];
  MeowlSkin? _selectedSkin;

  bool _isLoading = false;
  bool _isLoadingLeaderboard = false;
  String? _error;
  String? _successMessage;

  // Getters
  List<MeowlSkin> get allSkins => _allSkins;
  List<MeowlSkin> get mySkins => _mySkins;
  List<MeowlSkin> get leaderboard => _leaderboard;
  MeowlSkin? get selectedSkin => _selectedSkin;
  bool get isLoading => _isLoading;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get error => _error;
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allSkins = await _skinService.getAllSkins();
      _selectedSkin = _allSkins.cast<MeowlSkin?>().firstWhere(
        (s) => s?.selected == true,
        orElse: () => null,
      );
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('Error loading skins: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    _error = null;
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
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Select/equip a skin
  Future<bool> selectSkin(String skinCode) async {
    _error = null;
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
      _error = ErrorHandler.getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([loadAllSkins(), loadLeaderboard()]);
  }
}
