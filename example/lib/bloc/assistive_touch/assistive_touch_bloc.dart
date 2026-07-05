import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

part 'assistive_touch_event.dart';
part 'assistive_touch_state.dart';

class AssistiveTouchBloc extends Bloc<AssistiveTouchEvent, AssistiveTouchState> {
  HQFloatingWindow? pannelWindow;
  HQFloatingWindow? touchWindow;

  final Completer<void> _pannelReadyCompleter = Completer<void>();

  HQFloatingWindowListener? _touchStartedListener;
  HQFloatingWindowListener? _pannelCreatedListener;
  HQFloatingWindowListener? _pannelPausedListener;

  AssistiveTouchBloc() : super(const AssistiveTouchState()) {
    on<InitializeAssistiveTouch>(_onInitialize);
    on<PanelReadyUpdated>(_onPanelReadyUpdated);
    on<TouchWindowStarted>(_onTouchWindowStarted);
    on<OpenPanelRequested>(_onOpenPanel);
  }

  void _onInitialize(InitializeAssistiveTouch event, Emitter<AssistiveTouchState> emit) {
    touchWindow = event.touchWindow;

    _touchStartedListener = (window, data) {
      add(TouchWindowStarted());
    };
    touchWindow?.on(HQFloatingEventType.WindowStarted, _touchStartedListener!);

    pannelWindow = HQFloatingWindowConfig(
      id: 'assistive_pannel',
      callback: event.pannelMainCallback,
      width: HQFloatingWindowSize.matchParent,
      height: HQFloatingWindowSize.matchParent,
      autosize: false,
    ).to();

    pannelWindow?.create();

    _pannelCreatedListener = (window, data) {
      add(const PanelReadyUpdated(true));
      if (!_pannelReadyCompleter.isCompleted) {
        _pannelReadyCompleter.complete();
      }
    };

    _pannelPausedListener = (window, data) {
      touchWindow?.start();
    };

    pannelWindow
        ?.on(HQFloatingEventType.WindowCreated, _pannelCreatedListener!)
        .on(HQFloatingEventType.WindowPaused, _pannelPausedListener!);
  }

  void _onPanelReadyUpdated(PanelReadyUpdated event, Emitter<AssistiveTouchState> emit) {
    emit(state.copyWith(pannelReady: event.isReady));
  }

  void _onTouchWindowStarted(TouchWindowStarted event, Emitter<AssistiveTouchState> emit) {
    emit(state.copyWith(expend: false));
  }

  Future<void> _onOpenPanel(
    OpenPanelRequested event,
    Emitter<AssistiveTouchState> emit,
  ) async {
    if (state.opening) return;

    emit(state.copyWith(opening: true));

    try {
      if (!state.pannelReady) {
        await _pannelReadyCompleter.future;
      }

      final startedCompleter = Completer<void>();
      void startedListener(window, data) {
        if (!startedCompleter.isCompleted) {
          startedCompleter.complete();
        }
      }

      pannelWindow?.on(HQFloatingEventType.WindowStarted, startedListener);

      await pannelWindow?.start();

      await Future.any([
        startedCompleter.future,
        Future.delayed(const Duration(milliseconds: 500)),
      ]);

      pannelWindow?.off(HQFloatingEventType.WindowStarted, startedListener);

      await pannelWindow?.share([
        event.x,
        event.y,
      ]);

      emit(state.copyWith(expend: true));
    } finally {
      emit(state.copyWith(opening: false));
    }
  }

  @override
  Future<void> close() {
    if (touchWindow != null && _touchStartedListener != null) {
      touchWindow!.off(HQFloatingEventType.WindowStarted, _touchStartedListener!);
    }
    if (pannelWindow != null) {
      if (_pannelCreatedListener != null) {
        pannelWindow!.off(HQFloatingEventType.WindowCreated, _pannelCreatedListener!);
      }
      if (_pannelPausedListener != null) {
        pannelWindow!.off(HQFloatingEventType.WindowPaused, _pannelPausedListener!);
      }
    }
    return super.close();
  }
}
