import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yanzee_app/core/theme/app_colors.dart';
import 'package:yanzee_app/core/utils/currency_format.dart';
import 'package:yanzee_app/core/utils/responsive.dart';
import 'package:yanzee_app/data/models/dashboard_stats.dart';

class RevenueLineChart extends StatefulWidget {
  final List<MonthlyPoint> data;
  final int visitCount;

  const RevenueLineChart({
    super.key,
    required this.data,
    required this.visitCount,
  });

  @override
  State<RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<RevenueLineChart>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _revealController;
  late Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.data.isEmpty ? 0 : widget.data.length - 1;

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _reveal = CurvedAnimation(parent: _revealController, curve: Curves.easeOutCubic);
    _revealController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant RevenueLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.visitCount != widget.visitCount) {
      _selectedIndex = widget.data.isEmpty ? 0 : widget.data.length - 1;
      _revealController.forward(from: 0);
    } else if (oldWidget.data.length != widget.data.length) {
      _selectedIndex = widget.data.isEmpty ? 0 : widget.data.length - 1;
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 || index >= widget.data.length) return;
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  List<FlSpot> _visibleSpots(List<FlSpot> allSpots, double t) {
    if (allSpots.length <= 1) return allSpots;
    final maxIndex = allSpots.length - 1;
    final progress = t * maxIndex;
    final flooredIndex = progress.floor().clamp(0, maxIndex);
    final frac = progress - flooredIndex;

    final visible = <FlSpot>[
      for (var i = 0; i <= flooredIndex; i++) allSpots[i],
    ];

    if (flooredIndex < maxIndex && frac > 0) {
      final start = allSpots[flooredIndex];
      final end = allSpots[flooredIndex + 1];
      visible.add(FlSpot(
        start.x + (end.x - start.x) * frac,
        start.y + (end.y - start.y) * frac,
      ));
    }

    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    if (data.isEmpty) return const SizedBox();

    final allSpots = [
      for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].value),
    ];

    final maxY = data.map((d) => d.value).fold<double>(0, (a, b) => a > b ? a : b);
    final minX = 0.0;
    final maxX = (data.length - 1).toDouble();

    final selected = data[_selectedIndex];

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
                text: 'Rs ${formatNepaliStyle(selected.value)}',
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
          child: AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) {
              final t = _reveal.value;
              final isDrawComplete = t >= 1.0;
              final visibleSpots = _visibleSpots(allSpots, t);

              final lineBar = LineChartBarData(
                isCurved: true,
                color: AppColors.gold,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, bar) =>
                      isDrawComplete && spot.x.toInt() == _selectedIndex,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.gold,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.gold.withOpacity(0.12),
                ),
                spots: visibleSpots,
              );

              return LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: maxY == 0 ? 1 : maxY * 1.15,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                fontWeight: i == _selectedIndex
                                    ? FontWeight.w800
                                    : FontWeight.w600,
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
                  borderData: FlBorderData(show: false),
                  extraLinesData: isDrawComplete
                      ? ExtraLinesData(
                          verticalLines: [
                            VerticalLine(
                              x: _selectedIndex.toDouble(),
                              color: AppColors.gold.withOpacity(0.35),
                              strokeWidth: 1.5,
                              dashArray: [4, 4],
                            ),
                          ],
                        )
                      : const ExtraLinesData(),
                  showingTooltipIndicators: isDrawComplete
                      ? [
                          ShowingTooltipIndicators([
                            LineBarSpot(lineBar, 0, allSpots[_selectedIndex]),
                          ]),
                        ]
                      : [],
                  lineTouchData: LineTouchData(
                    enabled: isDrawComplete,
                    handleBuiltInTouches: false,
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (touchedSpot) => AppColors.ink,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      tooltipPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final i = spot.x.toInt();
                          final month =
                              (i >= 0 && i < data.length) ? data[i].month : '';
                          return LineTooltipItem(
                            '$month\n',
                            const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Rs ${formatNepaliStyle(spot.y)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      if (!isDrawComplete) return;
                      final spots = response?.lineBarSpots;
                      if (spots == null || spots.isEmpty) return;
                      if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
                        _select(spots.first.x.toInt());
                      }
                    },
                  ),
                  lineBarsData: [lineBar],
                ),
                duration: Duration.zero,
              );
            },
          ),
        ),
      ],
    );
  }
}