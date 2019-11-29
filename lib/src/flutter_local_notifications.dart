import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/src/notification_content.dart';
import 'package:flutter_local_notifications/src/received_notification.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'initialization_settings.dart';
import 'notification_app_launch_details.dart';
import 'notification_details.dart';
import 'pending_notification_request.dart';
import 'package:ansicolor/ansicolor.dart';

/// Signature of callback passed to [initialize]. Callback triggered when user taps on a notification

// ************** ABOUT DEPRECATED AND UNSECURE METHODS *******************
//
// https://github.com/MaikuB/flutter_local_notifications/issues/378
//
// ************************************************************************

// TODO DEPRECATED
typedef SelectNotificationCallback = Future<dynamic> Function(String payload);
typedef ReceiveNotificationCallback = Future<dynamic> Function(ReceivedNotification returnDetails);

// Signature of the callback that is triggered when a notification is shown whilst the app is in the foreground. Applicable to iOS versions < 10 only
typedef DidReceiveLocalNotificationCallback = Future<dynamic> Function(
    int id, String title, String body, String payload);

/// The available intervals for periodically showing notifications
enum RepeatInterval { EveryMinute, Hourly, Daily, Weekly }

/// The days of the week
class Day {
  static const Sunday = Day(1);
  static const Monday = Day(2);
  static const Tuesday = Day(3);
  static const Wednesday = Day(4);
  static const Thursday = Day(5);
  static const Friday = Day(6);
  static const Saturday = Day(7);

  static get values =>
      [Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday];

  final int value;

  const Day(this.value);
}

/// Used for specifying a time in 24 hour format
class Time {
  /// The hour component of the time. Accepted range is 0 to 23 inclusive
  final int hour;

  /// The minutes component of the time. Accepted range is 0 to 59 inclusive
  final int minute;

  /// The seconds component of the time. Accepted range is 0 to 59 inclusive
  final int second;

  Time([this.hour = 0, this.minute = 0, this.second = 0]) {
    assert(this.hour >= 0 && this.hour < 24);
    assert(this.minute >= 0 && this.minute < 60);
    assert(this.second >= 0 && this.second < 60);
  }

  Map<String, int> toMap() {
    return <String, int>{
      'hour': hour,
      'minute': minute,
      'second': second,
    };
  }
}

class FlutterLocalNotificationsPlugin {
  factory FlutterLocalNotificationsPlugin() => _instance;

  @visibleForTesting
  FlutterLocalNotificationsPlugin.private(
      MethodChannel channel, Platform platform)
      : _channel = channel,
        _platform = platform;

  static final FlutterLocalNotificationsPlugin _instance =
      FlutterLocalNotificationsPlugin.private(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          const LocalPlatform());

  final MethodChannel _channel;
  final Platform _platform;

  SelectNotificationCallback  selectNotificationCallback;
  ReceiveNotificationCallback receiveNotificationCallback;
  DidReceiveLocalNotificationCallback didReceiveLocalNotificationCallback;

  void _validateId(int id) {
    if (id > 0x7FFFFFFF || id < -0x80000000) {
      throw ArgumentError(
          'id must fit within the size of a 32-bit integer i.e. in the range [-2^31, 2^31 - 1]');
    }
  }

  _showDeprecatedWarning(){
    AnsiPen pen = AnsiPen()..white(bold: true)..rgb(r: 1.0, g: 0.0, b: 0.0);

    // TODO link example
    debugPrint(
      pen("*************  WARNING: YOU ARE USING A DEPRECATED METHOD  *******************\n")+
      pen("** Do not pass plain text over notifications. Use Payload object instead.\n")+
      pen("** Examples at XXXXXXXX\n")+
      pen("*****************************************************************************")
    );
  }

