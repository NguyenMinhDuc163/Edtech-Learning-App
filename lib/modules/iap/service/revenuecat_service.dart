import 'package:ed_tech/core/constants/api_path.dart';
import 'package:ed_tech/modules/iap/model/iap_models.dart';
import 'package:ed_tech/modules/iap/service/iap_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ed_tech/core/ads/ad_frequency_manager.dart';

class IapException implements Exception {
  const IapException(this.code, this.message, {this.cancelled = false});

  final String code;
  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  String? _configuredUserId;
  final Map<String, StoreProduct> _products = {};

  Future<void> configure(IapConfig config) async {
    if (!IapPlatform.isSupported) {
      throw const IapException(
        'unsupported_platform',
        'IAP is not supported on this platform.',
      );
    }
    if (config.revenueCatAppUserId.isEmpty) {
      throw const IapException(
        'invalid_user',
        'The purchase identity is unavailable.',
      );
    }

    final apiKey =
        defaultTargetPlatform == TargetPlatform.iOS
            ? ApiPath.revenueCatIosPublicApiKey
            : ApiPath.revenueCatAndroidPublicApiKey;
    if (apiKey.isEmpty || apiKey.contains('REPLACE_WITH')) {
      throw const IapException(
        'missing_api_key',
        'RevenueCat is not configured for this app.',
      );
    }

    try {
      if (!await Purchases.isConfigured) {
        final configuration = PurchasesConfiguration(apiKey)
          ..appUserID = config.revenueCatAppUserId;
        await Purchases.configure(configuration);
      } else {
        final currentUserId = await Purchases.appUserID;
        if (currentUserId != config.revenueCatAppUserId) {
          await Purchases.logIn(config.revenueCatAppUserId);
        }
      }
      _configuredUserId = config.revenueCatAppUserId;
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
    } on PlatformException catch (error) {
      throw _mapError(error);
    }
  }

  Future<StoreProduct> getProduct(String productId) async {
    final cached = _products[productId];
    if (cached != null) return cached;
    _ensureConfigured();

    try {
      final products = await Purchases.getProducts([
        productId,
      ], productCategory: ProductCategory.nonSubscription);
      if (products.isEmpty) {
        throw const IapException(
          'product_not_found',
          'This course is not available in the store.',
        );
      }
      final product = products.first;
      _products[productId] = product;
      return product;
    } on PlatformException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> purchase(StoreProduct product) async {
    _ensureConfigured();
    AdFrequencyManager.instance.isPaymentFlowActive = true;
    try {
      await Purchases.purchase(PurchaseParams.storeProduct(product));
    } on PlatformException catch (error) {
      throw _mapError(error);
    } finally {
      AdFrequencyManager.instance.isPaymentFlowActive = false;
    }
  }

  Future<void> restorePurchases() async {
    _ensureConfigured();
    try {
      await Purchases.restorePurchases();
    } on PlatformException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> clearLocalIdentity() async {
    _configuredUserId = null;
    _products.clear();
    if (!IapPlatform.isSupported) return;
    try {
      if (await Purchases.isConfigured) await Purchases.logOut();
    } on PlatformException {
      // Local guards still prevent access until the next authenticated login.
    }
  }

  void _ensureConfigured() {
    if (_configuredUserId == null) {
      throw const IapException(
        'not_configured',
        'RevenueCat has not been configured.',
      );
    }
  }

  IapException _mapError(PlatformException error) {
    final code = PurchasesErrorHelper.getErrorCode(error);
    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return const IapException(
          'purchase_cancelled',
          'Purchase cancelled.',
          cancelled: true,
        );
      case PurchasesErrorCode.paymentPendingError:
        return const IapException(
          'payment_pending',
          'The store is still processing this purchase.',
        );
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return const IapException(
          'already_purchased',
          'This item has already been purchased. Restore purchases to continue.',
        );
      case PurchasesErrorCode.purchaseNotAllowedError:
      case PurchasesErrorCode.insufficientPermissionsError:
        return const IapException(
          'purchase_not_allowed',
          'Purchases are not allowed on this device.',
        );
      case PurchasesErrorCode.networkError:
      case PurchasesErrorCode.offlineConnectionError:
        return const IapException(
          'network_error',
          'Check your connection and try again.',
        );
      default:
        return IapException(
          error.code,
          error.message ?? 'The purchase could not be completed.',
        );
    }
  }
}
