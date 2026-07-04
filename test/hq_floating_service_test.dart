import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HQFloatingService', () {
    const MethodChannel methodChannel = MethodChannel(
      'hq.floating.bubble/method',
    );

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (
            MethodCall methodCall,
          ) async {
            switch (methodCall.method) {
              case 'plugin.has_permission':
                return true;
              case 'plugin.open_permission_setting':
                return true;
              case 'plugin.is_service_running':
                return true;
              case 'plugin.start_service':
                return true;
              case 'plugin.clean_cache':
                return true;
              case 'plugin.initialize':
                return {
                  'permission_grated': true,
                  'service_running': true,
                  'windows': [],
                };
              case 'plugin.sync_windows':
                return [
                  {
                    'id': 'window-1',
                    'config': {'entry': 'main', 'route': '/test'},
                  },
                  {
                    'id': 'window-2',
                    'config': {'entry': 'main', 'route': '/test2'},
                  },
                ];
              case 'plugin.create_window':
                return {
                  'id': methodCall.arguments['id'] ?? 'default',
                  'config': methodCall.arguments['config'],
                };
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('should be a singleton', () {
      final plugin1 = HQFloatingService();
      final plugin2 = HQFloatingService();

      expect(identical(plugin1, plugin2), isTrue);
    });

    test('instance getter should return same instance', () {
      final plugin = HQFloatingService();

      expect(identical(plugin, plugin.instance), isTrue);
    });

    test('checkPermission should return true', () async {
      final result = await HQFloatingService().checkPermission();

      expect(result, isTrue);
    });

    test('openPermissionSetting should return true', () async {
      final result = await HQFloatingService().openPermissionSetting();

      expect(result, isTrue);
    });

    test('isServiceRunning should return true', () async {
      final result = await HQFloatingService().isServiceRunning();

      expect(result, isTrue);
    });

    test('startService should return true', () async {
      final result = await HQFloatingService().startService();

      expect(result, isTrue);
    });

    test('cleanCache should return true', () async {
      final result = await HQFloatingService().cleanCache();

      expect(result, isTrue);
    });

    test('syncWindows should populate windows map', () async {
      // Clear any existing state
      HQFloatingService().windows.clear();

      final result = await HQFloatingService().syncWindows();

      expect(result, isTrue);
      expect(HQFloatingService().windows.length, equals(2));
      expect(HQFloatingService().windows.containsKey('window-1'), isTrue);
      expect(HQFloatingService().windows.containsKey('window-2'), isTrue);
    });

    test('windows should return map of windows', () {
      final windows = HQFloatingService().windows;

      expect(windows, isA<Map<String, HQFloatingWindow>>());
    });

    test('currentWindow should be null initially for main engine', () {
      // In main engine, currentWindow should be null until ensureWindow is called
      // Since we're testing as main engine, this is expected behavior
      expect(HQFloatingService().currentWindow, isNull);
    });

    test('isWindow should be false for main engine', () {
      // isWindow is false until ensureWindow succeeds with valid data
      // For main engine tests, this should be false
      expect(HQFloatingService().isWindow, isFalse);
    });

    test('createWindow should create and cache window', () async {
      final config = HQFloatingWindowConfig(route: '/new-window');

      final window = await HQFloatingService().createWindow('new-window', config);

      expect(window, isNotNull);
      expect(window?.id, equals('new-window'));
      expect(HQFloatingService().windows.containsKey('new-window'), isTrue);
    });

    test('createWindow with start=true should create started window', () async {
      final config = HQFloatingWindowConfig(route: '/started-window');

      final window = await HQFloatingService().createWindow(
        'started-window',
        config,
        start: true,
      );

      expect(window, isNotNull);
      expect(window?.id, equals('started-window'));
    });

    test('on should return plugin for chaining', () {
      final plugin = HQFloatingService();

      final result = plugin.on(HQFloatingEventType.WindowCreated, (window, data) {});

      expect(result, same(plugin));
    });
  });

  group('HQFloatingService channel constants', () {
    test('channelID should be correct', () {
      expect(
        HQFloatingService.channelID,
        equals('hq.floating.bubble'),
      );
    });
  });

  group('HQFloatingService permission flow', () {
    const MethodChannel methodChannel = MethodChannel(
      'hq.floating.bubble/method',
    );

    test('should handle permission denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'plugin.has_permission') {
              return false;
            }
            return null;
          });

      final result = await HQFloatingService().checkPermission();

      expect(result, isFalse);

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('createWindow should throw HQFloatingPermissionException when permission denied', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'plugin.has_permission') {
              return false;
            }
            return null;
          });

      final config = HQFloatingWindowConfig(route: '/test');

      expect(
        () => HQFloatingService().createWindow('test', config),
        throwsA(isA<HQFloatingPermissionException>()),
      );

      // Cleanup
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('event stream should broadcast events globally and window-specific', () async {
      final config = HQFloatingWindowConfig(route: '/test');
      final window = HQFloatingWindow(id: 'test_window', config: config);
      HQFloatingService().windows['test_window'] = window;

      final testEvent = HQFloatingEvent(id: 'test_window', name: 'window.created', data: 'hello');

      // Set up listener lists
      final List<HQFloatingEvent> globalEvents = [];
      final List<HQFloatingEvent> windowEvents = [];

      final globalSub = HQFloatingService().onEvent.listen((event) {
        globalEvents.add(event);
      });

      final windowSub = window.onEvent.listen((event) {
        windowEvents.add(event);
      });

      // Sink event into EventManager
      final msgChannel = BasicMessageChannel<dynamic>('hq.floating.bubble/window_msg', JSONMessageCodec());
      final manager = EventManager(msgChannel);
      manager.sink(testEvent);

      // Wait a moment for streams to dispatch
      await Future.delayed(Duration.zero);

      expect(globalEvents.length, equals(1));
      expect(globalEvents.first.name, equals('window.created'));
      expect(globalEvents.first.data, equals('hello'));

      expect(windowEvents.length, equals(1));
      expect(windowEvents.first.name, equals('window.created'));
      expect(windowEvents.first.data, equals('hello'));

      await globalSub.cancel();
      await windowSub.cancel();
      HQFloatingService().windows.remove('test_window');
    });
  });
}
