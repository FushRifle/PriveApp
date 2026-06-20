part of 'feedback_bloc.dart';

enum FeedbackStatus { initial, submitting, success, error }

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final String? error;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.error,
  });

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, error];
}
