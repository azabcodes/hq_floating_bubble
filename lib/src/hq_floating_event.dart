import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

class EventManager {
  EventManager._(this._msgChannel) {
    // set just for window, so window have no need to do this
    _msgChannel.setMessageHandler((msg) {
      var map = msg as Map<dynamic, dynamic>?;
      if (map == null) {
        log('[event] unsupported message, we except a map');
        return Future.value(null);
      }
      var evt = HQFloatingEvent.fromMap(map);
      var rs = sink(evt);
      log('[event] handled event: ${evt.name}, handlers: ${rs.length}');
      return Future.value(null);
    });
  }

  final Map<String, Map<String, Map<HQFloatingWindow, List<HQFloatingWindowListener>>>> _listeners =
      {};

  final Map<String, List<HQFloatingWindow>> _windows = {};

  BasicMessageChannel _msgChannel;

  static final Map<String, EventManager> _instances = {};

  factory EventManager(BasicMessageChannel msgChannel) {
    if (_instances[msgChannel.name] == null) {
      _instances[msgChannel.name] = EventManager._(msgChannel);
    }
    return _instances[msgChannel.name]!;
  }

  List<dynamic> sink(HQFloatingEvent evt) {
    var res = [];
    // w.id -> type -> w -> [cb]

    // Broadcast globally
    HQFloatingService().eventController.add(evt);

    // Broadcast to the specific window if it exists
    final window = HQFloatingService().windows[evt.id];
    if (window != null) {
      window.eventController.add(evt);
    }

    // get windows
    var ws = (_listeners[evt.id] ?? {})[evt.name] ?? {};
    ws.forEach((w, cbs) {
      for (var c in (cbs)) {
        res.add(c(w, evt.data));
      }
    });
    return res;
  }

  EventManager on(
    HQFloatingWindow window,
    HQFloatingEventType type,
    HQFloatingWindowListener callback,
  ) {
    var key = type.name;
    log('[event] register listener $key for $window');
    
    if (_windows[window.id] == null) _windows[window.id] = [];
    if (!_windows[window.id]!.contains(window)) {
      _windows[window.id]!.add(window);
    }

    // w.id -> w -> type -> [cb]
    if (_listeners[window.id] == null) _listeners[window.id] = {};
    if (_listeners[window.id]![key] == null) _listeners[window.id]![key] = {};
    if (_listeners[window.id]![key]![window] == null) {
      _listeners[window.id]![key]![window] = [];
    }
    if (!_listeners[window.id]![key]![window]!.contains(callback)) {
      _listeners[window.id]![key]![window]!.add(callback);
    }
    return this;
  }

  EventManager off(
    HQFloatingWindow window,
    HQFloatingEventType type,
    HQFloatingWindowListener callback,
  ) {
    var key = type.name;
    log('[event] unregister listener $key for $window');
    if (_listeners[window.id] != null &&
        _listeners[window.id]![key] != null &&
        _listeners[window.id]![key]![window] != null) {
      _listeners[window.id]![key]![window]!.remove(callback);
      if (_listeners[window.id]![key]![window]!.isEmpty) {
        _listeners[window.id]![key]!.remove(window);
      }
      if (_listeners[window.id]![key]!.isEmpty) {
        _listeners[window.id]!.remove(key);
      }
      if (_listeners[window.id]!.isEmpty) {
        _listeners.remove(window.id);
        _windows.remove(window.id);
      }
    }
    return this;
  }

  EventManager clear(HQFloatingWindow window) {
    _listeners.remove(window.id);
    _windows.remove(window.id);
    return this;
  }

  @override
  String toString() {
    return 'EventManager@${super.hashCode}';
  }
}
