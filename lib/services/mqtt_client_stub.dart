import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String broker, String clientId, int port) {
  throw UnsupportedError('Cannot create MQTT client without dart:io or dart:html');
}