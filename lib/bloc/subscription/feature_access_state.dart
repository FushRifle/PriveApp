part of 'feature_access_cubit.dart';

enum FeatureAccessStatus { initial, loading, loaded, error }

class FeatureAccessState extends Equatable {
  final FeatureAccessStatus status;
  final FeatureAccess access;
  final bool isPurchasing;
  final bool isRestoring;
  final bool isRevenueCatConfigured;
  final String? error;

  const FeatureAccessState({
    required this.status,
    required this.access,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.isRevenueCatConfigured = false,
    this.error,
  });

  factory FeatureAccessState.initial() {
    return FeatureAccessState(
      status: FeatureAccessStatus.initial,
      access: FeatureAccess.free(),
    );
  }

  FeatureAccessState copyWith({
    FeatureAccessStatus? status,
    FeatureAccess? access,
    bool? isPurchasing,
    bool? isRestoring,
    bool? isRevenueCatConfigured,
    String? error,
    bool clearError = false,
  }) {
    return FeatureAccessState(
      status: status ?? this.status,
      access: access ?? this.access,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      isRevenueCatConfigured:
          isRevenueCatConfigured ?? this.isRevenueCatConfigured,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        access,
        isPurchasing,
        isRestoring,
        isRevenueCatConfigured,
        error,
      ];
}
