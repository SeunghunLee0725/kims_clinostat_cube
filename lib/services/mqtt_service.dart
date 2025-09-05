import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  static const String broker = 'd29c4d0bbdb946beae4aafdfc0e6e342.s1.eu.hivemq.cloud';
  static const int port = 8884; // WebSocket port for HiveMQ Cloud
  static const String username = 's25007cmd';
  static const String password = 's25007Pine';
  static const String statusTopic = 's25007/board1/status';
  static const String commandTopic = 's25007/board1/cmd';
  
  late MqttClient client; // Base client type
  final StreamController<String> _statusStreamController = StreamController<String>.broadcast();
  final StreamController<bool> _connectionStreamController = StreamController<bool>.broadcast();
  
  Stream<String> get statusStream => _statusStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  MqttService() {
    _setupClient();
  }
  
  void _setupClient() {
    // Generate unique client ID
    final clientId = kIsWeb 
        ? 'flutter_web_${DateTime.now().millisecondsSinceEpoch}' 
        : 'flutter_mobile_${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      // Web platform - use MqttBrowserClient
      final browserClient = MqttBrowserClient('wss://$broker/mqtt', clientId);
      browserClient.port = port;
      browserClient.logging(on: true);
      browserClient.keepAlivePeriod = 60;
      browserClient.connectTimeoutPeriod = 10000;
      browserClient.autoReconnect = false;
      browserClient.setProtocolV311();
      client = browserClient;
    } else {
      // Mobile/Desktop platforms - use MqttServerClient
      final serverClient = MqttServerClient.withPort(broker, clientId, port);
      serverClient.logging(on: true);
      serverClient.keepAlivePeriod = 60;
      serverClient.connectTimeoutPeriod = 10000;
      serverClient.autoReconnect = false;
      serverClient.secure = true; // Use secure connection
      serverClient.setProtocolV311();
      serverClient.useWebSocket = true; // Use WebSocket for mobile
      client = serverClient;
    }
    
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.onAutoReconnect = _onAutoReconnect;
    client.onAutoReconnected = _onAutoReconnected;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean();
    
    client.connectionMessage = connMessage;
  }
  
  Future<bool> connect() async {
    try {
      print('Connecting to MQTT broker...');
      print('Host: $broker');
      print('Port: $port');
      print('Username: $username');
      print('Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}');
      print('Using ${kIsWeb ? "WebSocket" : "Secure WebSocket"} connection');
      
      await client.connect(username, password);
      return true;
    } catch (e) {
      print('Connection error: $e');
      print('Stack trace: ${e.toString()}');
      client.disconnect();
      return false;
    }
  }
  
  void _onConnected() {
    print('Connected to MQTT broker');
    _isConnected = true;
    _connectionStreamController.add(true);
    _subscribeToStatus();
  }
  
  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    _isConnected = false;
    _connectionStreamController.add(false);
  }
  
  void _onAutoReconnect() {
    print('Auto-reconnecting...');
  }
  
  void _onAutoReconnected() {
    print('Auto-reconnected');
    _isConnected = true;
    _connectionStreamController.add(true);
    _subscribeToStatus();
  }
  
  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
  
  void _subscribeToStatus() {
    // Subscribe to specific status topic
    client.subscribe(statusTopic, MqttQos.atLeastOnce);
    // Also subscribe to all s25007 topics to debug
    client.subscribe('s25007/#', MqttQos.atLeastOnce);
    
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      print('Received ${messages.length} message(s)');
      for (var message in messages) {
        print('Message topic: ${message.topic}');
        final MqttPublishMessage publishMessage = message.payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(publishMessage.payload.message);
        print('Message payload: $payload');
        
        if (message.topic == statusTopic) {
          print('Status message received: $payload');
          _statusStreamController.add(payload);
        }
      }
    });
  }
  
  void publishCommand(String command) {
    if (!_isConnected) {
      print('Not connected, cannot send command');
      return;
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);
    
    client.publishMessage(commandTopic, MqttQos.atLeastOnce, builder.payload!);
    print('Command sent: $command');
  }
  
  void disconnect() {
    client.disconnect();
  }
  
  void dispose() {
    _statusStreamController.close();
    _connectionStreamController.close();
    disconnect();
  }
}