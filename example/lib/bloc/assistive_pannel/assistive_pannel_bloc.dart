// ignore_for_file: avoid_print

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
    on<PannelVisible>(_onVisible);
    on<EnableTapOutside>(_onEnableTapOutside);
    on<ClosePannelRequested>(_onCloseRequested);
  }

  void _onUpdateWindow(
    UpdatePannelWindow event,
    Emitter<AssistivePannelState> emit,
  ) {
    final newWindow = event.newWindow;
    print('[AssistivePannelBloc] _onUpdateWindow called, newWindow: ${newWindow?.id}');

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
      print('[AssistivePannelBloc] WindowStarted event callback fired');
      add(PannelVisible());
    };

    _resumedListener = (_, _) {
      print('[AssistivePannelBloc] WindowResumed event callback fired');
      add(PannelVisible());
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
          print(
            '[AssistivePannelBloc] onData callback received from source: $source, name: $name, data: $data',
          );
          if (data is! List || data.length < 2) {
            return;
          }
          if (data[0] is! num || data[1] is! num) {
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

    // Since this sub-engine isolate has loaded and initialized, the panel window
    // is already started and visible. Trigger PannelVisible immediately to scale up the menu.
    print('[AssistivePannelBloc] Dispatching PannelVisible immediately during initialization');
    add(PannelVisible());
  }

  void _onPositionUpdated(PannelTouchPositionUpdated event, Emitter<AssistivePannelState> emit) {
    print('[AssistivePannelBloc] Position updated event: x=${event.x}, y=${event.y}');
    if (state.touchX == event.x && state.touchY == event.y) {
      return;
    }
    emit(state.copyWith(touchX: event.x, touchY: event.y));
  }

  void _showPanel(Emitter<AssistivePannelState> emit) {
    print('[AssistivePannelBloc] _showPanel called. Current show: ${state.show}');
    if (state.show && !state.closing && !state.canTapOutside) {
      return;
    }
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
      print('[AssistivePannelBloc] Safety timer expired, enabling tap outside');
      add(EnableTapOutside());
    });
  }

  void _onVisible(PannelVisible event, Emitter<AssistivePannelState> emit) {
    print('[AssistivePannelBloc] PannelVisible event handler invoked');
    _showPanel(emit);
  }

  void _onEnableTapOutside(EnableTapOutside event, Emitter<AssistivePannelState> emit) {
    emit(state.copyWith(canTapOutside: true));
  }

  void _onCloseRequested(ClosePannelRequested event, Emitter<AssistivePannelState> emit) {
    print(
      '[AssistivePannelBloc] Close panel requested. force: ${event.force}, canTapOutside: ${state.canTapOutside}, closing: ${state.closing}',
    );
    if (!event.force && !state.canTapOutside) return;
    if (state.closing) return;

    emit(state.copyWith(closing: true, show: false));

    _closeTimer?.cancel();
    _closeTimer = Timer(duration, () {
      print('[AssistivePannelBloc] Close timer expired, invoking native window.close()');
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
