import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Save speed data to Supabase
  Future<void> saveSpeedData({
    required String deviceId,
    required int currentSpm,
    required DateTime timestamp,
  }) async {
    try {
      print('SupabaseService.saveSpeedData called with:');
      print('  deviceId: $deviceId');
      print('  currentSpm: $currentSpm');
      print('  timestamp: ${timestamp.toIso8601String()}');
      
      // Check if Supabase is initialized
      print('Supabase URL: ${Environment.supabaseUrl}');
      print('Supabase client initialized: ${Supabase.instance.client != null}');
      
      final supabaseClient = Supabase.instance.client;
      print('About to insert data to mqtt_data table...');
      
      final result = await supabaseClient.from('mqtt_data').insert({
        'device_id': deviceId,
        'current_spm': currentSpm,
        'timestamp': timestamp.toIso8601String(),
      }).select();
      
      print('Supabase insert successful!');
      print('Supabase insert result: $result');
    } catch (e) {
      print('ERROR saving speed data to Supabase: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      // Check if it's a PostgrestException
      if (e.toString().contains('PostgrestException')) {
        print('Database error - check if table exists and has correct schema');
      }
      
      // Check for CORS or network errors
      if (e.toString().contains('XMLHttpRequest') || 
          e.toString().contains('CORS') ||
          e.toString().contains('Failed to fetch')) {
        print('CORS or Network error detected');
        print('Make sure GitHub Pages URL is added to Supabase allowed URLs');
      }
      
      // Re-throw to see full stack trace in production
      rethrow;
    }
  }
  
  // Get last hour speed data
  Future<List<Map<String, dynamic>>> getLastHourSpeedData({
    required String deviceId,
  }) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      final response = await client
          .from('mqtt_data')
          .select('current_spm, timestamp')
          .eq('device_id', deviceId)
          .gte('timestamp', oneHourAgo.toIso8601String())
          .lte('timestamp', now.toIso8601String())
          .order('timestamp', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching last hour speed data: $e');
      return [];
    }
  }
  
  // Get last 24 hours speed data
  Future<List<Map<String, dynamic>>> getLast24HoursSpeedData({
    required String deviceId,
  }) async {
    try {
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
      
      final response = await client
          .from('mqtt_data')
          .select('current_spm, timestamp')
          .eq('device_id', deviceId)
          .gte('timestamp', twentyFourHoursAgo.toIso8601String())
          .lte('timestamp', now.toIso8601String())
          .order('timestamp', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching last 24 hours speed data: $e');
      return [];
    }
  }
  
  // Get speed data by time range
  Future<List<Map<String, dynamic>>> getSpeedDataByTimeRange({
    required DateTime startTime,
    required DateTime endTime,
    required String deviceId,
  }) async {
    try {
      final response = await client
          .from('mqtt_data')
          .select('current_spm, timestamp')
          .eq('device_id', deviceId)
          .gte('timestamp', startTime.toIso8601String())
          .lte('timestamp', endTime.toIso8601String())
          .order('timestamp', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching speed data by time range: $e');
      return [];
    }
  }
  
  // Get speed statistics (min, max, count)
  Future<Map<String, int>> getSpeedStats({
    required DateTime startTime,
    required DateTime endTime,
    required String deviceId,
  }) async {
    try {
      final response = await client
          .from('mqtt_data')
          .select('current_spm')
          .eq('device_id', deviceId)
          .gte('timestamp', startTime.toIso8601String())
          .lte('timestamp', endTime.toIso8601String());
      
      final data = List<Map<String, dynamic>>.from(response);
      
      if (data.isEmpty) {
        return {'min': 0, 'max': 0, 'count': 0};
      }
      
      int min = data.first['current_spm'];
      int max = data.first['current_spm'];
      
      for (final item in data) {
        final speed = item['current_spm'] as int;
        if (speed < min) min = speed;
        if (speed > max) max = speed;
      }
      
      return {
        'min': min,
        'max': max,
        'count': data.length,
      };
    } catch (e) {
      print('Error fetching speed stats: $e');
      return {'min': 0, 'max': 0, 'count': 0};
    }
  }
  
  // Get average speed
  Future<double> getAverageSpeed({
    required DateTime startTime,
    required DateTime endTime,
    required String deviceId,
  }) async {
    try {
      final response = await client
          .from('mqtt_data')
          .select('current_spm')
          .eq('device_id', deviceId)
          .gte('timestamp', startTime.toIso8601String())
          .lte('timestamp', endTime.toIso8601String());
      
      final data = List<Map<String, dynamic>>.from(response);
      
      if (data.isEmpty) return 0.0;
      
      int sum = 0;
      for (final item in data) {
        sum += item['current_spm'] as int;
      }
      
      return sum / data.length;
    } catch (e) {
      print('Error fetching average speed: $e');
      return 0.0;
    }
  }
  
  // Get recent speed data
  Future<List<Map<String, dynamic>>> getRecentSpeedData({
    required String deviceId,
    int limit = 100,
  }) async {
    try {
      final response = await client
          .from('mqtt_data')
          .select('current_spm, timestamp, device_id')
          .eq('device_id', deviceId)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching recent speed data: $e');
      return [];
    }
  }
  
  // Subscribe to realtime speed updates
  Stream<List<Map<String, dynamic>>> subscribeToRealtimeSpeedData(String deviceId) {
    return client
        .from('mqtt_data')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('timestamp', ascending: false)
        .limit(10);
  }
  
  // Save command
  Future<void> saveCommand({
    required String command,
    required String source,
    required DateTime timestamp,
  }) async {
    try {
      await client.from('commands').insert({
        'command': command,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
        'status': 'sent',
      });
    } catch (e) {
      print('Error saving command to Supabase: $e');
    }
  }
}