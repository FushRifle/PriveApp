class FeatureAccess {
  static const int unlimited = -1;

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
    return FeatureAccess(
      tier: 'free',
      planId: 'free',
      status: 'active',
      isPremium: false,
      isTrial: false,
      cancelAtPeriodEnd: false,
      permissions: FeatureAccessPolicy.freePermissions,
      limits: FeatureAccessPolicy.freeLimits,
      usage: const {},
      lockedFeatures: FeatureAccessPolicy.premiumPermissions,
      revenueCatProducts: const RevenueCatProducts(),
    );
  }

  factory FeatureAccess.premium({
    String tier = PremiumTier.premium,
    String planId = PremiumTier.premium,
    String status = 'active',
    bool isTrial = false,
    DateTime? currentPeriodEnd,
    bool cancelAtPeriodEnd = false,
    Map<String, int> usage = const {},
    RevenueCatProducts revenueCatProducts = const RevenueCatProducts(),
  }) {
    return FeatureAccess(
      tier: tier,
      planId: planId,
      status: status,
      isPremium: true,
      isTrial: isTrial,
      currentPeriodEnd: currentPeriodEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      permissions: FeatureAccessPolicy.premiumPermissionsMap,
      limits: FeatureAccessPolicy.premiumLimits,
      usage: usage,
      lockedFeatures: const [],
      revenueCatProducts: revenueCatProducts,
    );
  }

  factory FeatureAccess.fromJson(Map<String, dynamic> json) {
    final tier = json['tier']?.toString() ?? PremiumTier.free;
    final isPremium = json['isPremium'] == true ||
        tier == PremiumTier.premium ||
        tier == PremiumTier.vip;
    final defaults =
        isPremium ? FeatureAccess.premium(tier: tier) : FeatureAccess.free();
    final permissions = Map<String, bool>.from(defaults.permissions)
      ..addAll(_readBoolMap(json['permissions']));
    final limits = Map<String, dynamic>.from(defaults.limits)
      ..addAll(
        json['limits'] is Map
            ? Map<String, dynamic>.from(json['limits'] as Map)
            : const {},
      );
    final lockedFeatures = (json['lockedFeatures'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        permissions.entries
            .where((entry) => entry.value == false)
            .map((entry) => entry.key)
            .toList();

    return FeatureAccess(
      tier: tier,
      planId: json['planId']?.toString() ?? tier,
      status: json['status']?.toString() ?? 'active',
      isPremium: isPremium,
      isTrial: json['isTrial'] == true,
      currentPeriodEnd: DateTime.tryParse(
        json['currentPeriodEnd']?.toString() ?? '',
      ),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      permissions: permissions,
      limits: limits,
      usage: _readIntMap(json['usage']),
      lockedFeatures: lockedFeatures,
      revenueCatProducts: RevenueCatProducts.fromJson(
        json['revenueCatProducts'] is Map
            ? Map<String, dynamic>.from(json['revenueCatProducts'] as Map)
            : const {},
      ),
    );
  }

  bool can(String permission) => permissions[permission] == true;

  bool isLocked(String permission) => !can(permission);

  int limit(String key, {int fallback = 0}) {
    final value = limits[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  int used(String key) => usage[key] ?? 0;

  int remaining(String key, {int fallback = 0}) {
    final configuredLimit = limit(key, fallback: fallback);
    if (configuredLimit == unlimited) return unlimited;
    final value = configuredLimit - used(key);
    return value < 0 ? 0 : value;
  }

  bool hasLimitReached(String key, {int fallback = 0}) {
    final configuredLimit = limit(key, fallback: fallback);
    if (configuredLimit == unlimited) return false;
    return used(key) >= configuredLimit;
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

abstract final class PremiumTier {
  static const free = 'free';
  static const premium = 'premium';
  static const vip = 'vip';
}

abstract final class PremiumLimit {
  static const postEditsPerPost = 'postEditsPerPost';
  static const postEditWindowMinutes = 'postEditWindowMinutes';
  static const scheduledPosts = 'scheduledPosts';
  static const dailyReelUploads = 'dailyReelUploads';
  static const reelDurationSeconds = 'reelDurationSeconds';
  static const dailyStoryUploads = 'dailyStoryUploads';
  static const dailyMessageMediaUploads = 'dailyMessageMediaUploads';
  static const voiceNoteDurationSeconds = 'voiceNoteDurationSeconds';
  static const dailyProfileViews = 'dailyProfileViews';
  static const dailyMatchRequests = 'dailyMatchRequests';
  static const joinedGroups = 'joinedGroups';
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
  static const canUseAdvancedChatCustomization =
      'canUseAdvancedChatCustomization';
  static const canUseChatWallpapers = 'canUseChatWallpapers';
  static const canManageMessages = 'canManageMessages';
  static const canSaveDrafts = 'canSaveDrafts';
  static const canUsePriorityMediaProcessing = 'canUsePriorityMediaProcessing';
  static const canUseAdvancedModeration = 'canUseAdvancedModeration';
}

class PremiumFeature {
  final String permission;
  final String title;
  final String description;

  const PremiumFeature({
    required this.permission,
    required this.title,
    required this.description,
  });
}

abstract final class FeatureAccessPolicy {
  static const premiumFeatures = <PremiumFeature>[
    PremiumFeature(
      permission: PremiumPermission.canEditPost,
      title: 'Post Editing',
      description: 'Edit published posts and keep your content current.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canSchedulePost,
      title: 'Post Scheduling',
      description: 'Plan posts ahead and publish them at the right time.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canCreateCommunity,
      title: 'Community Creation',
      description: 'Create communities for your audience and interests.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canCreateGroup,
      title: 'Group Creation',
      description: 'Create private or focused group spaces.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canViewInsights,
      title: 'Profile Insights',
      description: 'See detailed performance and audience insights.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseAdvancedFilters,
      title: 'Advanced Filters',
      description: 'Use richer search and discovery filters.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUploadLongReels,
      title: 'Long Reels',
      description: 'Upload longer reels for deeper stories.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUsePremiumThemes,
      title: 'Premium Themes',
      description: 'Personalize clique with exclusive themes.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canAccessAnalytics,
      title: 'Advanced Analytics',
      description: 'Unlock deeper analytics across your activity.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canAccessStoryInsights,
      title: 'Story Insights',
      description: 'Track story views, engagement, and performance.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canAccessAdvancedMatching,
      title: 'Advanced Matching',
      description: 'Use better matching tools while discovering people.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canCustomizeProfile,
      title: 'Profile Customization',
      description: 'Unlock more ways to shape your profile.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUsePremiumBadge,
      title: 'Premium Badge',
      description: 'Show your premium status on your profile.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseVerificationBadge,
      title: 'Verification Badge',
      description: 'Stand out with a verified profile badge.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseVoiceNotes,
      title: 'Voice Notes',
      description: 'Send voice messages in chats.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseReadReceipts,
      title: 'Read Receipts',
      description: 'Know when your messages have been seen.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canCreatePremiumCommunity,
      title: 'Premium Communities',
      description: 'Create premium-only community spaces.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseAdvancedChatCustomization,
      title: 'Advanced Chat Customization',
      description: 'Use advanced chat themes and color controls.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseChatWallpapers,
      title: 'Chat Wallpapers',
      description: 'Set custom wallpapers for conversations.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canManageMessages,
      title: 'Message Management',
      description: 'Unlock advanced message management tools.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canSaveDrafts,
      title: 'Draft Saving',
      description: 'Save unfinished content and return later.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUsePriorityMediaProcessing,
      title: 'Priority Media Processing',
      description: 'Get faster processing for media uploads.',
    ),
    PremiumFeature(
      permission: PremiumPermission.canUseAdvancedModeration,
      title: 'Advanced Moderation',
      description: 'Use stronger moderation tools for communities.',
    ),
  ];

  static List<String> get premiumPermissions =>
      premiumFeatures.map((feature) => feature.permission).toList();

  static Map<String, bool> get freePermissions => {
        for (final permission in premiumPermissions) permission: false,
      };

  static Map<String, bool> get premiumPermissionsMap => {
        for (final permission in premiumPermissions) permission: true,
      };

  static const freeLimits = <String, dynamic>{
    PremiumLimit.postEditsPerPost: 1,
    PremiumLimit.postEditWindowMinutes: 30,
    PremiumLimit.scheduledPosts: 0,
    PremiumLimit.dailyReelUploads: 3,
    PremiumLimit.reelDurationSeconds: 60,
    PremiumLimit.dailyStoryUploads: 5,
    PremiumLimit.dailyMessageMediaUploads: 10,
    PremiumLimit.voiceNoteDurationSeconds: 30,
    PremiumLimit.dailyProfileViews: 50,
    PremiumLimit.dailyMatchRequests: 10,
    PremiumLimit.joinedGroups: 5,
  };

  static const premiumLimits = <String, dynamic>{
    PremiumLimit.postEditsPerPost: FeatureAccess.unlimited,
    PremiumLimit.postEditWindowMinutes: FeatureAccess.unlimited,
    PremiumLimit.scheduledPosts: FeatureAccess.unlimited,
    PremiumLimit.dailyReelUploads: FeatureAccess.unlimited,
    PremiumLimit.reelDurationSeconds: 180,
    PremiumLimit.dailyStoryUploads: FeatureAccess.unlimited,
    PremiumLimit.dailyMessageMediaUploads: FeatureAccess.unlimited,
    PremiumLimit.voiceNoteDurationSeconds: 300,
    PremiumLimit.dailyProfileViews: FeatureAccess.unlimited,
    PremiumLimit.dailyMatchRequests: FeatureAccess.unlimited,
    PremiumLimit.joinedGroups: FeatureAccess.unlimited,
  };

  static PremiumFeature feature(String permission) {
    for (final feature in premiumFeatures) {
      if (feature.permission == permission) return feature;
    }
    return PremiumFeature(
      permission: permission,
      title: 'Premium Feature',
      description: 'Upgrade to Premium to unlock this feature.',
    );
  }
}
