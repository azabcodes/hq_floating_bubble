import 'dart:ui';

class HQFloatingSystemConfig {
  int? pixelRadio;
  int? screenWidth;
  int? screenHeight;

  Size? screenSize;

  HQFloatingSystemConfig._({
    this.pixelRadio,
    this.screenWidth,
    this.screenHeight,
  }) {
    var w = screenWidth?.toDouble();
    var h = screenHeight?.toDouble();
    if (w != null && h != null) screenSize = Size(w, h);
  }

  Map<dynamic, dynamic> toMap() {
    return {
      "pixelRadio": pixelRadio,
      "screen": {
        "height": screenHeight,
        "width": screenWidth,
      },
    };
  }

  @override
  String toString() {
    return "${toMap()} $screenSize";
  }

  factory HQFloatingSystemConfig() {
    final view = PlatformDispatcher.instance.implicitView;
    return HQFloatingSystemConfig._(
      pixelRadio: view?.devicePixelRatio.toInt() ?? 1,
      screenHeight: view?.physicalSize.height.toInt() ?? 0,
      screenWidth: view?.physicalSize.width.toInt() ?? 0,
    );
  }

  factory HQFloatingSystemConfig.fromMap(Map<dynamic, dynamic> map) {
    var screen = map["screen"] ?? {};
    return HQFloatingSystemConfig._(
      pixelRadio: map["pixelRadio"],
      screenHeight: screen["height"],
      screenWidth: screen["width"],
    );
  }
}
