import '../enums/hq_floating_event_type.dart';

extension HQFloatingEventTypeExtension on HQFloatingEventType {
  /// Parse event type from string (reserved for future use)
  static HQFloatingEventType? fromString(String v) {
    try {
      return HQFloatingEventType.values.firstWhere((e) => e.name == v);
    } catch (_) {
      return null;
    }
  }

  String get name => switch (this) {
    HQFloatingEventType.WindowCreated => 'window.created',
    HQFloatingEventType.WindowStarted => 'window.started',
    HQFloatingEventType.WindowPaused => 'window.paused',
    HQFloatingEventType.WindowResumed => 'window.resumed',
    HQFloatingEventType.WindowDestroy => 'window.destroy',
    HQFloatingEventType.WindowDragStart => 'window.drag_start',
    HQFloatingEventType.WindowDragging => 'window.dragging',
    HQFloatingEventType.WindowDragEnd => 'window.drag_end',
  };
}
