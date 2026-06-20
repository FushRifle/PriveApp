import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:clique/core/services/feedback/feedback_service.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackService _service = FeedbackService();

  FeedbackBloc() : super(const FeedbackState()) {
    on<SubmitFeedback>(_onSubmitFeedback);
    on<ClearFeedbackState>(_onClearFeedbackState);
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(state.copyWith(
      status: FeedbackStatus.submitting,
      clearError: true,
    ));

    try {
      await _service.submitFeedback(
        category: event.category,
        message: event.message,
        email: event.email,
      );
      emit(state.copyWith(
        status: FeedbackStatus.success,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FeedbackStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onClearFeedbackState(
    ClearFeedbackState event,
    Emitter<FeedbackState> emit,
  ) {
    emit(const FeedbackState());
  }
}