  /// Initializes the plugin. Call this method on application before using the plugin further. This should only be done once. When a notification created by this plugin was used to launch the app, calling `initialize` is what will trigger to the `onSelectNotification` callback to be fire.
  Future<bool> initialize(InitializationSettings initializationSettings,
      {
        SelectNotificationCallback onSelectNotification,
        ReceiveNotificationCallback onReceiveNotification
      }
  ) async {
    selectNotificationCallback  = onSelectNotification;
    receiveNotificationCallback = onReceiveNotification;

    didReceiveLocalNotificationCallback =
        initializationSettings?.ios?.onDidReceiveLocalNotification;

    var serializedPlatformSpecifics =
        _retrievePlatformSpecificInitializationSettings(initializationSettings);

    _channel.setMethodCallHandler(_handleMethod);

    /*final CallbackHandle callback =
        PluginUtilities.getCallbackHandle(_callbackDispatcher);
    serializedPlatformSpecifics['callbackDispatcher'] = callback.toRawHandle();
    if (onShowNotification != null) {
      serializedPlatformSpecifics['onNotificationCallbackDispatcher'] =
          PluginUtilities.getCallbackHandle(onShowNotification).toRawHandle();
    }*/

    var result =
        await _channel.invokeMethod('initialize', serializedPlatformSpecifics);
    return result;
  }

  Future<NotificationAppLaunchDetails> getNotificationAppLaunchDetails() async {
    var result = await _channel.invokeMethod('getNotificationAppLaunchDetails');
    return NotificationAppLaunchDetails(result['notificationLaunchedApp'],
        result.containsKey('payload') ? result['payload'] : null);
  }

  Map<String, String> _getDeprecatedPayload(String payload){
    return {
      'deprecated': 'true',
      'plainText': payload ?? ''
    };
  }

  /// (DEPRECATED) Show a notification with an optional payload that will be passed back to the app when a notification is tapped
  @Deprecated('This method incentives unsecure practices. Use showNotification instead')
  Future<void> show(
      int id, String title, String body,
      NotificationDetails notificationDetails,
      {String payload}) async {

    // TODO Remove deprecated methods
    _showDeprecatedWarning();

    NotificationContent notificationContent =
        NotificationContent(
          id: id,
          title: title,
          body: body,
          payload: _getDeprecatedPayload(payload)
        );

    return showNotification(notificationDetails, notificationContent);
  }

  /// Show a notification with an optional payload that will be passed back to the app when a notification is tapped
  Future<void> showNotification(NotificationDetails notificationDetails, NotificationContent notificationContent) async {
    _validateId(notificationContent.id);

    var serializedPlatformSpecifics = _retrievePlatformSpecificNotificationDetails(notificationDetails);
    await _channel.invokeMethod(
        'show',
        notificationContent.toMap()..addAll({
          'platformSpecifics': serializedPlatformSpecifics
        })
    );
  }

  /// Schedules a notification to be shown at the specified time with an optional payload that is passed through when a notification is tapped
  /// The [androidAllowWhileIdle] parameter is Android-specific and determines if the notification should still be shown at the specified time
  /// even when in a low-power idle mode.
  @Deprecated('This method incentives unsecure practices. Use showNotificationSchedule instead')
  Future<void> schedule(int id, String title, String body,
      DateTime scheduledDate, NotificationDetails notificationDetails,
      {String payload, bool androidAllowWhileIdle = false}) async {

    // TODO Remove deprecated methods
    _showDeprecatedWarning();

    return showNotificationSchedule(
        scheduledDate,
        notificationDetails,
        androidAllowWhileIdle: androidAllowWhileIdle,
        notificationContent: NotificationContent(
          id: id,
          title: title,
          body: body,
          payload: _getDeprecatedPayload(payload)
        )
    );
  }

