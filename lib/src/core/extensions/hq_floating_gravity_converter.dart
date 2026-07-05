import '../enums/hq_floating_gravity_type.dart';

extension HQFloatingGravityTypeConverter on HQFloatingGravityType {
  static const center = 17;
  static const top = 48;
  static const bottom = 80;
  static const left = 3;
  static const right = 5;

  static final _values = {
    HQFloatingGravityType.center: center,
    HQFloatingGravityType.centerTop: top | center,
    HQFloatingGravityType.centerBottom: bottom | center,
    HQFloatingGravityType.leftTop: top | left,
    HQFloatingGravityType.leftCenter: center | left,
    HQFloatingGravityType.leftBottom: bottom | left,
    HQFloatingGravityType.rightTop: top | right,
    HQFloatingGravityType.rightCenter: center | right,
    HQFloatingGravityType.rightBottom: bottom | right,
  };

  int? toInt() {
    return _values[this];
  }

  HQFloatingGravityType? fromInt(int? v) {
    if (v == null) return null;
    var r = _values.keys.firstWhere(
      (e) => _values[e] == v,
      orElse: () => HQFloatingGravityType.unknown,
    );
    return r == HQFloatingGravityType.unknown ? null : r;
  }
}
