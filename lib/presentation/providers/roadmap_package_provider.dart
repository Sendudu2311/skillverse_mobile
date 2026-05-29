import 'package:flutter/foundation.dart';
import '../../data/models/roadmap_package_models.dart';
import '../../data/services/roadmap_package_service.dart';
import '../../core/utils/error_handler.dart';

/// Provider for Roadmap Packages — offerings and learner purchases.
class RoadmapPackageProvider extends ChangeNotifier {
  final RoadmapPackageService _service = RoadmapPackageService();

  // ─── State ──────────────────────────────────────────────────────────────

  List<RoadmapOfferingResponse> _offerings = [];
  List<RoadmapPurchaseResponse> _purchases = [];

  bool _isLoadingOfferings = false;
  bool _isLoadingPurchases = false;
  bool _isPurchasing = false;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────────────────

  List<RoadmapOfferingResponse> get offerings => _offerings;
  List<RoadmapPurchaseResponse> get purchases => _purchases;
  bool get isLoadingOfferings => _isLoadingOfferings;
  bool get isLoadingPurchases => _isLoadingPurchases;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;

  /// IDs of offerings that the learner already purchased (any status).
  Set<int> get purchasedOfferingIds =>
      _purchases.map((p) => p.offeringId).toSet();

  /// Active purchases only (not cancelled/refunded).
  List<RoadmapPurchaseResponse> get activePurchases => _purchases
      .where((p) =>
          p.status == RoadmapPurchaseStatus.active ||
          p.status == RoadmapPurchaseStatus.pendingPayment)
      .toList();

  // ─── Load Offerings ─────────────────────────────────────────────────────

  /// Fetch all active offerings from backend.
  Future<void> loadOfferings() async {
    if (_isLoadingOfferings) return;

    _isLoadingOfferings = true;
    _error = null;
    notifyListeners();

    try {
      _offerings = await _service.getActiveOfferings();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('RoadmapPackageProvider.loadOfferings error: $e');
    } finally {
      _isLoadingOfferings = false;
      notifyListeners();
    }
  }

  // ─── Load Purchases ─────────────────────────────────────────────────────

  /// Fetch all purchases for current learner.
  Future<void> loadPurchases() async {
    if (_isLoadingPurchases) return;

    _isLoadingPurchases = true;
    _error = null;
    notifyListeners();

    try {
      _purchases = await _service.getMyPurchases();
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('RoadmapPackageProvider.loadPurchases error: $e');
    } finally {
      _isLoadingPurchases = false;
      notifyListeners();
    }
  }

  // ─── Purchase ───────────────────────────────────────────────────────────

  /// Purchase an offering. Returns the new purchase response or null on error.
  Future<RoadmapPurchaseResponse?> purchaseOffering(int offeringId) async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    try {
      final purchase = await _service.purchase(
        CreateRoadmapPurchaseRequest(offeringId: offeringId),
      );
      // Reload purchases to refresh state
      await loadPurchases();
      return purchase;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('RoadmapPackageProvider.purchaseOffering error: $e');
      return null;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  // ─── Cancel ─────────────────────────────────────────────────────────────

  /// Cancel a purchase. Returns true on success.
  Future<bool> cancelPurchase(int purchaseId) async {
    _error = null;
    notifyListeners();

    try {
      await _service.cancelPurchase(purchaseId);
      await loadPurchases();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      debugPrint('RoadmapPackageProvider.cancelPurchase error: $e');
      return false;
    }
  }

  // ─── Load All ───────────────────────────────────────────────────────────

  /// Load both offerings and purchases in parallel.
  Future<void> loadAll() async {
    await Future.wait([loadOfferings(), loadPurchases()]);
  }

  // ─── Clear ──────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
