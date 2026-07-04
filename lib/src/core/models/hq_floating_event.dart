/// HQFloatingEvent is a common event
class HQFloatingEvent {
  /// id is window id
  String? id;

  /// name is the event name
  String? name;

  /// data is the payload for event
  dynamic data;

  HQFloatingEvent({this.id, this.name, this.data});

  factory HQFloatingEvent.fromMap(Map<dynamic, dynamic> map) {
    return HQFloatingEvent(id: map["id"], name: map["name"], data: map["data"]);
  }
}
