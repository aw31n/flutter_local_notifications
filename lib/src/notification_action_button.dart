import 'dart:convert';

class NotificationActionButton {
  String key;
  String label;
  bool autoCancel;
  bool requiresInput;

  NotificationActionButton({this.key, this.label, this.autoCancel, this.requiresInput}){
    requiresInput = requiresInput ?? false;
  }

  NotificationActionButton fromMap(Map<String, dynamic> data) {

    key = data['key'];
    label = data['key'];
    autoCancel = data['autoCancel'];
    requiresInput = data['requiresInput'];

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'autoCancel': autoCancel,
      'requiresInput': requiresInput
    };
  }

  @override
  String toString() {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');

    Map json = toMap();
    String prettyPrint = encoder.convert(json);

    return prettyPrint;
  }
}