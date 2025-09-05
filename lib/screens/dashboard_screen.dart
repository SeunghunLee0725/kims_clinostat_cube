import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../services/mqtt_service.dart';
import '../services/supabase_service.dart';
import '../services/data_collector_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DataCollectorService _dataCollector;
  late SupabaseService _supabaseService;
  final List<String> _mqttMessages = [];
  
  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService();
    _initializeServices();
  }
  
  void _initializeServices() {
    final mqttProvider = context.read<MqttProvider>();
    final mqttService = mqttProvider.mqttService;
    
    _dataCollector = DataCollectorService(
      mqttService: mqttService,
      supabaseService: _supabaseService,
    );
    
    _dataCollector.startPeriodicCollection(
      interval: const Duration(seconds: 30),
    );
    
    // Listen to MQTT status updates
    mqttProvider.addListener(() {
      if (mqttProvider.statusData.isNotEmpty && mounted) {
        setState(() {
          final timestamp = DateTime.now().toLocal().toString().substring(0, 19);
          _mqttMessages.insert(0, '$timestamp - ${mqttProvider.statusMessage}');
          if (_mqttMessages.length > 20) {
            _mqttMessages.removeLast();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _dataCollector.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final mqttProvider = context.watch<MqttProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Dashboard - Web'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(isWideScreen ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: mqttProvider.isConnected ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mqttProvider.isConnected ? 'Connected' : 'Disconnected',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    if (mqttProvider.isConnected && mqttProvider.statusData.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusRow('IP', mqttProvider.statusData['ip'] ?? 'N/A'),
                            _buildStatusRow('Wi-Fi 신호', '${mqttProvider.statusData['rssi'] ?? 'N/A'} dBm'),
                            _buildStatusRow('모터 상태', mqttProvider.statusData['run'] ?? 'N/A'),
                            _buildStatusRow('동작 모드', mqttProvider.statusData['mode'] ?? 'N/A'),
                            _buildStatusRow('현재 속도', '${mqttProvider.statusData['current_spm'] ?? 'N/A'} SPM'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Real-time Data',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                'Topic: s25007/board1/status',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all),
                            onPressed: () {
                              setState(() {
                                _mqttMessages.clear();
                              });
                            },
                            tooltip: 'Clear messages',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _mqttMessages.isEmpty
                              ? const Center(
                                  child: Text('Waiting for MQTT messages...'),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _mqttMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = _mqttMessages[index];
                                    final parts = message.split(' - ');
                                    final timestamp = parts[0];
                                    final content = parts.length > 1 ? parts[1] : '';
                                    
                                    // Parse status data
                                    Map<String, String> statusData = {};
                                    if (content.isNotEmpty) {
                                      final pairs = content.split(',');
                                      for (final pair in pairs) {
                                        final keyValue = pair.split('=');
                                        if (keyValue.length == 2) {
                                          statusData[keyValue[0].trim()] = keyValue[1].trim();
                                        }
                                      }
                                    }
                                    
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  timestamp,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (statusData.isNotEmpty) ...[
                                              Wrap(
                                                spacing: 16,
                                                runSpacing: 4,
                                                children: statusData.entries.map((entry) => 
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '${entry.key}: ',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        entry.value,
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ).toList(),
                                              ),
                                            ] else
                                              Text(
                                                content,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}