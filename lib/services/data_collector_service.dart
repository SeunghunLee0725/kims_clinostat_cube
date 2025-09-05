import 'dart:async';
import 'mqtt_service.dart';
import 'supabase_service.dart';

class DataCollectorService {
  final MqttService _mqttService;
  final SupabaseService _supabaseService;
  
  Timer? _collectionTimer;
  StreamSubscription<String>? _statusSubscription;
  
  DataCollectorService({
    required MqttService mqttService,
    required SupabaseService supabaseService,
  })  : _mqttService = mqttService,
        _supabaseService = supabaseService;
  
  void startPeriodicCollection({
    Duration interval = const Duration(seconds: 30),
  }) {
    _collectionTimer?.cancel();
    
    _collectionTimer = Timer.periodic(interval, (timer) {
      _requestStatusUpdate();
    });
    
    _subscribeToStatusUpdates();
    
    _requestStatusUpdate();
  }
  
  void _requestStatusUpdate() {
    if (_mqttService.isConnected) {
      _mqttService.publishCommand('GET_STATUS');
    }
  }
  
  void _subscribeToStatusUpdates() {
    _statusSubscription?.cancel();
    
    _statusSubscription = _mqttService.statusStream.listen((payload) {
      _handleStatusUpdate(payload);
    });
  }
  
  Future<void> _handleStatusUpdate(String payload) async {
    try {
      // Extract current_spm from the status data
      final statusPairs = payload.split(',');
      int? currentSpm;
      
      for (final pair in statusPairs) {
        final keyValue = pair.trim().split('=');
        if (keyValue.length == 2 && keyValue[0] == 'current_spm') {
          currentSpm = int.tryParse(keyValue[1]);
          break;
        }
      }
      
      // Only save if we have current_spm data
      if (currentSpm != null) {
        await _supabaseService.saveSpeedData(
          deviceId: 's25007/board1',
          currentSpm: currentSpm,
          timestamp: DateTime.now(),
        );
        print('Speed data saved to Supabase: current_spm=$currentSpm');
      }
    } catch (e) {
      print('Error handling status update: $e');
    }
  }
  
  void stopCollection() {
    _collectionTimer?.cancel();
    _statusSubscription?.cancel();
  }
  
  void dispose() {
    stopCollection();
  }
}