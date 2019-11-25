import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'enums.dart';
import 'styles/style_information.dart';
import 'styles/default_style_information.dart';

/// Configures the Action Button
class NotificationActionDetails {

  /// The button label
  String label;

  /// Defines the notification style
  AndroidNotificationStyle style;

  /// Contains extra information for the specified notification [style]
  StyleInformation styleInformation;

  /// Specifies if the notification should automatically dismissed upon tapping on it
  bool autoCancel;

  /// Sets the color
  Color color;

  NotificationActionDetails(
      this.label,
      {
        this.style = AndroidNotificationStyle.Default,
        this.styleInformation,
        this.autoCancel = true,
        this.color,
      }
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'style': style.index,
      'styleInformation': styleInformation == null
          ? DefaultStyleInformation(false, false).toMap()
          : styleInformation.toMap(),
      'autoCancel': autoCancel,
      'colorAlpha': color?.alpha,
      'colorRed': color?.red,
      'colorGreen': color?.green,
      'colorBlue': color?.blue,
    };
  }
}
