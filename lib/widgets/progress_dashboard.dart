import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/session_service.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await SessionService.getSessionHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const Center(
        child: Text("No session data yet. Complete your first session to see progress!"),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Therapeutic Insights",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2B),
                    ),
                  ),
                  Text(
                    "Behavioral and emotional trends",
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A839A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF1A73E8)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // --- Risk Trend Chart ---
          const _ChartLabel(title: "Distress Level Trend", subtitle: "Based on multimodal analysis"),
          const SizedBox(height: 16),
          _buildRiskChart(),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          
          // --- Summary Stats ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: "Total Sessions", 
                value: _history.length.toString(),
                icon: Icons.calendar_today_rounded,
              ),
              _StatItem(
                label: "Peak Risk", 
                value: "${(_history.map((e) => (e['risk_score'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(0)}%",
                icon: Icons.priority_high_rounded,
                color: Colors.orange,
              ),
              _StatItem(
                label: "Latest Risk", 
                value: "${(_history.last['risk_score'] * 100).toStringAsFixed(0)}%",
                icon: Icons.analytics_outlined,
                color: _history.last['risk_level'] == 'HIGH' ? Colors.red : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChart() {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "S${value.toInt() + 1}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _history.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value['risk_score'].toDouble());
              }).toList(),
              isCurved: true,
              color: const Color(0xFF1A73E8),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A73E8).withOpacity(0.2),
                    const Color(0xFF1A73E8).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: 1.0,
        ),
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ChartLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF444C5E))),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF7A839A))),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? const Color(0xFF1A73E8)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF1A1D2B),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF7A839A))),
      ],
    );
  }
}
