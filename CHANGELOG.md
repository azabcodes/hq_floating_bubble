## 0.0.5

* Implemented major performance, layout, and BLoC architecture optimizations:
  * Refactored example app state management to follow professional BLoC architecture, separating Touch, Panel, and Home into distinct events, states, and blocs.
  * Simplified `AssistiveButton` layout logic to use standard const `56x56` size, eliminating dynamic `RenderBox` bounds check overhead and listener leaks.
  * Added auto-repositioning support for screen rotation and keyboard-safe view padding/insets changes.
  * Throttled native gesture movement coordinates update updates in `ACTION_MOVE` to at most once per 16ms to drastically lower CPU consumption.
  * Prevented redundant WindowManager layout redraw updates when bounds/dimensions are unchanged on update.
  * Added safe animation cancels inside window destruction to prevent late anim callbacks.
  * Added clean `offData` listener release method inside `HQFloatingWindow` and integrated it in BLoCs.

## 0.0.4

* Implemented stability & memory management updates on the native Android (Kotlin) layer:
  * Prevented Activity memory leaks using `WeakReference<Activity>`.
  * Resolved overlay request race conditions in `waitPermissionResult`.
  * Fully added Android 14+ Foreground Service support (`specialUse`) with native manifest declarations.
  * Re-registered active activity reference during configurations/orientations rotation changes.
  * Wrapped overlay view removal in try-catch to prevent layout detachment crashes.
  * Added safety type conversion for all parameters sent from Dart to prevent conversion crashes.
  * Prevented event filter bypasses and resolved concurrent modification exceptions in window lifecycle lists.

## 0.0.3

* Fixed Kotlin compilation error where `JSONObject.toMap()` was unresolved by moving the extension function to the package level.

## 0.0.2

* Updated Android configuration documentation in README.md with explicit permission declarations and `HQFloatingService` service configurations for full compatibility.

## 0.0.1


* Initial release with support for Android system-level floating bubble overlay windows.
* Complete refactoring and naming cleanup to `hq_floating_bubble` and `hq.floating.bubble`.
* Modularized core codebase separating enums, extensions, constants, typedefs, models, and services under `lib/src/core/`.
* Implemented display constraints and horizontal magnet snapping animation on drag release.
* Implemented smooth Scale & Fade transitions for window visibility updates.
* Implemented customizable Foreground Service Notifications with title, description, and dynamic drawable resource resolution.
* Implemented dynamic system CPU WakeLock control to manage battery safety.
* Implemented reactive streams event system (`onEvent`) for global and window-specific overlay events.
* Added custom structured exception types (`HQFloatingPermissionException`, etc.).