  Future<void> showNotificationSchedule(
      DateTime scheduledDate,
      NotificationDetails notificationDetails,
      {
        NotificationContent notificationContent,
        bool androidAllowWhileIdle = false
      }) async {

    _validateId(notificationContent.id);

    var serializedPlatformSpecifics =
          _retrievePlatformSpecificNotificationDetails(notificationDetails);

    if (_platform.isAndroid) {
      serializedPlatformSpecifics['allowWhileIdle'] = androidAllowWhileIdle;
    }

    await _channel.invokeMethod(
        'schedule',
        notificationContent.toMap()..addAll({
          'millisecondsSinceEpoch': scheduledDate.millisecondsSinceEpoch,
          'platformSpecifics': serializedPlatformSpecifics,
        })
    );
  }



  /// Periodically show a notification using the specified interval.
  /// For example, specifying a hourly interval means the first time the notification will be an hour after the method has been called and then every hour after that.
  @Deprecated('This method incentives unsecure practices. Use showNotificationPeriodically instead')
  Future<void> periodicallyShow(int id, String title, String body,
      RepeatInterval repeatInterval, NotificationDetails notificationDetails,
      {String payload}) async {

    // TODO Remove deprecated methods
    _showDeprecatedWarning();

    return showNotificationPeriodically(
      repeatInterval,
      notificationDetails,
      NotificationContent(
        id: id,
        title: title,
        body: body,
        payload: _getDeprecatedPayload(payload)
      )
    );
  }

  Future<void> showNotificationPeriodically(
        RepeatInterval repeatInterval, NotificationDetails notificationDetails, NotificationContent notificationContent
      ) async {

    _validateId(notificationContent.id);

    var serializedPlatformSpecifics =
    _retrievePlatformSpecificNotificationDetails(notificationDetails);

    await _channel.invokeMethod(
        'periodicallyShow',
        notificationContent.toMap()..addAll({
          'calledAt': DateTime.now().millisecondsSinceEpoch,
          'repeatInterval': repeatInterval.index,
          'platformSpecifics': serializedPlatformSpecifics,
        })
    );
  }

  /// Shows a notification on a daily interval at the specified time
  @Deprecated('This method incentives unsecure practices. Use showNotificationDailyAtTime instead')
  Future<void> showDailyAtTime(int id, String title, String body,
      Time notificationTime, NotificationDetails notificationDetails,
      {String payload}) async {

    // TODO Remove deprecated methods
    _showDeprecatedWarning();

    return showNotificationDailyAtTime(notificationTime, notificationDetails,
      NotificationContent(
          id: id,
          title: title,
          body: body,
          payload: _getDeprecatedPayload(payload)
      )
    );
  }

  /// Shows a notification on a daily interval at the specified time
  Future<void> showNotificationDailyAtTime(
      Time notificationTime, NotificationDetails notificationDetails, NotificationContent notificationContent
  ) async {

    _validateId(notificationContent.id);

    var serializedPlatformSpecifics =
      _retrievePlatformSpecificNotificationDetails(notificationDetails);

    await _channel.invokeMethod(
        'showDailyAtTime',
        notificationContent.toMap()..addAll({
          'calledAt': DateTime.now().millisecondsSinceEpoch,
          'repeatInterval': RepeatInterval.Daily.index,
          'repeatTime': notificationTime.toMap(),
          'platformSpecifics': serializedPlatformSpecifics,
        })
    );
  }

  /// Shows a notification on a daily interval at the specified time
  @Deprecated('This method incentives unsecure practices. Use showNotificationWeeklyAtDayAndTime instead')
  Future<void> showWeeklyAtDayAndTime(int id, String title, String body,
      Day day, Time notificationTime, NotificationDetails notificationDetails,
      {String payload}) async {

    // TODO Remove deprecated methods
    _showDeprecatedWarning();

    return showNotificationWeeklyAtDayAndTime(day, notificationTime, notificationDetails,
      NotificationContent(
          id: id,
          title: title,
          body: body,
          payload: _getDeprecatedPayload(payload)
      )
    );
  }

