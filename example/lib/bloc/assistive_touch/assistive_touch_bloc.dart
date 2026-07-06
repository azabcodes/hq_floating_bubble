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
  HQFloatingWindowListener? _pannelStartedListener;
  Completer<void>? _pannelStartedCompleter;

  AssistiveTouchBloc() : super(const AssistiveTouchState()) {
    on<InitializeAssistiveTouch>(_onInitialize);
    on<PanelReadyUpdated>(_onPanelReadyUpdated);
    on<TouchWindowStarted>(_onTouchWindowStarted);
    on<OpenPanelRequested>(_onOpenPanel);
  }

  Future<void> _onInitialize(InitializeAssistiveTouch event, Emitter<AssistiveTouchState> emit) async {
    if (touchWindow != null) return;
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

    _pannelCreatedListener = (window, data) {
      add(const PanelReadyUpdated(true));
      if (!_pannelReadyCompleter.isCompleted) {
        _pannelReadyCompleter.complete();
      }
    };

    _pannelPausedListener = (window, data) {
      touchWindow?.start();
    };

    _pannelStartedListener = (window, data) {
      if (_pannelStartedCompleter != null && !_pannelStartedCompleter!.isCompleted) {
        _pannelStartedCompleter!.complete();
      }
    };

    pannelWindow
        ?.on(HQFloatingEventType.WindowCreated, _pannelCreatedListener!)
        .on(HQFloatingEventType.WindowPaused, _pannelPausedListener!)
        .on(HQFloatingEventType.WindowStarted, _pannelStartedListener!);

    print('[AssistiveTouchBloc] Syncing windows from native service...');
    await HQFloatingService().syncWindows();

    final existingWindow = HQFloatingService().windows['assistive_pannel'];
    if (existingWindow != null) {
      print('[AssistiveTouchBloc] Panel window already exists in cache. Marking as ready immediately.');
      pannelWindow!.pixelRadio = existingWindow.pixelRadio;
      pannelWindow!.system = existingWindow.system;
      pannelWindow!.config = existingWindow.config;
      
      emit(state.copyWith(pannelReady: true));
      if (!_pannelReadyCompleter.isCompleted) {
        _pannelReadyCompleter.complete();
      }
    } else {
      print('[AssistiveTouchBloc] Panel window not found in cache. Calling create().');
      pannelWindow?.create();
    }
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
    print('[AssistiveTouchBloc] _onOpenPanel called, target coords: x=${event.x}, y=${event.y}, state.opening=${state.opening}');
    if (state.opening) {
      print('[AssistiveTouchBloc] Already opening panel, aborting');
      return;
    }
    if (pannelWindow == null) {
      print('[AssistiveTouchBloc] pannelWindow is null, aborting');
      return;
    }

    emit(state.copyWith(opening: true));

    try {
      if (!state.pannelReady) {
        print('[AssistiveTouchBloc] Panel window is not ready, waiting for _pannelReadyCompleter...');
        await _pannelReadyCompleter.future;
        print('[AssistiveTouchBloc] _pannelReadyCompleter completed, panel window is ready');
      }

      _pannelStartedCompleter = Completer<void>();

      try {
        print('[AssistiveTouchBloc] Calling native pannelWindow.start()...');
        await pannelWindow?.start();

        print('[AssistiveTouchBloc] Waiting for WindowStarted event callback (timeout 1s)...');
        await Future.any([
          _pannelStartedCompleter!.future,
          Future.delayed(const Duration(seconds: 1)),
        ]);
        print('[AssistiveTouchBloc] Panel start await finished');
      } finally {
        _pannelStartedCompleter = null;
      }

      print('[AssistiveTouchBloc] Sharing touch coordinates via pannelWindow.share()');
      await pannelWindow?.share([
        event.x,
        event.y,
      ]);

      print('[AssistiveTouchBloc] Panel expanded successfully');
      emit(state.copyWith(expend: true));
    } catch (e, st) {
      print('[AssistiveTouchBloc] Error opening panel: $e\n$st');
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
      if (_pannelStartedListener != null) {
        pannelWindow!.off(HQFloatingEventType.WindowStarted, _pannelStartedListener!);
      }
    }
    return super.close();
  }
}
