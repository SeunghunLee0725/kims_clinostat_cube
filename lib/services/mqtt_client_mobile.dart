import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String broker, String clientId, int port) {
  final client = MqttServerClient.withPort(broker, clientId, port);
  client.logging(on: true);
  client.keepAlivePeriod = 60;
  client.connectTimeoutPeriod = 10000;
  client.autoReconnect = false;
  client.secure = true;
  client.setProtocolV311();
  client.useWebSocket = true;
  return client;
}