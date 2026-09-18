import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/dashboard_stats.dart';

class MonthlyOrdersBarChart extends StatefulWidget {
  final List<MonthlyPoint> data;

  const MonthlyOrdersBarChart({super.key, required this.data});

  @override
  State<MonthlyOrdersBarChart> createState() => _MonthlyOrdersBarChartState();
}

class _MonthlyOrdersBarChartState extends State<MonthlyOrdersBarChart> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.data.isEmpty ? 0 : widget.data.length - 1;
  }

  @override
  void didUpdateWidget(covariant MonthlyOrdersBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.length != widget.data.length) {
      _selectedIndex = widget.data.isEmpty ? 0 : widget.data.length - 1;
    }
  }

  void _select(int index) {
    if (index < 0 || index >= widget.data.length) return;
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return const SizedBox();

    final selected = data[_selectedIndex];
    final count = selected.value.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${selected.month} · ',
                style: TextStyle(
                  fontSize: Responsive.font(context, 13, capSystemScale: false),
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withOpacity(0.6),
                ),
              ),
              TextSpan(
                text: '$count ${count == 1 ? 'order' : 'orders'}',
                style: TextStyle(
                  fontSize: Responsive.font(context, 15, capSystemScale: false),
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          data[i].month,
                          style: TextStyle(
                            fontSize: Responsive.font(context, 11),
                            fontWeight:
                                i == _selectedIndex ? FontWeight.w800 : FontWeight.w600,
                            color: i == _selectedIndex
                                ? AppColors.ink
                                : AppColors.ink.withOpacity(0.55),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: false,
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => AppColors.ink,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = data[groupIndex].month;
                    final total = rod.toY.round();
                    return BarTooltipItem(
                      '$month\n',
                      const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: '$total ${total == 1 ? 'order' : 'orders'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (event, response) {
                  final spot = response?.spot;
                  if (spot == null) return;
                  if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
                    _select(spot.touchedBarGroupIndex);
                  }
                },
              ),
              barGroups: [
                for (var i = 0; i < data.length; i++)
                  BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: i == _selectedIndex ? [0] : [],
                    barRods: [
                      BarChartRodData(
                        toY: data[i].value,
                        color: i == _selectedIndex ? AppColors.gold : AppColors.ink,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}