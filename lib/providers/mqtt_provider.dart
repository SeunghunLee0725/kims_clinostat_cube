import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';

class MqttProvider extends ChangeNotifier {
  final MqttService _mqttService = MqttService();
  
  bool _isConnected = false;
  String _statusMessage = '상태 정보 대기중...';
  Map<String, String> _statusData = {};
  
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  Map<String, String> get statusData => _statusData;
  
  MqttProvider() {
    _initializeStreams();
  }
  
  void _initializeStreams() {
    _mqttService.connectionStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });
    
    _mqttService.statusStream.listen((status) {
      _statusMessage = status;
      _parseStatus(status);
      notifyListeners();
    });
  }
  
  void _parseStatus(String status) {
    _statusData.clear();
    final pairs = status.split(',');
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        _statusData[parts[0].trim()] = parts[1].trim();
      }
    }
  }
  
  Future<void> connect() async {
    final connected = await _mqttService.connect();
    if (connected) {
      _isConnected = true;
      notifyListeners();
    }
  }
  
  void disconnect() {
    _mqttService.disconnect();
    _isConnected = false;
    _statusMessage = '상태 정보 대기중...';
    _statusData.clear();
    notifyListeners();
  }
  
  void sendCommand(String command) {
    _mqttService.publishCommand(command);
  }
  
  // 기본 명령어
  void startMotor() => sendCommand('start');
  void stopMotor() => sendCommand('stop');
  void oneStep() => sendCommand('once');
  void ledOn() => sendCommand('led:on');
  void ledOff() => sendCommand('led:off');
  
  // 설정 명령어
  void setSpm(int value) {
    if (value >= 1 && value <= 2400) {
      sendCommand('spm:$value');
    }
  }
  
  void manualStep(int value) {
    sendCommand('manualstep:$value');
  }
  
  void setSpinSteps(int value) {
    sendCommand('spinsteps:$value');
  }
  
  void setSpinSpm(int value) {
    if (value >= 1 && value <= 2400) {
      sendCommand('spinspm:$value');
    }
  }
  
  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }
}