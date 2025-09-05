import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _spmController = TextEditingController();
  final TextEditingController _manualStepController = TextEditingController();
  final TextEditingController _customCommandController = TextEditingController();
  final TextEditingController _spinstepsController = TextEditingController();
  final TextEditingController _spinspmController = TextEditingController();
  bool _isOneStepActive = false;

  @override
  void dispose() {
    _spmController.dispose();
    _manualStepController.dispose();
    _customCommandController.dispose();
    _spinstepsController.dispose();
    _spinspmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S25007 MQTT Controller'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MqttProvider>(
        builder: (context, mqttProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 연결 상태
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              mqttProvider.isConnected
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: mqttProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mqttProvider.isConnected
                                  ? '연결됨'
                                  : '연결 안됨',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mqttProvider.isConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (mqttProvider.isConnected) {
                              mqttProvider.disconnect();
                            } else {
                              mqttProvider.connect();
                            }
                          },
                          icon: Icon(mqttProvider.isConnected
                              ? Icons.cloud_off
                              : Icons.cloud),
                          label: Text(
                              mqttProvider.isConnected ? '연결 해제' : 'MQTT 연결'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 상태 정보
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '보드 상태 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildStatusInfo(mqttProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 모터 제어
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '모터 제어',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: mqttProvider.isConnected
                                    ? () => mqttProvider.startMotor()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mqttProvider.statusData['run'] == 'on'
                                      ? Colors.green
                                      : null,
                                  foregroundColor: mqttProvider.statusData['run'] == 'on'
                                      ? Colors.white
                                      : null,
                                ),
                                child: const Text('시작'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: mqttProvider.isConnected
                                    ? () => mqttProvider.stopMotor()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mqttProvider.statusData['run'] == 'off'
                                      ? Colors.red
                                      : null,
                                  foregroundColor: mqttProvider.statusData['run'] == 'off'
                                      ? Colors.white
                                      : null,
                                ),
                                child: const Text('정지'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: mqttProvider.isConnected
                                    ? () {
                                        mqttProvider.oneStep();
                                        setState(() {
                                          _isOneStepActive = true;
                                        });
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          if (mounted) {
                                            setState(() {
                                              _isOneStepActive = false;
                                            });
                                          }
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isOneStepActive
                                      ? Colors.blue
                                      : null,
                                  foregroundColor: _isOneStepActive
                                      ? Colors.white
                                      : null,
                                ),
                                child: const Text('한 스텝'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                // 고급 설정
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '속도 설정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // SPM 설정 (분당 스텝 수)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _spmController,
                                decoration: const InputDecoration(
                                  labelText: '분당 스텝 수 (1-2400)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected
                                  ? () {
                                      final value = int.tryParse(_spmController.text);
                                      if (value != null && value >= 1 && value <= 2400) {
                                        mqttProvider.setSpm(value);
                                        _spmController.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('분당 스텝 수 설정: $value')),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('설정'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // spinsteps 설정 (초기 가속 단계 스텝 수)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _spinstepsController,
                                decoration: const InputDecoration(
                                  labelText: '초기 가속 스텝 수',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected
                                  ? () {
                                      final value = int.tryParse(_spinstepsController.text);
                                      if (value != null) {
                                        mqttProvider.setSpinSteps(value);
                                        _spinstepsController.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('초기 가속 스텝 수 설정: $value')),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('설정'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // spinspm 설정 (초기 가속 속도)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _spinspmController,
                                decoration: const InputDecoration(
                                  labelText: '초기 가속 속도 (1-2400)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected
                                  ? () {
                                      final value = int.tryParse(_spinspmController.text);
                                      if (value != null && value >= 1 && value <= 2400) {
                                        mqttProvider.setSpinSpm(value);
                                        _spinspmController.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('초기 가속 속도 설정: $value')),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('설정'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Manual Step
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualStepController,
                                decoration: const InputDecoration(
                                  labelText: '수동 스텝 수',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected
                                  ? () {
                                      final value = int.tryParse(_manualStepController.text);
                                      if (value != null) {
                                        mqttProvider.manualStep(value);
                                        _manualStepController.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('수동 스텝: $value')),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('실행'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 사용자 정의 명령어
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customCommandController,
                                decoration: const InputDecoration(
                                  labelText: '사용자 명령어',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected
                                  ? () {
                                      final command = _customCommandController.text.trim();
                                      if (command.isNotEmpty) {
                                        mqttProvider.sendCommand(command);
                                        _customCommandController.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('명령 전송: $command')),
                                        );
                                      }
                                    }
                                  : null,
                              child: const Text('전송'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusInfo(MqttProvider provider) {
    if (!provider.isConnected) {
      return const Text('연결되지 않음');
    }

    final data = provider.statusData;
    if (data.isEmpty) {
      return const Text('상태 정보 대기중...');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow('IP', data['ip'] ?? 'N/A'),
        _buildStatusRow('Wi-Fi 신호', '${data['rssi'] ?? 'N/A'} dBm'),
        _buildStatusRow('모터 상태', data['run'] ?? 'N/A'),
        _buildStatusRow('동작 모드', data['mode'] ?? 'N/A'),
        _buildStatusRow('현재 속도', '${data['current_spm'] ?? 'N/A'} SPM'),
        _buildStatusRow('설정 속도', '${data['spm'] ?? 'N/A'} SPM'),
        _buildStatusRow('초기 가속 스텝', data['spinsteps'] ?? 'N/A'),
        _buildStatusRow('초기 가속 속도', '${data['spinspm'] ?? 'N/A'} SPM'),
        if (data.containsKey('spin_rem'))
          _buildStatusRow('남은 가속 스텝', data['spin_rem']!),
        if (data.containsKey('manual_rem'))
          _buildStatusRow('남은 수동 스텝', data['manual_rem']!),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}