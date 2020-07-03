import 'dart:convert';
import 'package:intl/intl.dart';

enum NotificationSource{ foreground, background }

class ReceivedNotification {

  int notification_id = -1;
  String title;
  String body;
  NotificationSource source;
  String buttonKeyPressed = '';
  String buttonKeyInput = '';
  Map<String, String> payload;
  String receivedDate;
  String createdDate = DateFormat('yyyy-MM-dd H:m:s').format(DateTime.now());

  ReceivedNotification({
    this.notification_id,
    this.title,
    this.body,
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
    title            = receivedContent['title'];
    body             = receivedContent['body'];
    buttonKeyPressed = receivedContent['action_key'];
    buttonKeyInput   = receivedContent['action_input'];
    createdDate      = receivedContent['created_date'];
    receivedDate     = receivedContent['received_date'];

    payload = receivedContent['payload'] != null ? Map<String, String>.from(receivedContent['payload']) : null;

    return this;
  }

  Map<String, dynamic> toMap() {

    return {
      'source': source,
      'notification_id': notification_id,
      'title': title,
      'body': body,
      'createdDate': createdDate,
      'receivedDate': receivedDate,
      'buttonKeyPressed': buttonKeyPressed,
      'buttonKeyInput': buttonKeyInput,
      'payload': payload,
    };

  }

  @override
  String toString() {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');

    Map json = toMap();
    json['source'] = json['source'].toString();
    String prettyPrint = encoder.convert(json);

    return prettyPrint;
  }
}