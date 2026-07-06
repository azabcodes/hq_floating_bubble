import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

class HQFloatingService {
  /// Broadcast StreamController for all system overlay events.
  final StreamController<HQFloatingEvent> eventController =
      StreamController<HQFloatingEvent>.broadcast();

  /// Stream of all events emitted by any of the windows.
  Stream<HQFloatingEvent> get onEvent => eventController.stream;

  HQFloatingService._() {
    WidgetsFlutterBinding.ensureInitialized();

    // make sure this only be called once
    // what happens when multiple window instances
    // are created and register event handlers?
    // HQFloatingWindow().on(): id -> [HQFloatingWindow, HQFloatingWindow]
    // _eventManager = EventManager(_msgChannel);

    // _bgChannel.setMethodCallHandler((call) {
    //   var id = call.arguments as String;
    //   // if we are window egine, should call main engine
    //   HQFloatingService().windows[id]?.eventManager?.sink(call.method, call.arguments);
    //   switch (call.method) {

    //   }
    //   return Future.value(null);
    // });
  }

  static const String channelID = 'hq.floating.bubble';

  static final MethodChannel _channel = MethodChannel('$channelID/method');

  // Reserved for future background communication
  // ignore: unused_field
  static final MethodChannel _bgChannel = MethodChannel('$channelID/bg_method');

  // Reserved for future message-based communication
  // ignore: unused_field
  static final BasicMessageChannel _msgChannel = BasicMessageChannel(
    '$channelID/bg_message',
    JSONMessageCodec(),
  );

  static final HQFloatingService _instance = HQFloatingService._();

  /// event manager
  // EventManager? _eventManager;

  /// flag for inited
  bool _inited = false;

  /// permission granted already (updated by initialize)
  // ignore: unused_field
  bool? _permissionGranted;

  /// service running already (updated by initialize)
  // ignore: unused_field
  bool? _serviceRunning;

  /// _windows for the main engine to manage the windows started
  /// items added by start function
  final Map<String, HQFloatingWindow> _windows = {};

  /// reutrn all windows only works for main engine
  Map<String, HQFloatingWindow> get windows =>
      _windows; // _windows.entries.map<HQFloatingWindow>((e) => e.value).toList();

  /// _window for the sub window engine to manage it's self
  /// setted after window's engine start and initital call
  HQFloatingWindow? _window;

  /// return current window for window's engine
  HQFloatingWindow? get currentWindow => _window;

  /// i'm window engine, default is the main engine
  /// if we sync success, we set to true.
  bool get isWindow => _isWindow;
  bool _isWindow = false;

  factory HQFloatingService() {
    return _instance;
  }

  HQFloatingService get instance {
    return _instance;
  }

  /// sync make the plugin to sync windows from services
  Future<bool> syncWindows() async {
    var ws = await _channel.invokeListMethod('plugin.sync_windows');
    ws?.forEach((e) {
      var w = HQFloatingWindow.fromMap(e);
      _windows[w.id] = w;
    });
    return true;
  }

