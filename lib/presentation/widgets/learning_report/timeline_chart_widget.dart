import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/models/learning_report_model.dart';
import '../../themes/app_theme.dart';
import '../glass_card.dart';

class TimelineChartWidget extends StatefulWidget {
  final List<TimelinePoint> timeline;
  final bool isDark;

  const TimelineChartWidget({
    super.key,
    required this.timeline,
    required this.isDark,
  });

  @override
  State<TimelineChartWidget> createState() => _TimelineChartWidgetState();
}

class _TimelineChartWidgetState extends State<TimelineChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.timeline.isEmpty) return const SizedBox.shrink();

    // Prepare data
    final List<FlSpot> studySpots = [];
    final List<FlSpot> productivitySpots = [];

    double maxStudy = 0;
    double maxProd = 0;

    for (int i = 0; i < widget.timeline.length; i++) {
      final point = widget.timeline[i];
      final study = point.studyMinutes?.toDouble() ?? 0.0;
      final prod = (point.missionsCompleted ?? 0) +
          (point.tasksCompleted ?? 0) +
          (point.jobsCompleted ?? 0).toDouble();

      studySpots.add(FlSpot(i.toDouble(), study));
      productivitySpots.add(FlSpot(i.toDouble(), prod));

      if (study > maxStudy) maxStudy = study;
      if (prod > maxProd) maxProd = prod;
    }

    // Scale productivity to match study minutes visually if needed, 
    // but FlChart allows multiple bars on the same axis.
    // If scales are vastly different, we can normalize. Let's normalize prod to study.
    final scaleFactor = maxStudy > 0 && maxProd > 0 ? maxStudy / maxProd : 1.0;
    
    final normalizedProdSpots = productivitySpots.map((spot) {
      return FlSpot(spot.x, spot.y * scaleFactor);
    }).toList();

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 20,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dòng Thời Gian Hoạt Động',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Phân tích chi tiết: Thời gian học & Nhiệm vụ đã hoàn thành',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => widget.isDark 
                          ? Colors.blueGrey.shade800 
                          : Colors.white.withOpacity(0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final point = widget.timeline[touchedSpot.x.toInt()];
                          final isStudy = touchedSpot.barIndex == 0;
                          
                          if (isStudy) {
                            return LineTooltipItem(
                              'Thời gian học\n${point.studyMinutes ?? 0} phút',
                              const TextStyle(
                                color: AppTheme.accentCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          } else {
                            final prod = (point.missionsCompleted ?? 0) +
                              (point.tasksCompleted ?? 0) +
                              (point.jobsCompleted ?? 0);
                            return LineTooltipItem(
                              'Hoàn thành\n$prod',
                              TextStyle(
                                color: AppTheme.primaryBlueDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.lineBarSpots == null) {
                        setState(() {
                          touchedIndex = -1;
                        });
                        return;
                      }
                      setState(() {
                        touchedIndex = response.lineBarSpots!.first.x.toInt();
                      });
                    },
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxStudy > 0 ? maxStudy / 4 : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: widget.isDark ? Colors.white10 : Colors.black12,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= widget.timeline.length) {
                            return const SizedBox.shrink();
                          }
                          // Only show some labels to avoid crowding
                          final step = max(1, widget.timeline.length ~/ 6);
                          if (value.toInt() % step != 0 && value.toInt() != widget.timeline.length - 1) {
                            return const SizedBox.shrink();
                          }
                          
                          final label = widget.timeline[value.toInt()].bucketLabel ?? '';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxStudy > 0 ? maxStudy / 4 : 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == maxStudy) return const SizedBox.shrink(); // Hide top label if it clips
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (widget.timeline.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxStudy * 1.1 > 0 ? maxStudy * 1.1 : 10,
                  lineBarsData: [
                    // Area Chart for Study Minutes
                    LineChartBarData(
                      spots: studySpots,
                      isCurved: true,
                      color: AppTheme.accentCyan,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.accentCyan.withOpacity(0.3),
                            AppTheme.accentCyan.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    // Line Chart for Productivity
                    LineChartBarData(
                      spots: normalizedProdSpots,
                      isCurved: true,
                      color: AppTheme.primaryBlueDark,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.primaryBlueDark,
                            strokeWidth: 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppTheme.accentCyan, 'Thời Gian Học (phút)', widget.isDark),
                const SizedBox(width: 16),
                _buildLegendItem(AppTheme.primaryBlueDark, 'Đã Hoàn Thành', widget.isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
