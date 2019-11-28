class NotificationActionButton {
  String key;
  String label;
  bool autoCancel;

  NotificationActionButton({this.key, this.label, this.autoCancel});

  NotificationActionButton fromMap(Map<String, dynamic> data) {

    key = data['key'];
    label = data['key'];
    autoCancel = data['autoCancel'];

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'autoCancel': autoCancel
    };
  }
}