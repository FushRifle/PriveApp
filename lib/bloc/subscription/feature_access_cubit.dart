import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:clique/core/models/feature_access_model.dart';
import 'package:clique/core/services/subscription/revenue_cat_service.dart';
import 'package:clique/core/services/subscription/subscription_service.dart';

part 'feature_access_state.dart';

class FeatureAccessCubit extends Cubit<FeatureAccessState> {
  final SubscriptionService _subscriptionService;
  final RevenueCatService _revenueCatService;

  Future<void>? _loadFuture;
  Future<void>? _configureFuture;

  FeatureAccessCubit({
    SubscriptionService? subscriptionService,
    RevenueCatService? revenueCatService,
  })  : _subscriptionService = subscriptionService ?? SubscriptionService(),
        _revenueCatService = revenueCatService ?? RevenueCatService(),
        super(FeatureAccessState.initial());

  Future<void> load() async {
    final existingLoad = _loadFuture;
    if (existingLoad != null) return existingLoad;

    final future = _load();
    _loadFuture = future;

    try {
      await future;
    } finally {
      if (_loadFuture == future) {
        _loadFuture = null;
      }
    }
  }

  Future<void> configureRevenueCat(String appUserId) async {
    final existingConfigure = _configureFuture;
    if (existingConfigure != null) return existingConfigure;

    final future = _configureRevenueCat(appUserId);
    _configureFuture = future;

    try {
      await future;
    } finally {
      if (_configureFuture == future) {
        _configureFuture = null;
      }
    }
  }

  Future<void> _load() async {
    emit(state.copyWith(status: FeatureAccessStatus.loading, clearError: true));
    try {
      final access = await _subscriptionService.getFeatureAccess();
      emit(state.copyWith(
        status: FeatureAccessStatus.loaded,
        access: access,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: FeatureAccessStatus.error,
        error: error.toString(),
      ));
    }
  }

  Future<void> _configureRevenueCat(String appUserId) async {
    final configured = await _revenueCatService.configure(appUserId: appUserId);
    emit(state.copyWith(isRevenueCatConfigured: configured));
  }

  bool can(String permission) => state.access.can(permission);

  bool isLocked(String permission) => state.access.isLocked(permission);

  int limit(String key, {int fallback = 0}) {
    return state.access.limit(key, fallback: fallback);
  }

  int remaining(String key, {int fallback = 0}) {
    return state.access.remaining(key, fallback: fallback);
  }

  bool hasLimitReached(String key, {int fallback = 0}) {
    return state.access.hasLimitReached(key, fallback: fallback);
  }

  Future<List<Package>> packages() => _revenueCatService.getPackages();

  Future<void> purchase(Package package) async {
    emit(state.copyWith(isPurchasing: true, clearError: true));
    try {
      final info = await _revenueCatService.purchase(package);
      await _syncCustomerInfo(info);
      emit(state.copyWith(isPurchasing: false));
    } catch (error) {
      emit(state.copyWith(isPurchasing: false, error: error.toString()));
    }
  }

  Future<void> restore() async {
    emit(state.copyWith(isRestoring: true, clearError: true));
    try {
      final info = await _revenueCatService.restore();
      await _syncCustomerInfo(info);
      emit(state.copyWith(isRestoring: false));
    } catch (error) {
      emit(state.copyWith(isRestoring: false, error: error.toString()));
    }
  }

  Future<void> _syncCustomerInfo(CustomerInfo? info) async {
    if (info == null) {
      await load();
      return;
    }

    final entitlement = _revenueCatService.activeEntitlement(
      info,
      entitlementId: state.access.revenueCatProducts.entitlementId,
    );

    final access = await _subscriptionService.syncEntitlement(
      productId: entitlement.productId,
      expiresAtMs: entitlement.expiresAtMs,
      isActive: entitlement.isActive,
    );

    emit(state.copyWith(
      status: FeatureAccessStatus.loaded,
      access: access,
    ));
  }
}
