import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

part 'home_page_event.dart';
part 'home_page_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  static bool forceKillOnStartup = false;
  List<HQFloatingWindowConfig> _configs = const [];

  HomePageBloc() : super(const HomePageState()) {
    on<InitializeServiceAndWindows>(_onInitialize);
    on<RefreshServiceStatus>(_onRefreshServiceStatus);
    on<OpenWindowRequested>(_onOpenWindow);
    on<CloseWindowRequested>(_onCloseWindow);
  }

  Future<void> _onInitialize(
    InitializeServiceAndWindows event,
    Emitter<HomePageState> emit,
  ) async {
    _configs = event.configs;
    emit(state.copyWith(loading: true, errorMessage: null));
    await _initializeFlow(emit);
  }

  Future<void> _onRefreshServiceStatus(
    RefreshServiceStatus event,
    Emitter<HomePageState> emit,
  ) async {
    emit(state.copyWith(loading: true, errorMessage: null));
    await _initializeFlow(emit);
  }

  Future<void> _initializeFlow(Emitter<HomePageState> emit) async {
    try {
      if (kDebugMode && forceKillOnStartup) {
        try {
          await HQFloatingService().stopService();
        } catch (_) {}
      }

      await HQFloatingService().initialize(force: true);

      final hasPermission = await HQFloatingService().checkPermission();
      if (!hasPermission) {
        emit(state.copyWith(
          loading: false,
          hasPermission: false,
          ready: false,
        ));
        HQFloatingService().openPermissionSetting();
        return;
      }

      final serviceRunning = await HQFloatingService().isServiceRunning();
      if (!serviceRunning) {
        await HQFloatingService().startService();
      }

      // Populate initial windows
      final List<HQFloatingWindow> windows = [];
      for (var c in _configs) {
        windows.add(c.to());
      }

      // Attempt to create windows in parallel
      final Map<String, bool> readys = Map.from(state.readys);
      final List<Future<void>> createFutures = [];

      for (int i = 0; i < windows.length; i++) {
        final w = windows[i];
        final existing = HQFloatingService().windows[w.id];
        if (existing != null) {
          windows[i] = existing;
          readys[existing.id] = true;
          continue;
        }

        final index = i;
        createFutures.add(() async {
          try {
            final createdWindow = await w.create();
            if (createdWindow != null) {
              windows[index] = createdWindow;
              readys[createdWindow.id] = true;
            }
          } catch (e, st) {
            debugPrint('Failed to create window "${w.id}": $e\n$st');
          }
        }());
      }

      if (createFutures.isNotEmpty) {
        await Future.wait(createFutures);
      }

      emit(state.copyWith(
        loading: false,
        ready: true,
        windows: windows,
        readys: readys,
        hasPermission: true,
      ));
    } catch (e, st) {
      debugPrint('Failed to initialize floating overlays: $e\n$st');
      emit(state.copyWith(
        loading: false,
        ready: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOpenWindow(OpenWindowRequested event, Emitter<HomePageState> emit) async {
    try {
      await event.window.start();
    } catch (e) {
      debugPrint('Failed to open window "${event.window.id}": $e');
    }
  }

  Future<void> _onCloseWindow(CloseWindowRequested event, Emitter<HomePageState> emit) async {
    final w = event.window;
    try {
      await w.share('close');
    } catch (e) {
      debugPrint('Failed to notify window "${w.id}" before closing: $e');
    }
    try {
      await w.close();
    } catch (e) {
      debugPrint('Failed to close window "${w.id}": $e');
    }
  }
}
