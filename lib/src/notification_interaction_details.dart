enum NotificationSource{ foreground, application }

class NotificationInteractionDetails {

  int notification_id = -1;
  NotificationSource source;
  String buttonKeyPressed = '';
  String buttonReplyInput = '';
  Map<String, String> payload;

  NotificationInteractionDetails({
    this.notification_id,
    this.source,
    this.buttonKeyPressed,
    this.buttonReplyInput
  });

  NotificationInteractionDetails fromMap(Map<String, dynamic> receivedContent) {

    source =
        receivedContent['source'] != null ?
          NotificationSource.values.firstWhere((e) => e.toString() == receivedContent['source']) :
          null;

    notification_id = receivedContent['notification_id'];
    buttonKeyPressed = receivedContent['action_key'];
    buttonReplyInput = receivedContent['action_input'];

    payload = Map<String, String>.from(receivedContent['payload']);

    return this;
  }

  Map<String, dynamic> toMap() {

    return {
      'notification_id': notification_id,
      'source': source,
      'payload': payload,
      'buttonKeyPressed': buttonKeyPressed,
      'buttonReplyInput': buttonReplyInput,
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