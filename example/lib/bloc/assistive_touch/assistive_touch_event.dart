part of 'assistive_touch_bloc.dart';

abstract class AssistiveTouchEvent extends Equatable {
  const AssistiveTouchEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAssistiveTouch extends AssistiveTouchEvent {
  final HQFloatingWindow? touchWindow;
  final VoidCallback pannelMainCallback;

  const InitializeAssistiveTouch({
    required this.touchWindow,
    required this.pannelMainCallback,
  });

  @override
  List<Object?> get props => [touchWindow, pannelMainCallback];
}

class PanelReadyUpdated extends AssistiveTouchEvent {
  final bool isReady;

  const PanelReadyUpdated(this.isReady);

  @override
  List<Object?> get props => [isReady];
}

class TouchWindowStarted extends AssistiveTouchEvent {}

class OpenPanelRequested extends AssistiveTouchEvent {
  final double x;
  final double y;

  const OpenPanelRequested({required this.x, required this.y});

  @override
  List<Object?> get props => [x, y];
}
