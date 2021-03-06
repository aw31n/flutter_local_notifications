import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<String> didReceiveNotificationSubject = BehaviorSubject<String>();
final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();
final BehaviorSubject<ReceivedNotification> receiveNotificationSubject = BehaviorSubject<ReceivedNotification>();


// Pause and Play vibration sequences
final Int64List lowVibrationPattern    = Int64List.fromList([ 0, 200, 200, 200 ]);
final Int64List mediumVibrationPattern = Int64List.fromList([ 0, 500, 200, 200, 200, 200 ]);
final Int64List highVibrationPattern   = Int64List.fromList([ 0, 1000, 200, 200, 200, 200, 200, 200 ]);

List<Int64List> vibrationPatterns = [lowVibrationPattern, mediumVibrationPattern, highVibrationPattern];




/// IMPORTANT: running the following code on its own won't work as there is setup required for each platform head project.
/// Please download the complete example app from the GitHub repository where all the setup has been done
Future<void> main() async {

  // needed if you intend to initialize in the `main` function
  WidgetsFlutterBinding.ensureInitialized();

  InitializationSettings initializationSettings = InitializationSettings(
      AndroidInitializationSettings('app_icon'),
      IOSInitializationSettings(
          onDidReceiveLocalNotification: (int id, String title, String body, String payload) async {
            didReceiveNotificationSubject.add(payload);
          }
      )
  );

  await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // Deprecated Method
      onSelectNotification: (String payloadPainText) async {
        debugPrint('Notification received: '+(payloadPainText ?? 'null'));
        // On this stage, BuildContext do not exist yet. Lets add an event to be captured later.
        selectNotificationSubject.add(payloadPainText);

      },
      // Replace to onSelectNotification
      onReceiveNotification: (ReceivedNotification returnDetails) async {
        // On this stage, BuildContext do not exist yet. Lets add an event to be captured later.
        debugPrint('Notification received: id ' + returnDetails.notification_id.toString());
        receiveNotificationSubject.add(returnDetails);
      }
  );


  runApp(MaterialApp( home: HomePage() ));
}




