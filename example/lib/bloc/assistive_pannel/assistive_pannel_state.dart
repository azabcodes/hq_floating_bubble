part of 'assistive_pannel_bloc.dart';

class AssistivePannelState extends Equatable {
  final bool show;
  final bool closing;
  final bool canTapOutside;
  final double touchX;
  final double touchY;

  const AssistivePannelState({
    this.show = false,
    this.closing = false,
    this.canTapOutside = false,
    this.touchX = 0.0,
    this.touchY = 0.0,
  });

  AssistivePannelState copyWith({
    bool? show,
    bool? closing,
    bool? canTapOutside,
    double? touchX,
    double? touchY,
  }) {
    return AssistivePannelState(
      show: show ?? this.show,
      closing: closing ?? this.closing,
      canTapOutside: canTapOutside ?? this.canTapOutside,
      touchX: touchX ?? this.touchX,
      touchY: touchY ?? this.touchY,
    );
  }

  @override
  List<Object?> get props => [show, closing, canTapOutside, touchX, touchY];
}
