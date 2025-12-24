import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimulationChart extends StatelessWidget {
  final List<double> data;
  const SimulationChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barGroups: data
                  .asMap()
                  .entries
                  .map((e) => BarChartGroupData(
                        x: e.key,
                        barRods: [BarChartRodData(toY: e.value)],
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
