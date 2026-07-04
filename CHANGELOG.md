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