  Future<void> showNotificationWeeklyAtDayAndTime(
      Day day, Time notificationTime, NotificationDetails notificationDetails, NotificationContent notificationContent
  ) async {

    _validateId(notificationContent.id);

    var serializedPlatformSpecifics =
    _retrievePlatformSpecificNotificationDetails(notificationDetails);

    await _channel.invokeMethod(
        'showWeeklyAtDayAndTime',
        notificationContent.toMap()..addAll({
          'calledAt': DateTime.now().millisecondsSinceEpoch,
          'repeatInterval': RepeatInterval.Weekly.index,
          'repeatTime': notificationTime.toMap(),
          'day': day.value,
          'platformSpecifics': serializedPlatformSpecifics,
        })
    );
  }

  /// Cancel/remove the notification with the specified id. This applies to notifications that have been scheduled and those that have already been presented.
  Future<void> cancel(int id) async {
    _validateId(id);
    await _channel.invokeMethod('cancel', id);
  }

  /// Cancels/removes all notifications. This applies to notifications that have been scheduled and those that have already been presented.
  Future<void> cancelAll() async {
    await _channel.invokeMethod('cancelAll');
  }

  /// Returns a list of notifications pending to be delivered/shown
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {

    final List<Map<dynamic, dynamic>> pendingNotifications =
        await _channel.invokeListMethod('pendingNotificationRequests');

    return pendingNotifications
        .map((pendingNotification) => PendingNotificationRequest(
            pendingNotification['id'],
            pendingNotification['title'],
            pendingNotification['body'],
            pendingNotification['payload']))
        .toList();
  }

  Map<String, dynamic> _retrievePlatformSpecificNotificationDetails(
      NotificationDetails notificationDetails) {

    Map<String, dynamic> serializedPlatformSpecifics;

    if (_platform.isAndroid) {
      serializedPlatformSpecifics = notificationDetails?.android?.toMap();
    } else if (_platform.isIOS) {
      serializedPlatformSpecifics = notificationDetails?.iOS?.toMap();
    }

    return serializedPlatformSpecifics;
  }

  Map<String, dynamic> _retrievePlatformSpecificInitializationSettings(
      InitializationSettings initializationSettings) {

    Map<String, dynamic> serializedPlatformSpecifics;

    if (_platform.isAndroid) {
      serializedPlatformSpecifics = initializationSettings?.android?.toMap();
    } else if (_platform.isIOS) {
      serializedPlatformSpecifics = initializationSettings?.ios?.toMap();
    }

    return serializedPlatformSpecifics;
  }

  Future<void> _handleMethod(MethodCall call) {

    Map<String, dynamic> arguments = Map<String, dynamic>.from(call.arguments);

    switch (call.method) {

      case 'receiveNotification':

        // keep the deprecated method working for a while
        if(call.arguments['payload'] != null && call.arguments['payload']['deprecated'] != null){

          if(call.arguments['source'] == 'NotificationSource.foreground'){

            return didReceiveLocalNotificationCallback(
                call.arguments['id'],
                call.arguments['title'],
                call.arguments['body'],
                call.arguments['payload']['plainText'] ?? ''
            );

          } else {

            return selectNotificationCallback(
              // Not safe
                call.arguments['payload']['plainText'] ?? ''
            );
          }

        } else {

          return receiveNotificationCallback(
              ReceivedNotification().fromMap(arguments)
          );
        }
        break;

      case 'didReceiveLocalNotification':

        // keep the deprecated method working for a while
        if(call.arguments['payload'] != null && call.arguments['payload']['deprecated'] != null){

          return didReceiveLocalNotificationCallback(
              call.arguments['id'],
              call.arguments['title'],
              call.arguments['body'],
              call.arguments['payload']['plainText'] ?? ''
          );

        } else {

          return receiveNotificationCallback(
              ReceivedNotification().fromMap(call.arguments)
          );
        }
        break;

      default:
        return Future.error('method not defined');
    }
  }
}