  Future<HQFloatingSystemConfig> _getValidSystemConfig() async {
    var config = HQFloatingSystemConfig();
    if (config.screenWidth != null &&
        config.screenWidth! > 0 &&
        config.screenHeight != null &&
        config.screenHeight! > 0) {
      return config;
    }

    final completer = Completer<HQFloatingSystemConfig>();

    void checkMetrics(Duration _) {
      final view = PlatformDispatcher.instance.implicitView;
      final size = view?.physicalSize ?? Size.zero;
      if (size.width > 0 && size.height > 0) {
        completer.complete(HQFloatingSystemConfig());
      } else {
        WidgetsBinding.instance.addPostFrameCallback(checkMetrics);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(checkMetrics);
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => config,
    );
  }

  Future<bool> initialize({bool force = false}) async {
    if (_inited && !force) return false;
    _inited = true;

    final systemConfig = await _getValidSystemConfig();
    final view = PlatformDispatcher.instance.implicitView;

    var map = await _channel.invokeMapMethod('plugin.initialize', {
      'pixelRadio': view?.devicePixelRatio ?? 1.0,
      'system': systemConfig.toMap(),
    });

    log('[plugin] initialize result: $map');

    _serviceRunning = map?['service_running'];
    _permissionGranted = map?['permission_grated'];

    var ws = map?['windows'] as List<dynamic>?;
    ws?.forEach((e) {
      var w = HQFloatingWindow.fromMap(e);
      _windows[w.id] = w;
    });

    log('[plugin] there are ${_windows.length} windows already started');

    return true;
  }

  Future<bool> checkPermission() async {
    return (await _channel.invokeMethod<bool>('plugin.has_permission')) ?? false;
  }

  Future<bool> openPermissionSetting() async {
    return (await _channel.invokeMethod<bool>('plugin.open_permission_setting')) ?? false;
  }

  Future<bool> isServiceRunning() async {
    return (await _channel.invokeMethod<bool>('plugin.is_service_running')) ?? false;
  }

  Future<bool> startService() async {
    return (await _channel.invokeMethod<bool>('plugin.start_service')) ?? false;
  }

  Future<bool> stopService() async {
    return (await _channel.invokeMethod<bool>('service.stop_service')) ?? false;
  }

  Future<bool> cleanCache() async {
    return (await _channel.invokeMethod<bool>('plugin.clean_cache')) ?? false;
  }

  /// Promote the background service to a foreground service with custom notification info.
  Future<bool> promoteService({
    String title = 'HQFloating Service',
    String description = 'HQFloating service is running',
    String? icon,
    bool showWhen = false,
    String? ticker,
    String? subText,
  }) async {
    return (await _channel.invokeMethod<bool>('service.promote', {
      'title': title,
      'description': description,
      'icon': icon,
      'showWhen': showWhen,
      'ticker': ticker,
      'subText': subText,
    })) ?? false;
  }

  /// Demote the foreground service back to background.
  Future<bool> demoteService() async {
    return (await _channel.invokeMethod<bool>('service.demote')) ?? false;
  }

  /// Control whether the foreground service holds system WakeLock.
  Future<bool> setWakeLock(bool enabled) async {
    return (await _channel.invokeMethod<bool>('service.set_wakelock', {'enabled': enabled})) ?? false;
  }

  /// create window to create a window
  Future<HQFloatingWindow?> createWindow(
    String? id,
    HQFloatingWindowConfig config, {
    bool start = false, // start immediately if true
    HQFloatingWindow? window,
  }) async {
    var w = isWindow
        ? await currentWindow?.createChildWindow(
            id,
            config,
            start: start,
            window: window,
          )
        : await internalCreateWindow(
            id,
            config,
            start: start,
            window: window,
            channel: _channel,
          );
    if (w == null) return null;
    // store current window for window engine
    // for window engine use, update the current window
    // if we use create_window first?
    // _window = w; // we should don't use create_window first!!!
    // store the window to cache
    _windows[w.id] = w;
    return w;
  }

  // create window object for main engine
  Future<HQFloatingWindow?> internalCreateWindow(
    String? id,
    HQFloatingWindowConfig config, {
    bool start = false, // start immediately if true
    HQFloatingWindow? window,
    required MethodChannel channel,
    String name = 'plugin.create_window',
  }) async {
    // check permission first
    if (!await checkPermission()) {
      throw HQFloatingPermissionException(
        'No permission to create overlay window.',
      );
    }

    // store the window first
    // window.id can't be updated
    // for main engine use
    // if (window != null) _windows[window.id] = window;
    var updates = await channel.invokeMapMethod(name, {
      'id': id,
      'config': config.toMap(),
      'start': start,
    });
    // if window is not created, new one
    return updates == null ? null : (window ?? HQFloatingWindow()).applyMap(updates);
  }

  /// ensure window make sure the window object sync from android
  /// call this as soon at posible when engine start
  /// you should only call this in the window engine
  /// if only main as entry point, it's ok to call this
  /// and return nothing
  // only window engine call this
  // make sure window engine return only one window from every where
  Future<HQFloatingWindow?> ensureWindow() async {
    // window object don't have sync method, we must do at here
    // assert if you are in main engine should call this
    var map = await HQFloatingWindow.sync();
    log('[window] sync window object from android: $map');
    if (map == null) return null;
    // store current window if needed
    // use the static window first
    // so sync will return only one instance of window
    // improve this logic
    // means first time call sync, just create a new window
    final resolvedId = map['id'] as String? ?? 'default';
    _window ??= HQFloatingWindow(id: resolvedId);
    _window!.applyMap(map);
    _isWindow = true;
    return _window;
  }

  /// `on` register event handlers for all windows
  /// or we can use stream mode
  HQFloatingService on(
    HQFloatingEventType type,
    HQFloatingWindowListener callback,
  ) {
    onEvent.listen((event) {
      if (event.name == type.name) {
        final window = _windows[event.id] ?? _window;
        if (window != null) {
          callback(window, event.data);
        }
      }
    });
    return this;
  }
}
