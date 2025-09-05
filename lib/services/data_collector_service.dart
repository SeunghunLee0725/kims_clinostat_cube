import 'dart:async';
import 'mqtt_service.dart';
import 'supabase_service.dart';

class DataCollectorService {
  final MqttService _mqttService;
  final SupabaseService _supabaseService;
  
  Timer? _collectionTimer;
  StreamSubscription<String>? _statusSubscription;
  bool _shouldSaveNextStatus = false;
  
  DataCollectorService({
    required MqttService mqttService,
    required SupabaseService supabaseService,
  })  : _mqttService = mqttService,
        _supabaseService = supabaseService;
  
  void startPeriodicCollection({
    Duration interval = const Duration(seconds: 30),
  }) {
    print('DataCollectorService: Starting periodic collection with interval: $interval');
    _collectionTimer?.cancel();
    
    _collectionTimer = Timer.periodic(interval, (timer) {
      print('DataCollectorService: Timer triggered - requesting status update');
      _shouldSaveNextStatus = true;  // Mark that we want to save the next status
      _requestStatusUpdate();
    });
    
    _subscribeToStatusUpdates();
    
    // Initial request
    print('DataCollectorService: Sending initial status request');
    _shouldSaveNextStatus = true;  // Mark for initial save
    _requestStatusUpdate();
  }
  
  void _requestStatusUpdate() {
    if (_mqttService.isConnected) {
      print('DataCollectorService: MQTT connected, publishing GET_STATUS command');
      _mqttService.publishCommand('GET_STATUS');
    } else {
      print('DataCollectorService: MQTT not connected, skipping status request');
    }
  }
  
  void _subscribeToStatusUpdates() {
    _statusSubscription?.cancel();
    
    print('DataCollectorService: Subscribing to MQTT status updates...');
    _statusSubscription = _mqttService.statusStream.listen((payload) {
      print('DataCollectorService: Status stream received data');
      _handleStatusUpdate(payload);
    }, onError: (error) {
      print('DataCollectorService: Status stream error: $error');
    }, onDone: () {
      print('DataCollectorService: Status stream closed');
    });
    print('DataCollectorService: Subscription created');
  }
  
  Future<void> _handleStatusUpdate(String payload) async {
    try {
      print('DataCollector received status update: $payload');
      
      // Only save if this update was requested by our timer
      if (!_shouldSaveNextStatus) {
        print('DataCollector: Ignoring automatic status update (not requested by timer)');
        return;
      }
      
      // Reset the flag
      _shouldSaveNextStatus = false;
      
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
        print('Attempting to save speed data: current_spm=$currentSpm');
        await _supabaseService.saveSpeedData(
          deviceId: 's25007/board1',
          currentSpm: currentSpm,
          timestamp: DateTime.now(),
        );
        print('Speed data saved successfully to Supabase: current_spm=$currentSpm');
      } else {
        print('No current_spm found in payload: $payload');
      }
    } catch (e) {
      print('Error handling status update: $e');
      print('Error details: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      
      // Don't rethrow - continue collecting data even if save fails
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