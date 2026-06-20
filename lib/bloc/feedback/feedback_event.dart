part of 'feedback_bloc.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class SubmitFeedback extends FeedbackEvent {
  final String category;
  final String message;
  final String? email;

  const SubmitFeedback({
    required this.category,
    required this.message,
    this.email,
  });

  @override
  List<Object?> get props => [category, message, email];
}

class ClearFeedbackState extends FeedbackEvent {
  const ClearFeedbackState();
}
