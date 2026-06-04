import 'dart:io';

import 'package:clique/app/configs/api_config.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  bool _configured = false;
  String? _configuredUserId;

  bool get isConfigured => _configured;

  Future<bool> configure({required String appUserId}) async {
    final apiKey = Platform.isIOS
        ? ApiConfig.revenueCatAppleApiKey
        : ApiConfig.revenueCatGoogleApiKey;

    if (apiKey.isEmpty || appUserId.isEmpty) return false;
    if (_configured && _configuredUserId == appUserId) return true;

    await Purchases.setLogLevel(LogLevel.warn);
    await Purchases.configure(
      PurchasesConfiguration(apiKey)..appUserID = appUserId,
    );

    _configured = true;
    _configuredUserId = appUserId;
    return true;
  }

  Future<List<Package>> getPackages() async {
    if (!_configured) return const [];
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? const [];
  }

  Future<CustomerInfo?> purchase(Package package) async {
    if (!_configured) return null;
    final result = await Purchases.purchasePackage(package);
    return result.customerInfo;
  }

  Future<CustomerInfo?> restore() async {
    if (!_configured) return null;
    return Purchases.restorePurchases();
  }

  RevenueCatEntitlement activeEntitlement(
    CustomerInfo customerInfo, {
    required String entitlementId,
  }) {
    final active = customerInfo.entitlements.active[entitlementId];
    if (active == null) {
      return const RevenueCatEntitlement(isActive: false);
    }

    return RevenueCatEntitlement(
      isActive: active.isActive,
      productId: active.productIdentifier,
      expiresAtMs: _expirationMs(active.expirationDate),
    );
  }

  int _expirationMs(String? value) {
    if (value == null || value.isEmpty) return 0;
    return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
  }
}

class RevenueCatEntitlement {
  final bool isActive;
  final String productId;
  final int expiresAtMs;

  const RevenueCatEntitlement({
    required this.isActive,
    this.productId = '',
    this.expiresAtMs = 0,
  });
}