class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final MethodChannel platform =
      MethodChannel('crossingthestreams.io/resourceResolver');

  bool patternTestShouldSchedule = false;

  _showAlertDidReceiveNotification(String payload){
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            CupertinoAlertDialog(
              title: Text('didReceivedNotification'),
              content: Text('notification received when the app was closed'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Ok'),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.push(context, MaterialPageRoute( builder: (context) =>
                        SecondScreen(payload)
                    ));
                  },
                )
              ],
            )
    );
  }

  @override
  void initState() {
    super.initState();

    selectNotificationSubject.stream.listen(
        (String payloadPainText){
          Navigator.push( context, MaterialPageRoute( builder: (context) =>
              SecondScreen(payloadPainText)
          ));
        }
    );

    receiveNotificationSubject.stream.listen(
        (ReceivedNotification receivedNotification){
          if(receivedNotification.source == NotificationSource.background){
            _showAlertDidReceiveNotification(receivedNotification.toString());
          } else {
            Navigator.push( context, MaterialPageRoute( builder: (context) =>
                SecondScreen(receivedNotification.toString())
            ));
          }
        }
    );

    didReceiveNotificationSubject.stream.listen(
      (String payload) {
        _showAlertDidReceiveNotification(payload);
    });

  }

  @override
  void dispose() {
    didReceiveNotificationSubject.close();
    receiveNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    MediaQueryData mediaQuery = MediaQuery.of(context);

    Widget remarkableDivisor = Divider(
        color: Colors.black,
        height: 5,
    );

    // TODO The methods below should be widgets in separate files. Just not worth doing it right now.
    Widget renderDivisor({String title}){
      return
        Padding(
          padding: EdgeInsets.only(top: 40, bottom: 20),
          child: title != null && title.isNotEmpty ?
            Row(
                children: <Widget>[
                  Expanded(
                      child: remarkableDivisor
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: mediaQuery.size.width / 2),
                      child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      )
                  ),
                  Expanded(
                      child: remarkableDivisor
                  ),
                ]
            ):
            remarkableDivisor
        );
    }

    Widget renderNote(String text){
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text('Note:',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14 ,
                      fontStyle: FontStyle.italic
                    )
                  )
                )
              ]
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(text,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 14
                    )
                  )
                )
              ]
            ),
          ],
        ),
      );
    }

    Widget renderSimpleButton(String label, {Color labelColor, Color backgroundColor, void Function() onPressed}){
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: RaisedButton(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14
              ),
            ),
          ),
          color: backgroundColor,
          textColor: labelColor,
          onPressed: () async {
            await onPressed();
          },
        )
      );
    }

    Widget renderCheckButton(String label, bool isSelected, {Color labelColor, Color backgroundColor, void Function(bool) onPressed}){
      return Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                    width: mediaQuery.size.width - 110 /* 30 - 60 - 20 */,
                    child: Text(label, style: TextStyle(fontSize: 16))
                ),
                Container(
                    width: 60,
                    child: Switch(
                      value: isSelected,
                      onChanged: onPressed,
                    )
                ),
              ]
          )
      );
    }

    _launchExternalURL(String url) async {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Local Notification Example App', style: TextStyle(fontSize: 20),),
        ),
        body: Container(
          child: Padding(
            padding: EdgeInsets.symmetric( horizontal: 15, vertical:8 ),
            child: ListView(
                children: <Widget>[

                  /* ******************************************************************** */
                  renderDivisor( title: 'Deprecated Notifications with plaintext payload' ),
                  renderNote('Action Buttons will not work on plain text due security issues.\nTopic discussed on GitHub bellow:'),
                  FlatButton(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Github link (opens externally)', textAlign: TextAlign.left, style: TextStyle( color: Colors.blue, decoration: TextDecoration.underline )),
                      ),
                      onPressed: () => _launchExternalURL('https://github.com/MaikuB/flutter_local_notifications/issues/378')
                  ),
                  renderSimpleButton(
                      'Show plain notification with plaintext payload (unsecure)',
                      onPressed: () => _showDeprecatedNotification(1)
                  ),
                  renderSimpleButton(
                      'Show plain notification with payload object',
                      onPressed: () => _showNotificationWithPayloadObject(1)
                  ),
                  renderSimpleButton(
                      'Show plain notification without payload object',
                      onPressed: () => _showNotificationWithoutPayloadObject(1)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(1)
                  ),

                  /* ******************************************************************** */
                  renderDivisor( title: 'Plain Notifications' ),
                  renderNote('Tap on a notification when it appears to trigger navigation'),
                  renderSimpleButton(
                      'Show plain notification with payload',
                      onPressed: () => _showNotificationWithPayloadObject(2)
                  ),
                  renderSimpleButton(
                    'Show plain notification that has no body with payload',
                    onPressed: () => _showNotificationWithNoBody(2)
                  ),
                  renderSimpleButton(
                    'Show plain notification with payload and update channel description [Android]',
                    onPressed: () => _showNotificationWithUpdatedChannelDescription(2)
                  ),
                  renderSimpleButton(
                    'Cancel notification',
                    backgroundColor: Colors.red,
                    labelColor: Colors.white,
                    onPressed: () => _cancelNotification(0)
                  ),

                  /* ******************************************************************** */
                  renderDivisor( title: 'Action Buttons' ),
                  renderNote('Action buttons can be just tap or requires to insert a input text before go.'),
                  renderSimpleButton(
                      'Show plain notification with payload and action buttons',
                      onPressed: () => _showNotificationWithButtons(2)
                  ),
                  renderSimpleButton(
                      'Show plain notification with payload, reply and action button',
                      onPressed: () => _showNotificationWithButtonsAndReply(2)
                  ),
                  renderSimpleButton(
                      'Show Big picture notification with payload, reply and action button',
                      onPressed: () => _showBigPictureNotificationActionButtonsAndReply(2)
                  ),
                  renderSimpleButton(
                      'Show Big text notification with payload, reply and action button',
                      onPressed: () => _showBigTextNotificationWithActionAndReply(2)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(0)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Vibration and Led Patterns'),
                  renderNote(
                      ' Android 8.0+, sounds and vibrations are associated with notification channels and can only be configured when they are first created on each installation.\n\n'+
                          'Showing/scheduling a notification will create a channel with the specified id if it doesn\'t exist already.\n\n'+
                          'If another notification specifies the same channel id but tries to specify another sound or vibration pattern then nothing occurs.'
                  ),
                  renderCheckButton(
                      'Delay notification for 5 seconds',
                      patternTestShouldSchedule,
                      onPressed: (value){
                        setState(() {
                          patternTestShouldSchedule = value;
                        });
                      }
                  ),
                  renderSimpleButton(
                      'Show plain notification with low vibration and led pattern',
                      onPressed: () => _showNotificationWithVibrationPattern(
                          3,
                          intensity: 0,
                          shouldSchedule: patternTestShouldSchedule,
                          title: 'Low intensity vibration',
                          body: 'Low intensity vibration and led',
                          payload: 'Low intensity payload'
                      )
                  ),
                  renderSimpleButton(
                      'Show plain notification with medium vibration and led pattern',
                      onPressed: () => _showNotificationWithVibrationPattern(
                          3,
                          intensity: 1,
                          shouldSchedule: patternTestShouldSchedule,
                          title: 'Medium intensity vibration',
                          body: 'Medium intensity vibration and led',
                          payload: 'Medium intensity payload'
                      )
                  ),
                  renderSimpleButton(
                      'Show plain notification with high vibration and led pattern',
                      onPressed: () => _showNotificationWithVibrationPattern(
                          3,
                          intensity: 2,
                          shouldSchedule: patternTestShouldSchedule,
                          title: 'High intensity vibration',
                          body: 'High intensity vibration and led',
                          payload: 'High intensity payload'
                      )
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(3)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Leds and Colors'),
                  renderNote('red colour, large icon and red LED are Android-specific'),
                  renderSimpleButton(
                    'Schedule notification to appear in 5 seconds, custom sound, red colour, large icon, red LED',
                    onPressed: () => _scheduleNotification(4)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(4)
                  ),

                  /* ******************************************************************** */
                  renderDivisor( title: 'Schedule Notifications' ),
                  renderSimpleButton(
                    'Repeat notification every minute',
                    onPressed: () => _repeatNotification(5),
                  ),
                  renderSimpleButton(
                    'Repeat notification every day at approximately 10:00:00 am',
                    onPressed: () => _showDailyAtTime(5)
                  ),
                  renderSimpleButton(
                    'Repeat notification weekly on Monday at approximately 10:00:00 am',
                    onPressed: () => _showWeeklyAtDayAndTime(5),
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(5)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Silenced Notifications'),
                  renderSimpleButton(
                    'Show notification with no sound',
                    onPressed: () => _showNotificationWithNoSound(6)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(6)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Big Picture Notifications'),
                  renderSimpleButton(
                    'Show big picture notification [Android]',
                    onPressed: () => _showBigPictureNotification(7)
                  ),
                  renderSimpleButton(
                    'Show big picture notification, hide large icon on expand [Android]',
                    onPressed: () => _showBigPictureNotificationHideExpandedLargeIcon(7)
                  ),
                  renderSimpleButton(
                      'Show big picture notification with Action Buttons [Android]',
                      onPressed: () => _showBigPictureNotificationActionButtons(7)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(7)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Html Layout Notifications'),
                  renderSimpleButton(
                    'Show big text notification [Android]',
                    onPressed: () => _showBigTextNotification(8)
                  ),
                  renderSimpleButton(
                    'Show inbox notification [Android]',
                    onPressed: () => _showInboxNotification(8),
                  ),
                  renderSimpleButton(
                    'Show messaging notification [Android]',
                    onPressed: () => _showMessagingNotification(8)
                  ),
                  renderSimpleButton(
                    'Show grouped notifications [Android]',
                    onPressed: () => _showGroupedNotifications(8)
                  ),
                  renderSimpleButton(
                    'Show ongoing notification [Android]',
                    onPressed: () => _showOngoingNotification(8)
                  ),
                  renderSimpleButton(
                    'Show notification with no badge, alert only once [Android]',
                    onPressed: () => _showNotificationWithNoBadge(8),
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(8)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(title: 'Progress Notifications'),
                  renderSimpleButton(
                    'Show progress notification - updates every second [Android]',
                    onPressed: () => _showProgressNotification(9)
                  ),
                  renderSimpleButton(
                    'Show indeterminate progress notification [Android]',
                    onPressed: () => _showIndeterminateProgressNotification(9)
                  ),
                  renderSimpleButton(
                      'Cancel notification',
                      backgroundColor: Colors.red,
                      labelColor: Colors.white,
                      onPressed: () => _cancelNotification(9)
                  ),

                  /* ******************************************************************** */
                  renderDivisor(),
                  renderSimpleButton(
                    'Check pending notifications',
                    onPressed: _checkPendingNotificationRequests
                  ),
                  renderSimpleButton(
                    'Cancel all notifications',
                    backgroundColor: Colors.red,
                    labelColor: Colors.white,
                    onPressed: _cancelAllNotifications
                  ),
                ],
            ),
          ),
        ),
      ),
    );
  }




  /* **********************************************************
  *
  * Show Notification Methods
  *
  ********************************************************** */


  Future<void> _showDeprecatedNotification(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker'
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x'
    );
  }

  Future<void> _showNotificationWithPayloadObject(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker'
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'plain title',
            body: 'plain body',
            payload: {
              'uuid' : 'uuid-test',
              'secret-code' : 'abcd'
            }
        )
    );
  }

  Future<void> _showNotificationWithoutPayloadObject(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker'
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'plain title',
            body: 'plain body'
        )
    );
  }

  Future<void> _showNotificationWithButtons(int id) async {

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker',
        color: Colors.blueAccent
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'plain title',
            body: 'plain body',
            actionButtons: [
              NotificationActionButton(
                  key: 'READED',
                  label: 'Mark as readed',
                  autoCancel: true
              ),
              NotificationActionButton(
                  key: 'REMEMBER',
                  label: 'Remember-me later',
                  autoCancel: false
              )
            ],
            payload: {
              'uuid' : 'uuid-test'
            }
        )
    );
  }

  Future<void> _showNotificationWithButtonsAndReply(int id) async {

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker',
        color: Colors.blueAccent
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'plain title',
            body: 'plain body',
            actionButtons: [
              NotificationActionButton(
                  key: 'REPLY',
                  label: 'Reply',
                  autoCancel: true,
                  requiresInput: true,
              ),
              NotificationActionButton(
                  key: 'ARCHIVE',
                  label: 'Archive',
                  autoCancel: true
              )
            ],
            payload: {
              'uuid' : 'uuid-test'
            }
        )
    );
  }

  Future<void> _showNotificationWithNoBody(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
          id: id,
          title: 'plain title',
          payload: {
            'uuid' : 'uuid-test'
          }
        )
    );
  }

  // Lights intensity should be the inverse of vibration intensity
  int getLedIntensity(int intensity){
    int response = vibrationPatterns[vibrationPatterns.length - 1 - intensity][1] * 2;
    return response;
  }

  Future<void> _showNotificationWithVibrationPattern(int id, {int intensity, bool shouldSchedule, String title, String body, String payload}) async {

    int ledIntensity = getLedIntensity(intensity);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'intensity_channel_'+intensity.toString(),
      'Vibration Patterns and Leds',
      'Test of changing intensity patterns for vibration and led',
      importance: Importance.Max, priority: Priority.High, ticker: 'ticker',
      vibrationPattern: vibrationPatterns[intensity ?? 0],
      enableLights: true,
      ledOffMs: ledIntensity,
      ledOnMs: ledIntensity,
      color: Colors.deepPurple,
      ledColor: Colors.deepPurple,
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    var notificationContent = NotificationContent(
        id: id,
        title: title ?? 'title',
        body: body ?? 'body',
        payload: {
        'simpleText': 'test payload'
        }
    );

    if(shouldSchedule){

      var scheduledNotificationDateTime = DateTime.now().add(Duration(seconds: 5));
      await flutterLocalNotificationsPlugin.showNotificationSchedule(
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        notificationContent
      );

    } else {

      await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        notificationContent
      );

    }
  }

  /// Schedules a notification that specifies a different icon, sound and vibration pattern
  Future<void> _scheduleNotification(int id) async {
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(seconds: 5));
    var vibrationPattern = Int64List(4);
    vibrationPattern[0] = 0;
    vibrationPattern[1] = 1000;
    vibrationPattern[2] = 5000;
    vibrationPattern[3] = 2000;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your other channel id',
        'your other channel name',
        'your other channel description',
        icon: 'secondary_icon',
        sound: 'slow_spring_board',
        largeIcon: 'sample_large_icon',
        largeIconBitmapSource: BitmapSource.Drawable,
        vibrationPattern: vibrationPattern,
        enableLights: true,
        color: const Color.fromARGB(255, 255, 0, 0),
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500);
    var iOSPlatformChannelSpecifics =
        IOSNotificationDetails(sound: "slow_spring_board.aiff");
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotificationSchedule(
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'scheduled title',
            body: 'scheduled body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showNotificationWithNoSound(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'silent channel id',
        'silent channel name',
        'silent channel description',
        playSound: false,
        styleInformation: DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
        IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Silenced title',
            body: 'Silenced body',
            payload: {
              'uuid' : 'uuid-test'
            }
        )
    );
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> _showBigPictureNotification(int id) async {
    var largeIconPath = await _downloadAndSaveImage(
        'http://via.placeholder.com/48x48', 'largeIcon');
    var bigPicturePath = await _downloadAndSaveImage(
        'http://via.placeholder.com/400x800', 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        contentTitle: 'overridden <b>big</b> content title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Big picture title',
            body: 'Big picture body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showBigPictureNotificationActionButtons(int id) async {
    var largeIconPath = await _downloadAndSaveImage(
        'http://via.placeholder.com/48x48', 'largeIcon');
    var bigPicturePath = await _downloadAndSaveImage(
        'http://via.placeholder.com/300x800', 'bigPictureAction');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        contentTitle: 'overridden <b>big</b> content title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation
    );
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);

    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'big text title',
            body: 'silent body',
            actionButtons: [
              NotificationActionButton(
                  key: 'READED',
                  label: 'Mark as readed',
                  autoCancel: true
              ),
              NotificationActionButton(
                  key: 'REMEMBER',
                  label: 'Remember-me later',
                  autoCancel: false
              )
            ],
            payload: {
              'uuid' : 'uuid-test'
            }
        )
    );
  }

  Future<void> _showBigPictureNotificationActionButtonsAndReply(int id) async {
    var largeIconPath = await _downloadAndSaveImage(
        'http://via.placeholder.com/48x48', 'largeIcon');
    var bigPicturePath = await _downloadAndSaveImage(
        'http://via.placeholder.com/300x800', 'bigPictureAction');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        contentTitle: 'overridden <b>big</b> content title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation
    );
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);

    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
          id: id,
          title: 'big text title',
          body: 'silent body',
          actionButtons: [
            NotificationActionButton(
                key: 'REPLY',
                label: 'Reply',
                autoCancel: true,
                requiresInput: true
            ),
            NotificationActionButton(
                key: 'REMEMBER',
                label: 'Remember-me later',
                autoCancel: true
            )
          ],
          payload: {
            'uuid' : 'uuid-test'
          }
        )
    );
  }

  Future<void> _showBigPictureNotificationHideExpandedLargeIcon(int id) async {
    var largeIconPath = await _downloadAndSaveImage(
        'http://via.placeholder.com/48x48', 'largeIcon');
    var bigPicturePath = await _downloadAndSaveImage(
        'http://via.placeholder.com/400x800', 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        bigPicturePath, BitmapSource.FilePath,
        hideExpandedLargeIcon: true,
        contentTitle: 'overridden <b>big</b> content title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        largeIcon: largeIconPath,
        largeIconBitmapSource: BitmapSource.FilePath,
        style: AndroidNotificationStyle.BigPicture,
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Big picture title',
            body: 'Big picture body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showBigTextNotification(int id) async {
    var bigTextStyleInformation = BigTextStyleInformation(
        'Lorem <i>ipsum dolor sit</i> amet, consectetur <b>adipiscing elit</b>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        htmlFormatBigText: true,
        contentTitle: 'overridden <b>big</b> content title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true,

    );
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        style: AndroidNotificationStyle.BigText,
        styleInformation: bigTextStyleInformation);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Big text title',
            body: 'Big text body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showBigTextNotificationWithActionAndReply(int id) async {
    var bigTextStyleInformation = BigTextStyleInformation(
      'Lorem <i>ipsum dolor sit</i> amet, consectetur <b>adipiscing elit</b>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      htmlFormatBigText: true,
      contentTitle: 'overridden <b>big</b> content title',
      htmlFormatContentTitle: true,
      summaryText: 'summary <i>text</i>',
      htmlFormatSummaryText: true,

    );
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        color: Colors.orange,
        style: AndroidNotificationStyle.BigText,
        styleInformation: bigTextStyleInformation);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Big text title',
            body: 'Big text body',
            actionButtons: [
              NotificationActionButton(
                  key: 'REPLY',
                  label: 'Reply',
                  autoCancel: true,
                  requiresInput: true
              ),
              NotificationActionButton(
                  key: 'REMEMBER',
                  label: 'Remember-me later',
                  autoCancel: true
              )
            ],
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showInboxNotification(int id) async {
    var lines = List<String>();
    lines.add('line <b>1</b>');
    lines.add('line <i>2</i>');
    var inboxStyleInformation = InboxStyleInformation(lines,
        htmlFormatLines: true,
        contentTitle: 'overridden <b>inbox</b> context title',
        htmlFormatContentTitle: true,
        summaryText: 'summary <i>text</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'inbox channel id', 'inboxchannel name', 'inbox channel description',
        style: AndroidNotificationStyle.Inbox,
        styleInformation: inboxStyleInformation);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'Inbox title',
            body: 'Inbox body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showMessagingNotification(int id) async {
    // use a platform channel to resolve an Android drawable resource to a URI.
    // This is NOT part of the notifications plugin. Calls made over this channel is handled by the app
    String imageUri = await platform.invokeMethod('drawableToUri', 'food');
    var messages = List<Message>();
    // First two person objects will use icons that part of the Android app's drawable resources
    var me = Person(
        name: 'Me',
        key: '1',
        uri: 'tel:1234567890',
        icon: 'me',
        iconSource: IconSource.Drawable);
    var coworker = Person(
        name: 'Coworker',
        key: '2',
        uri: 'tel:9876543210',
        icon: 'coworker',
        iconSource: IconSource.Drawable);
    // download the icon that would be use for the lunch bot person
    var largeIconPath = await _downloadAndSaveImage(
        'http://via.placeholder.com/48x48', 'largeIcon');
    // this person object will use an icon that was downloaded
    var lunchBot = Person(
        name: 'Lunch bot',
        key: 'bot',
        bot: true,
        icon: largeIconPath,
        iconSource: IconSource.FilePath);
    messages.add(Message('Hi', DateTime.now(), null));
    messages.add(Message(
        'What\'s up?', DateTime.now().add(Duration(minutes: 5)), coworker));
    messages.add(Message(
        'Lunch?', DateTime.now().add(Duration(minutes: 10)), null,
        dataMimeType: 'image/png', dataUri: imageUri));
    messages.add(Message('What kind of food would you prefer?',
        DateTime.now().add(Duration(minutes: 10)), lunchBot));
    var messagingStyle = MessagingStyleInformation(me,
        groupConversation: true,
        conversationTitle: 'Team lunch',
        htmlFormatContent: true,
        htmlFormatTitle: true,
        messages: messages);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'message channel id',
        'message channel name',
        'message channel description',
        style: AndroidNotificationStyle.Messaging,
        styleInformation: messagingStyle);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'message title', 'message body', platformChannelSpecifics);

    // wait 10 seconds and add another message to simulate another response
    await Future.delayed(Duration(seconds: 10), () async {
      messages.add(
          Message('Thai', DateTime.now().add(Duration(minutes: 11)), null));
      await flutterLocalNotificationsPlugin.showNotification(
          platformChannelSpecifics,
          NotificationContent(
              id: id,
              title: 'message title',
              body: 'message body',
              payload: {
                'uuid' : 'uuid-test'
              }
          ));
    });
  }

  Future<void> _showGroupedNotifications(int id) async {
    var groupKey = 'com.android.example.WORK_EMAIL';
    var groupChannelId = 'grouped channel id';
    var groupChannelName = 'grouped channel name';
    var groupChannelDescription = 'grouped channel description';
    // example based on https://developer.android.com/training/notify-user/group.html
    var firstNotificationAndroidSpecifics = AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        importance: Importance.Max,
        priority: Priority.High,
        groupKey: groupKey);
    var firstNotificationPlatformSpecifics =
        NotificationDetails(firstNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.show(1, 'Alex Faarborg',
        'You will not believe...', firstNotificationPlatformSpecifics);
    var secondNotificationAndroidSpecifics = AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        importance: Importance.Max,
        priority: Priority.High,
        groupKey: groupKey);
    var secondNotificationPlatformSpecifics =
        NotificationDetails(secondNotificationAndroidSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        secondNotificationPlatformSpecifics,
        NotificationContent(
            id: 2,
            title: 'Jeff Chang',
            body: 'Please join us to celebrate the...'
        ));

    // create the summary notification to support older devices that pre-date Android 7.0 (API level 24).
    // this is required is regardless of which versions of Android your application is going to support
    var lines = List<String>();
    lines.add('Alex Faarborg  Check this out');
    lines.add('Jeff Chang    Launch Party');
    var inboxStyleInformation = InboxStyleInformation(lines,
        contentTitle: '2 messages', summaryText: 'janedoe@example.com');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        style: AndroidNotificationStyle.Inbox,
        styleInformation: inboxStyleInformation,
        groupKey: groupKey,
        setAsGroupSummary: true);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: 3,
            title: 'Attention',
            body: 'Two messages'
        ));
  }

  Future<void> _checkPendingNotificationRequests() async {
    var pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (var pendingNotificationRequest in pendingNotificationRequests) {
      debugPrint(
          'pending notification: [id: ${pendingNotificationRequest.id}, title: ${pendingNotificationRequest.title}, body: ${pendingNotificationRequest.body}, payload: ${pendingNotificationRequest.payload}]');
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(
              '${pendingNotificationRequests.length} pending notification requests'),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _showOngoingNotification(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max,
        priority: Priority.High,
        ongoing: true,
        autoCancel: false);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'ongoing notification title',
            body: 'ongoing notification body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _repeatNotification(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'repeating channel id',
        'repeating channel name',
        'repeating description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotificationPeriodically(
        RepeatInterval.EveryMinute,
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'repeating title',
            body: 'repeating body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showDailyAtTime(int id) async {
    var time = Time(10, 0, 0);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'repeatDailyAtTime channel id',
        'repeatDailyAtTime channel name',
        'repeatDailyAtTime description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotificationDailyAtTime(
        time,
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'show daily title',
            body: 'Daily notification shown at approximately ${_toTwoDigitString(time.hour)}:${_toTwoDigitString(time.minute)}:${_toTwoDigitString(time.second)}',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showWeeklyAtDayAndTime(int id) async {
    var time = Time(10, 0, 0);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'show weekly channel id',
        'show weekly channel name',
        'show weekly description');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotificationWeeklyAtDayAndTime(
        Day.Monday,
        time,
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'show weekly title',
            body: 'Weekly notification shown on Monday at approximately ${_toTwoDigitString(time.hour)}:${_toTwoDigitString(time.minute)}:${_toTwoDigitString(time.second)}',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showNotificationWithNoBadge(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'no badge channel', 'no badge name', 'no badge description',
        channelShowBadge: false,
        importance: Importance.Max,
        priority: Priority.High,
        onlyAlertOnce: true);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
            id: id,
            title: 'no badge title',
            body: 'no badge body',
            payload: {
              'uuid' : 'uuid-test'
            }
        ));
  }

  Future<void> _showProgressNotification(int id) async {
    var maxProgress = 5;
    for (var i = 0; i <= maxProgress; i++) {
      await Future.delayed(Duration(seconds: 1), () async {
        var androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'progress channel',
            'progress channel',
            'progress channel description',
            channelShowBadge: false,
            importance: Importance.Max,
            priority: Priority.High,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: maxProgress,
            progress: i);
        var iOSPlatformChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
            androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
        await flutterLocalNotificationsPlugin.showNotification(
            platformChannelSpecifics,
            NotificationContent(
                id: id,
                title: 'progress notification title',
                body: 'progress notification body',
                payload: {
                  'file' : 'filename.txt',
                  'path' : '-rmdir c://ruwindows/system32/huehuehue'
                }
            ));
      });
    }
  }

  Future<void> _showIndeterminateProgressNotification(int id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'indeterminate progress channel',
        'indeterminate progress channel',
        'indeterminate progress channel description',
        channelShowBadge: false,
        importance: Importance.Max,
        priority: Priority.High,
        onlyAlertOnce: true,
        showProgress: true,
        indeterminate: true);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showNotification(
        platformChannelSpecifics,
        NotificationContent(
          id: id,
          title: 'indeterminate progress notification title',
          body: 'indeterminate progress notification body',
          payload: {
            'file' : 'filename.txt',
            'path' : '-rmdir c://ruwindows/system32/huehuehue'
          }
        )
    );
  }

  Future<void> _showNotificationWithUpdatedChannelDescription(int id) async {

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your updated channel description',
        importance: Importance.Max,
        priority: Priority.High,
        channelAction: AndroidNotificationChannelAction.Update);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();

    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.showNotification(
      platformChannelSpecifics,
      NotificationContent(
        id: id,
        title: 'updated notification channel',
        body: 'check settings to see updated channel description',
        payload: {
          'uuid': '0123456789'
        }
      )
    );
  }

  String _toTwoDigitString(int value) {
    return value.toString().padLeft(2, '0');
  }

}

class SecondScreen extends StatelessWidget {

  String results;

  SecondScreen(results){
    this.results = results ?? '';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen with Payload', style: TextStyle(fontSize: 16)),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: ListView(
              children: <Widget>[
                Text('Payload', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),),
                SizedBox(height: 20 ),
                Text(results,  style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                RaisedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Go back!', style: TextStyle(fontSize: 16),)
                ),
              ],
            )
        ),
      ),
    );
  }
}
