enum NotificationSource{ foreground, application }

class ReceivedNotification {

  int notification_id = -1;
  NotificationSource source;
  String buttonKeyPressed = '';
  String buttonKeyInput = '';
  Map<String, String> payload;
  String receivedDate;
  String createdDate;

  ReceivedNotification({
    this.notification_id,
    this.source,
    this.buttonKeyPressed,
    this.buttonKeyInput,
    this.payload
  });

  ReceivedNotification fromMap(Map<String, dynamic> receivedContent) {

    source =
        receivedContent['source'] != null ?
          NotificationSource.values.firstWhere((e) => e.toString() == receivedContent['source']) :
          null;

    notification_id  = receivedContent['notification_id'];
    buttonKeyPressed = receivedContent['action_key'];
    buttonKeyInput   = receivedContent['action_input'];
    createdDate      = receivedContent['created_date'];
    receivedDate     = receivedContent['received_date'];

    payload = Map<String, String>.from(receivedContent['payload']);

    return this;
  }

  Map<String, dynamic> toMap() {

    return {
      'source': source,
      'notification_id': notification_id,
      'createdDate': createdDate,
      'receivedDate': receivedDate,
      'buttonKeyPressed': buttonKeyPressed,
      'buttonKeyInput': buttonKeyInput,
      'payload': payload,
    };

  }

  @override
  String toString() {
    return toMap().toString()
        .replaceAll(',', ',\n')
        .replaceAll('[\{\[]', '\$1\n')
        .replaceAll('[\}\]]', '\n\$1');
  }
}