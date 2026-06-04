class FeatureAccess {
  final String tier;
  final String planId;
  final String status;
  final bool isPremium;
  final bool isTrial;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final Map<String, bool> permissions;
  final Map<String, dynamic> limits;
  final Map<String, int> usage;
  final List<String> lockedFeatures;
  final RevenueCatProducts revenueCatProducts;

  const FeatureAccess({
    required this.tier,
    required this.planId,
    required this.status,
    required this.isPremium,
    required this.isTrial,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.permissions,
    required this.limits,
    required this.usage,
    required this.lockedFeatures,
    required this.revenueCatProducts,
  });

  factory FeatureAccess.free() {
    return const FeatureAccess(
      tier: 'free',
      planId: 'free',
      status: 'active',
      isPremium: false,
      isTrial: false,
      cancelAtPeriodEnd: false,
      permissions: {},
      limits: {},
      usage: {},
      lockedFeatures: [],
      revenueCatProducts: RevenueCatProducts(),
    );
  }

  factory FeatureAccess.fromJson(Map<String, dynamic> json) {
    return FeatureAccess(
      tier: json['tier']?.toString() ?? 'free',
      planId: json['planId']?.toString() ?? 'free',
      status: json['status']?.toString() ?? 'active',
      isPremium: json['isPremium'] == true,
      isTrial: json['isTrial'] == true,
      currentPeriodEnd: DateTime.tryParse(
        json['currentPeriodEnd']?.toString() ?? '',
      ),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      permissions: _readBoolMap(json['permissions']),
      limits: json['limits'] is Map
          ? Map<String, dynamic>.from(json['limits'] as Map)
          : const {},
      usage: _readIntMap(json['usage']),
      lockedFeatures: (json['lockedFeatures'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      revenueCatProducts: RevenueCatProducts.fromJson(
        json['revenueCatProducts'] is Map
            ? Map<String, dynamic>.from(json['revenueCatProducts'] as Map)
            : const {},
      ),
    );
  }

  bool can(String permission) => permissions[permission] == true;

  int limit(String key, {int fallback = 0}) {
    final value = limits[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<String, bool> _readBoolMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, item) => MapEntry(key.toString(), item == true));
  }

  static Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, item) {
      var parsed = 0;
      if (item is int) parsed = item;
      if (item is num) parsed = item.toInt();
      if (item is String) parsed = int.tryParse(item) ?? 0;
      return MapEntry(key.toString(), parsed);
    });
  }
}

class RevenueCatProducts {
  final String premiumMonthly;
  final String premiumYearly;
  final String vipMonthly;
  final String vipYearly;
  final String entitlementId;

  const RevenueCatProducts({
    this.premiumMonthly = 'premium_monthly',
    this.premiumYearly = 'premium_yearly',
    this.vipMonthly = 'vip_monthly',
    this.vipYearly = 'vip_yearly',
    this.entitlementId = 'premium',
  });

  factory RevenueCatProducts.fromJson(Map<String, dynamic> json) {
    return RevenueCatProducts(
      premiumMonthly: json['premiumMonthly']?.toString() ?? 'premium_monthly',
      premiumYearly: json['premiumYearly']?.toString() ?? 'premium_yearly',
      vipMonthly: json['vipMonthly']?.toString() ?? 'vip_monthly',
      vipYearly: json['vipYearly']?.toString() ?? 'vip_yearly',
      entitlementId: json['entitlementId']?.toString() ?? 'premium',
    );
  }
}

abstract final class PremiumPermission {
  static const canEditPost = 'canEditPost';
  static const canSchedulePost = 'canSchedulePost';
  static const canCreateCommunity = 'canCreateCommunity';
  static const canCreateGroup = 'canCreateGroup';
  static const canViewInsights = 'canViewInsights';
  static const canUseAdvancedFilters = 'canUseAdvancedFilters';
  static const canUploadLongReels = 'canUploadLongReels';
  static const canUsePremiumThemes = 'canUsePremiumThemes';
  static const canAccessAnalytics = 'canAccessAnalytics';
  static const canAccessStoryInsights = 'canAccessStoryInsights';
  static const canAccessAdvancedMatching = 'canAccessAdvancedMatching';
  static const canCustomizeProfile = 'canCustomizeProfile';
  static const canUsePremiumBadge = 'canUsePremiumBadge';
  static const canUseVerificationBadge = 'canUseVerificationBadge';
  static const canUseVoiceNotes = 'canUseVoiceNotes';
  static const canUseReadReceipts = 'canUseReadReceipts';
  static const canCreatePremiumCommunity = 'canCreatePremiumCommunity';
}
