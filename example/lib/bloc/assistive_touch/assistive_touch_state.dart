part of 'assistive_touch_bloc.dart';

class AssistiveTouchState extends Equatable {
  final bool expend;
  final bool pannelReady;
  final bool opening;

  const AssistiveTouchState({
    this.expend = false,
    this.pannelReady = false,
    this.opening = false,
  });

  AssistiveTouchState copyWith({
    bool? expend,
    bool? pannelReady,
    bool? opening,
  }) {
    return AssistiveTouchState(
      expend: expend ?? this.expend,
      pannelReady: pannelReady ?? this.pannelReady,
      opening: opening ?? this.opening,
    );
  }

  @override
  List<Object?> get props => [expend, pannelReady, opening];
}
