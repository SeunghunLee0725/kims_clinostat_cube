import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String broker, String clientId, int port) {
  final client = MqttBrowserClient('wss://$broker/mqtt', clientId);
  client.port = port;
  client.logging(on: true);
  client.keepAlivePeriod = 60;
  client.connectTimeoutPeriod = 10000;
  client.autoReconnect = false;
  client.setProtocolV311();
  return client;
}