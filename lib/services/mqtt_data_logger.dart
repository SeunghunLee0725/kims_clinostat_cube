import 'dart:async';
import 'supabase_service.dart';

class MqttDataLogger {
  final SupabaseService _supabaseService = SupabaseService();
  Timer? _loggingTimer;
  int? _lastCurrentSpm;
  String _deviceId = 's25007/board1';
  DateTime? _lastTimestamp;
  
  // Start logging MQTT data every 10 seconds
  void startLogging() {
    _loggingTimer?.cancel();
    _loggingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_lastCurrentSpm != null) {
        _saveDataToSupabase();
      }
    });
  }
  
  // Update the latest received data - parse current_spm from payload
  void updateLatestData(String topic, String payload) {
    // Extract device_id from topic
    if (topic.contains('s25007/')) {
      _deviceId = topic.split('/').take(2).join('/');
    }
    
    // Parse current_spm from payload
    _lastCurrentSpm = _parseCurrentSpm(payload);
    _lastTimestamp = DateTime.now();
  }
  
  // Parse current_spm value from MQTT payload
  int? _parseCurrentSpm(String payload) {
    try {
      // Payload format: "ip=192.168.50.2,rssi=-55,run=on,mode=RUN,current_spm=100,..."
      final pairs = payload.split(',');
      for (final pair in pairs) {
        final parts = pair.split('=');
        if (parts.length == 2 && parts[0].trim() == 'current_spm') {
          return int.tryParse(parts[1].trim());
        }
      }
    } catch (e) {
      print('Error parsing current_spm: $e');
    }
    return null;
  }
  
  // Save data to Supabase
  Future<void> _saveDataToSupabase() async {
    if (_lastCurrentSpm == null || _lastTimestamp == null) {
      return;
    }
    
    await _supabaseService.saveSpeedData(
      deviceId: _deviceId,
      currentSpm: _lastCurrentSpm!,
      timestamp: _lastTimestamp!,
    );
    
    print('Logged speed data to Supabase: $_deviceId - current_spm: $_lastCurrentSpm at $_lastTimestamp');
  }
  
  // Stop logging
  void stopLogging() {
    _loggingTimer?.cancel();
    _loggingTimer = null;
  }
  
  // Force save current data immediately
  Future<void> saveNow() async {
    await _saveDataToSupabase();
  }
  
  void dispose() {
    stopLogging();
  }
}