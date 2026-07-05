import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

part 'assistive_pannel_event.dart';
part 'assistive_pannel_state.dart';

class AssistivePannelBloc extends Bloc<AssistivePannelEvent, AssistivePannelState> {
  final Duration duration = const Duration(milliseconds: 250);

  HQFloatingWindow? window;
  HQFloatingWindowListener? _startedListener;
  HQFloatingWindowListener? _resumedListener;

  Timer? _closeTimer;
  Timer? _safetyTimer;

  AssistivePannelBloc() : super(const AssistivePannelState()) {
    on<UpdatePannelWindow>(_onUpdateWindow);
    on<PannelTouchPositionUpdated>(_onPositionUpdated);
    on<PannelStarted>(_onStarted);
    on<PannelResumed>(_onResumed);
    on<EnableTapOutside>(_onEnableTapOutside);
    on<ClosePannelRequested>(_onCloseRequested);
  }

  void _onUpdateWindow(
    UpdatePannelWindow event,
    Emitter<AssistivePannelState> emit,
  ) {
    final newWindow = event.newWindow;

    if (identical(newWindow, window)) {
      return;
    }

    if (window != null) {
      if (_startedListener != null) {
        window!.off(
          HQFloatingEventType.WindowStarted,
          _startedListener!,
        );
      }

      if (_resumedListener != null) {
        window!.off(
          HQFloatingEventType.WindowResumed,
          _resumedListener!,
        );
      }

      window!.offData();
    }

    window = newWindow;

    _closeTimer?.cancel();
    _safetyTimer?.cancel();

    emit(
      state.copyWith(
        closing: false,
        show: false,
        canTapOutside: false,
      ),
    );

    _startedListener = (_, _) {
      add(PannelStarted());
    };

    _resumedListener = (_, _) {
      add(PannelResumed());
    };

    window
        ?.on(
          HQFloatingEventType.WindowStarted,
          _startedListener!,
        )
        .on(
          HQFloatingEventType.WindowResumed,
          _resumedListener!,
        )
        .onData((source, name, data) async {
          if (data is! List || data.length < 2) {
            return;
          }

          final x = (data[0] as num).toDouble();
          final y = (data[1] as num).toDouble();

          add(
            PannelTouchPositionUpdated(
              x,
              y,
            ),
          );
        });
  }

  void _onPositionUpdated(PannelTouchPositionUpdated event, Emitter<AssistivePannelState> emit) {
    emit(state.copyWith(touchX: event.x, touchY: event.y));
  }

  void _onStarted(PannelStarted event, Emitter<AssistivePannelState> emit) {
    _closeTimer?.cancel();
    _safetyTimer?.cancel();
    emit(
      state.copyWith(
        show: true,
        closing: false,
        canTapOutside: false,
      ),
    );
    _safetyTimer = Timer(const Duration(milliseconds: 300), () {
      add(EnableTapOutside());
    });
  }

  void _onResumed(PannelResumed event, Emitter<AssistivePannelState> emit) {
    _closeTimer?.cancel();
    _safetyTimer?.cancel();
    emit(
      state.copyWith(
        show: true,
        closing: false,
        canTapOutside: false,
      ),
    );
    _safetyTimer = Timer(const Duration(milliseconds: 300), () {
      add(EnableTapOutside());
    });
  }

  void _onEnableTapOutside(EnableTapOutside event, Emitter<AssistivePannelState> emit) {
    emit(state.copyWith(canTapOutside: true));
  }

  void _onCloseRequested(ClosePannelRequested event, Emitter<AssistivePannelState> emit) {
    if (!state.canTapOutside) return;
    if (state.closing) return;

    emit(state.copyWith(closing: true, show: false));

    _closeTimer?.cancel();
    _closeTimer = Timer(duration, () {
      window?.close();
    });
  }

  @override
  Future<void> close() {
    _closeTimer?.cancel();
    _safetyTimer?.cancel();
    if (window != null) {
      if (_startedListener != null) {
        window!.off(HQFloatingEventType.WindowStarted, _startedListener!);
      }
      if (_resumedListener != null) {
        window!.off(HQFloatingEventType.WindowResumed, _resumedListener!);
      }
      window!.offData();
    }
    return super.close();
  }
}
