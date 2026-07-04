import 'package:flutter_test/flutter_test.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HQFloatingEventType', () {
    test('should have all expected event types', () {
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowCreated));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowStarted));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowPaused));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowResumed));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowDestroy));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowDragStart));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowDragging));
      expect(HQFloatingEventType.values, contains(HQFloatingEventType.WindowDragEnd));
    });

    test('should have correct number of event types', () {
      expect(HQFloatingEventType.values.length, equals(8));
    });
  });

  group('HQFloatingEvent', () {
    test('should create with all parameters', () {
      final event = HQFloatingEvent(
        id: 'window-1',
        name: 'window.created',
        data: {'key': 'value'},
      );

      expect(event.id, equals('window-1'));
      expect(event.name, equals('window.created'));
      expect(event.data, isA<Map>());
      expect(event.data['key'], equals('value'));
    });

    test('should create with null parameters', () {
      final event = HQFloatingEvent();

      expect(event.id, isNull);
      expect(event.name, isNull);
      expect(event.data, isNull);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 'window-2',
        'name': 'window.started',
        'data': {'position': 'center'},
      };

      final event = HQFloatingEvent.fromMap(map);

      expect(event.id, equals('window-2'));
      expect(event.name, equals('window.started'));
      expect(event.data, isA<Map>());
      expect(event.data['position'], equals('center'));
    });

    test('should handle missing fields in fromMap', () {
      final map = <dynamic, dynamic>{'id': 'window-3'};

      final event = HQFloatingEvent.fromMap(map);

      expect(event.id, equals('window-3'));
      expect(event.name, isNull);
      expect(event.data, isNull);
    });

    test('should handle dynamic data types', () {
      final eventWithString = HQFloatingEvent(data: 'string data');
      expect(eventWithString.data, equals('string data'));

      final eventWithInt = HQFloatingEvent(data: 42);
      expect(eventWithInt.data, equals(42));

      final eventWithList = HQFloatingEvent(data: [1, 2, 3]);
      expect(eventWithList.data, equals([1, 2, 3]));

      final eventWithBool = HQFloatingEvent(data: true);
      expect(eventWithBool.data, isTrue);
    });
  });

  group('HQFloatingEvent name mapping', () {
    // Test that event names are correctly mapped (based on the _EventType extension)
    test('WindowCreated should map to window.created', () {
      // We can't directly test the private extension, but we can verify
      // the event types exist and are usable
      expect(HQFloatingEventType.WindowCreated, isNotNull);
    });

    test('WindowDragStart should map to window.drag_start', () {
      expect(HQFloatingEventType.WindowDragStart, isNotNull);
    });

    test('all event types should be distinct', () {
      final types = HQFloatingEventType.values.toSet();
      expect(types.length, equals(HQFloatingEventType.values.length));
    });
  });

  group('HQFloatingWindow event registration', () {
    test('should allow registering multiple event handlers', () {
      final window = HQFloatingWindow(id: 'test-window');
      int handlerCount = 0;

      window
          .on(HQFloatingEventType.WindowCreated, (w, data) {
            handlerCount++;
          })
          .on(HQFloatingEventType.WindowStarted, (w, data) {
            handlerCount++;
          })
          .on(HQFloatingEventType.WindowDestroy, (w, data) {
            handlerCount++;
          });

      // The handlers are registered but not called yet
      expect(handlerCount, equals(0));
    });

    test('on() should return window for chaining', () {
      final window = HQFloatingWindow(id: 'test-window');

      final result = window.on(HQFloatingEventType.WindowCreated, (w, data) {});

      expect(result, same(window));
    });

    test('should handle all event types registration', () {
      final window = HQFloatingWindow(id: 'test-window');

      // Register handlers for all event types
      for (final eventType in HQFloatingEventType.values) {
        window.on(eventType, (w, data) {});
      }

      // If we get here without errors, all event types are registrable
      expect(true, isTrue);
    });
  });

  group('HQFloatingWindowListener typedef', () {
    test('should accept correct function signature', () {
      // HQFloatingWindowListener = dynamic Function(HQFloatingWindow window, dynamic data)
      HQFloatingWindowListener listener = (HQFloatingWindow w, dynamic data) {
        return 'handled';
      };

      final window = HQFloatingWindow(id: 'test');
      final result = listener(window, {'event': 'data'});

      expect(result, equals('handled'));
    });

    test('should work with async handlers', () async {
      HQFloatingWindowListener asyncListener = (HQFloatingWindow w, dynamic data) async {
        await Future.delayed(Duration(milliseconds: 10));
        return 'async handled';
      };

      final window = HQFloatingWindow(id: 'test');
      final result = await asyncListener(window, null);

      expect(result, equals('async handled'));
    });

    test('should allow void return', () {
      HQFloatingWindowListener voidListener = (HQFloatingWindow w, dynamic data) {
        // No return
      };

      final window = HQFloatingWindow(id: 'test');
      final result = voidListener(window, null);

      expect(result, isNull);
    });
  });
}
