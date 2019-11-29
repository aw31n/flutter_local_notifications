import 'notification_action_button.dart';

class NotificationContent {

  // TODO remove this parameter when all the plain text notifications a
  bool isUsingDeprecated = false;

  int id = 0;
  String title = '';
  String body = '';


  List<NotificationActionButton> actionButtons;
  Map<String, String> payload;

  NotificationContent({
    this.id,
    this.title,
    this.body,
    this.actionButtons,
    this.payload
  });

  NotificationContent fromMap(Map<String, dynamic> receivedPayload) {

    id      = receivedPayload['id'];
    title   = receivedPayload['title'];
    body    = receivedPayload['body'];
    payload = receivedPayload['payload'];

    if(receivedPayload['actionButtons'] != null && receivedPayload['actionButtons'] is List && receivedPayload['actionButtons'].lenght > 0){
      actionButtons = [];
      receivedPayload['actionButtons'].forEach(
          (actionButton) => actionButtons.add(
              NotificationActionButton().fromMap(actionButton)
          )
      );
    }

    return this;
  }

  Map<String, dynamic> toMap() {
    List<dynamic> actionButtonList = [];

    if(actionButtons != null){
      actionButtons.forEach((actionButton) => actionButtonList.add(actionButton.toMap()));
    }

    return {
      'id': id,
      'title': title,
      'body': body,
      'actionButtons': actionButtonList,
      'payload': payload
    };
  }

  @override
  String toString() {
    return toMap().toString().replaceAll(',', ',\n');
  }
}