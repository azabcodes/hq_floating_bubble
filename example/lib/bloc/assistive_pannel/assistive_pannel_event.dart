part of 'assistive_pannel_bloc.dart';

abstract class AssistivePannelEvent extends Equatable {
  const AssistivePannelEvent();

  @override
  List<Object?> get props => [];
}

class UpdatePannelWindow extends AssistivePannelEvent {
  final HQFloatingWindow? newWindow;

  const UpdatePannelWindow(this.newWindow);

  @override
  List<Object?> get props => [newWindow];
}

class PannelTouchPositionUpdated extends AssistivePannelEvent {
  final double x;
  final double y;

  const PannelTouchPositionUpdated(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

class PannelVisible extends AssistivePannelEvent {}

class EnableTapOutside extends AssistivePannelEvent {}

class ClosePannelRequested extends AssistivePannelEvent {
  final bool force;

  const ClosePannelRequested({this.force = false});

  @override
  List<Object?> get props => [force];
}
