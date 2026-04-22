import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

class PurchaseService extends ChangeNotifier {
  static const String removeAdsId = 'remove_ads_permanent';
  
  static PurchaseService? _instance;
  final InAppPurchase _iap = InAppPurchase.instance;
  late final StorageService _storage;
  
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  bool _isPurchasing = false;

  PurchaseService._();

  static Future<PurchaseService> getInstance() async {
    if (_instance == null) {
      _instance = PurchaseService._();
      _instance!._storage = await StorageService.getInstance();
      await _instance!._init();
    }
    return _instance!;
  }

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  bool get isPurchasing => _isPurchasing;
  bool get hasRemovedAds => _storage.isAdsRemoved();

  Future<void> _init() async {
    _isAvailable = await _iap.isAvailable();
    
    if (_isAvailable) {
      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('IAP Error: $error'),
      );
      
      // Load product details
      await loadProducts();
    }
  }

  Future<void> loadProducts() async {
    const Set<String> ids = {removeAdsId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    
    if (response.error == null) {
      _products = response.productDetails;
      notifyListeners();
    }
  }

  Future<void> buyRemoveAds() async {
    if (!_isAvailable) return;
    
    ProductDetails? product;
    for (final p in _products) {
      if (p.id == removeAdsId) {
        product = p;
        break;
      }
    }

    if (product == null) {
      debugPrint('Product $removeAdsId not found in store.');
      return;
    }

    _isPurchasing = true;
    notifyListeners();

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _isPurchasing = true;
      } else {
        if (purchase.status == PurchaseStatus.error) {
          debugPrint('Purchase Error: ${purchase.error}');
        } else if (purchase.status == PurchaseStatus.purchased || 
                   purchase.status == PurchaseStatus.restored) {
          
          // Verify and deliver the product
          if (purchase.productID == removeAdsId) {
            _storage.setAdsRemoved(true);
          }
        }
        
        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
        _isPurchasing = false;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
