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
      await _supabaseService.saveMqttData(
        topic: MqttService.statusTopic,
        payload: payload,
        timestamp: DateTime.now(),
      );
      
      print('Status data saved to Supabase: $payload');
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