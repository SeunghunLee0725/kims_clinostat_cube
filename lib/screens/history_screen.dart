import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _speedData = [];
  Map<String, int>? _speedStats;
  double? _averageSpeed;
  bool _isLoading = false;
  String _selectedPeriod = '1 hour';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final String _deviceId = 's25007/board1';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> result = [];
    DateTime startTime;
    DateTime endTime = DateTime.now();

    if (_selectedPeriod == '1 hour') {
      startTime = endTime.subtract(const Duration(hours: 1));
      result = await _supabaseService.getLastHourSpeedData(deviceId: _deviceId);
    } else if (_selectedPeriod == '24 hours') {
      startTime = endTime.subtract(const Duration(hours: 24));
      result = await _supabaseService.getLast24HoursSpeedData(deviceId: _deviceId);
    } else if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
      startTime = _customStartDate!;
      endTime = _customEndDate!;
      result = await _supabaseService.getSpeedDataByTimeRange(
        startTime: startTime,
        endTime: endTime,
        deviceId: _deviceId,
      );
    } else {
      startTime = endTime.subtract(const Duration(hours: 1));
      result = await _supabaseService.getLastHourSpeedData(deviceId: _deviceId);
    }

    // Get statistics
    final stats = await _supabaseService.getSpeedStats(
      startTime: startTime,
      endTime: endTime,
      deviceId: _deviceId,
    );
    
    final average = await _supabaseService.getAverageSpeed(
      startTime: startTime,
      endTime: endTime,
      deviceId: _deviceId,
    );

    setState(() {
      _speedData = result;
      _speedStats = stats;
      _averageSpeed = average;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _customEndDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        _selectedPeriod = 'custom';
      });
      _loadData();
    }
  }

  List<FlSpot> _getChartData() {
    if (_speedData.isEmpty) return [];

    // Sort data by timestamp first to ensure chronological order
    final sortedData = List<Map<String, dynamic>>.from(_speedData)
      ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    // Remove any duplicate timestamps to prevent chart issues
    final uniqueData = <Map<String, dynamic>>[];
    DateTime? lastTimestamp;
    
    for (final data in sortedData) {
      final timestamp = DateTime.parse(data['timestamp']);
      if (lastTimestamp == null || timestamp.difference(lastTimestamp).inSeconds >= 1) {
        uniqueData.add(data);
        lastTimestamp = timestamp;
      }
    }

    if (uniqueData.isEmpty) return [];

    final spots = <FlSpot>[];
    final firstTime = DateTime.parse(uniqueData.first['timestamp']);
    
    // Create spots with proper x-axis values
    for (int i = 0; i < uniqueData.length; i++) {
      final data = uniqueData[i];
      final time = DateTime.parse(data['timestamp']);
      final minutesFromStart = time.difference(firstTime).inMinutes.toDouble();
      final speed = (data['current_spm'] as num).toDouble();
      
      // Ensure valid values
      if (speed.isFinite && minutesFromStart.isFinite) {
        spots.add(FlSpot(minutesFromStart, speed));
      }
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Speed History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Period selector with modern design
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodChip('1 Hour', '1 hour'),
                _buildPeriodChip('24 Hours', '24 hours'),
                _buildCustomRangeChip(),
              ],
            ),
          ),

          // Statistics Cards
          if (_speedStats != null && _averageSpeed != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('MIN', '${_speedStats!['min']}', 'SPM', Colors.indigo),
                  _buildStatCard('AVG', _averageSpeed!.toStringAsFixed(0), 'SPM', Colors.teal),
                  _buildStatCard('MAX', '${_speedStats!['max']}', 'SPM', Colors.deepOrange),
                ],
              ),
            ),

          // Chart
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _speedData.isEmpty
                    ? Container(
                        margin: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timeline_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No Data Available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Speed data will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'once measurements are recorded',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Chart header
                            Container(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.speed,
                                      size: 20,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Speed Trend',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      Text(
                                        'Strokes per minute over time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: _getYInterval(),
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey[300]!,
                                        strokeWidth: 1,
                                        dashArray: [5, 5],
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      axisNameWidget: Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      axisNameSize: 20,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: _getXLabelInterval(),
                                        getTitlesWidget: (value, meta) {
                                          if (_speedData.isEmpty || value < 0) return const SizedBox.shrink();
                                          
                                          final sortedData = List<Map<String, dynamic>>.from(_speedData)
                                            ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
                                          
                                          if (sortedData.isEmpty) return const SizedBox.shrink();
                                          
                                          final firstTime = DateTime.parse(sortedData.first['timestamp']);
                                          final currentTime = firstTime.add(Duration(minutes: value.toInt()));
                                          
                                          // Format based on duration
                                          String format;
                                          if (_selectedPeriod == '1 hour') {
                                            format = 'HH:mm';
                                          } else if (_selectedPeriod == '24 hours') {
                                            format = 'HH:mm';
                                          } else {
                                            format = 'MM/dd HH:mm';
                                          }
                                          
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              DateFormat(format).format(currentTime),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      axisNameWidget: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text(
                                          'Speed (SPM)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      axisNameSize: 20,
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        interval: _getYInterval(),
                                        getTitlesWidget: (value, meta) {
                                          if (value == meta.max || value == meta.min) {
                                            return const SizedBox.shrink();
                                          }
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                              value.toInt().toString(),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.grey[500]!, width: 2),
                                      left: BorderSide(color: Colors.grey[500]!, width: 2),
                                      right: BorderSide(color: Colors.transparent),
                                      top: BorderSide(color: Colors.transparent),
                                    ),
                                  ),
                                  minX: 0,
                                  maxX: _getMaxX(),
                                  minY: 0,
                                  maxY: _getMaxY(),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _getChartData(),
                                      isCurved: true,
                                      curveSmoothness: 0.2,
                                      preventCurveOverShooting: true,
                                      color: theme.primaryColor,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: _speedData.length <= 20,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: Colors.white,
                                            strokeWidth: 2,
                                            strokeColor: theme.primaryColor,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.primaryColor.withOpacity(0.15),
                                            theme.primaryColor.withOpacity(0.02),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.3, 1.0],
                                        ),
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipRoundedRadius: 12,
                                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      tooltipBgColor: Colors.grey[900]!.withOpacity(0.95),
                                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                        return touchedBarSpots.map((barSpot) {
                                          final sortedData = List<Map<String, dynamic>>.from(_speedData)
                                            ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
                                          
                                          if (sortedData.isEmpty) return null;
                                          
                                          final firstTime = DateTime.parse(sortedData.first['timestamp']);
                                          final touchedTime = firstTime.add(Duration(minutes: barSpot.x.toInt()));
                                          
                                          return LineTooltipItem(
                                            '',
                                            const TextStyle(),
                                            children: [
                                              TextSpan(
                                                text: '${barSpot.y.toInt()}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' SPM\n',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              TextSpan(
                                                text: DateFormat('HH:mm:ss').format(touchedTime),
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList();
                                      },
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                    ),
                                    handleBuiltInTouches: true,
                                    getTouchedSpotIndicator: (barData, spotIndexes) {
                                      return spotIndexes.map((spotIndex) {
                                        return TouchedSpotIndicatorData(
                                          FlLine(
                                            color: theme.primaryColor.withOpacity(0.2),
                                            strokeWidth: 1,
                                            dashArray: [6, 3],
                                          ),
                                          FlDotData(
                                            getDotPainter: (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 6,
                                                color: Colors.white,
                                                strokeWidth: 3,
                                                strokeColor: theme.primaryColor,
                                              );
                                            },
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // Data count indicator with modern design
          if (!_isLoading && _speedStats != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        const TextSpan(text: 'Total data points: '),
                        TextSpan(
                          text: '${_speedStats!['count']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedPeriod = value);
          _loadData();
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: Colors.grey[100],
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildCustomRangeChip() {
    final isSelected = _selectedPeriod == 'custom';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 15,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              isSelected ? 
                (_customStartDate != null && _customEndDate != null
                  ? '${DateFormat('MM/dd').format(_customStartDate!)} - ${DateFormat('MM/dd').format(_customEndDate!)}'
                  : 'Custom')
                : 'Select Range',
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => _selectDateRange(),
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: Colors.grey[100],
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color.withOpacity(0.85),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _getXLabelInterval() {
    if (_speedData.isEmpty) return 10;
    
    final maxX = _getMaxX();
    
    // Return interval in minutes
    if (maxX <= 60) return 10; // Every 10 minutes for 1 hour
    if (maxX <= 180) return 30; // Every 30 minutes for 3 hours
    if (maxX <= 360) return 60; // Every hour for 6 hours
    if (maxX <= 1440) return 240; // Every 4 hours for 24 hours
    return 720; // Every 12 hours for longer periods
  }

  double _getYInterval() {
    final maxY = _getMaxY();
    
    // Calculate interval for about 5-8 grid lines
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 40;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 2000) return 400;
    if (maxY <= 5000) return 1000;
    
    // For larger values
    return (maxY / 5).roundToDouble();
  }

  double _getMaxX() {
    if (_speedData.isEmpty) return 60; // Default to 1 hour in minutes
    
    final sortedData = List<Map<String, dynamic>>.from(_speedData)
      ..sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
    
    if (sortedData.length < 2) return 60;
    
    final duration = DateTime.parse(sortedData.last['timestamp'])
        .difference(DateTime.parse(sortedData.first['timestamp']))
        .inMinutes
        .toDouble();
    
    // Add 5% padding for better visualization
    final paddedDuration = duration * 1.05;
    return paddedDuration > 0 ? paddedDuration : 60;
  }

  double _getMinY() {
    // Always start from 0 for better visualization
    return 0;
  }

  double _getMaxY() {
    if (_speedData.isEmpty) return 1000;
    
    // Find the maximum value
    double maxSpeed = 0;
    for (final data in _speedData) {
      final speed = (data['current_spm'] as num).toDouble();
      if (speed > maxSpeed) maxSpeed = speed;
    }
    
    // Add 20% padding and round up to nice number
    final paddedMax = maxSpeed * 1.2;
    
    // Round to nearest nice number
    if (paddedMax <= 100) return 100;
    if (paddedMax <= 200) return 200;
    if (paddedMax <= 500) return 500;
    if (paddedMax <= 1000) return 1000;
    if (paddedMax <= 2000) return 2000;
    if (paddedMax <= 5000) return 5000;
    
    // For larger values, round to nearest 1000
    return ((paddedMax / 1000).ceil() * 1000).toDouble();
  }
}