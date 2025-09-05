import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  Future<void> saveMqttData({
    required String topic,
    required String payload,
    required DateTime timestamp,
  }) async {
    try {
      await client.from('mqtt_data').insert({
        'topic': topic,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error saving to Supabase: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getRecentData({
    int limit = 100,
  }) async {
    try {
      final response = await client
          .from('mqtt_data')
          .select()
          .order('timestamp', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching from Supabase: $e');
      return [];
    }
  }
  
  Stream<List<Map<String, dynamic>>> subscribeToRealtimeData() {
    return client
        .from('mqtt_data')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .limit(10);
  }
  
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