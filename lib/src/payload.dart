
import 'package:meta/meta.dart';

class PayloadException implements Exception {
  String cause;
  PayloadException(this.cause);
}

abstract class Payload {

  // optimizes future cast
  Type type;
  String actionButtonPressed;

  @mustCallSuper
  Payload(){
    type = runtimeType;
  }

  @mustCallSuper
  Map<String, String> toMap() => ({ 'type': runtimeType.toString() });

  Payload fromMap(Map<String, dynamic> receivedPayload){
    this.actionButtonPressed = receivedPayload['action_key'];
    return this;
  }
}

class PlainTextPayload extends Payload {

  String plainText = '';

  PlainTextPayload({this.plainText});

  @override
  PlainTextPayload fromMap(Map<String, dynamic> receivedPayload) {
    super.fromMap(receivedPayload);

    plainText = receivedPayload['payload']['plainText'];

    return this;
  }

  @override
  Map<String, String> toMap() {
    Map<String, String> payload = super.toMap();

    payload['plainText'] = plainText ?? '';

    return payload;
  }

  @override
  String toString() {
    return (actionButtonPressed != null && actionButtonPressed.isNotEmpty ? actionButtonPressed + ': '  : '' ) +
        plainText ?? '"Empty value"';
  }

}