import 'dart:convert';

import 'package:meta/meta.dart';

class NotificationActionButton {
  String key;
  String label;
  bool autoCancel;
  bool requiresInput;

  NotificationActionButton({@required this.key, @required this.label, this.autoCancel, this.requiresInput}){
    requiresInput = requiresInput ?? false;
    autoCancel = autoCancel ?? true;
  }

  NotificationActionButton fromMap(Map<String, dynamic> data) {

    key = data['key'];
    label = data['label'];
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