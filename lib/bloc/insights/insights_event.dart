part of 'insights_bloc.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

class LoadInsights extends InsightsEvent {
  final int days;
  const LoadInsights({this.days = 30});

  @override
  List<Object?> get props => [days];
}

class RefreshInsights extends InsightsEvent {
  final int days;
  const RefreshInsights({this.days = 30});

  @override
  List<Object?> get props => [days];
}

class ChangeInsightsPeriod extends InsightsEvent {
  final int days;
  const ChangeInsightsPeriod({required this.days});

  @override
  List<Object?> get props => [days];
}

class LoadRealtimeStats extends InsightsEvent {}

class RefreshRealtimeStats extends InsightsEvent {}

class ClearInsightsError extends InsightsEvent {}

class ResetInsightsState extends InsightsEvent {}
