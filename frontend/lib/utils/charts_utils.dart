import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AppCharts {
  static PieChartData createPieChart({
    required List<PieChartSectionData> sections,
    double centerSpaceRadius = 40,
  }) {
    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: centerSpaceRadius,
      borderData: FlBorderData(show: false),
    );
  }

  static List<PieChartSectionData> createPieSections({
    required List<double> values,
    required List<Color> colors,
    required List<String> titles,
    double radius = 60,
  }) {
    return List.generate(values.length, (i) {
      return PieChartSectionData(
        color: colors[i],
        value: values[i],
        title: titles[i],
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      );
    });
  }

  /// Pie chart legend widget
  static Widget buildPieChartLegend({
    required List<Color> colors,
    required List<String> labels,
    List<String>? values, // Optional: show percentages or counts
    double boxSize = 14,
    double spacing = 12,
    double fontSize = 13,
  }) {
    return Wrap(
      spacing: spacing,
      children: List.generate(colors.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              labels[i] +
                  (values != null && i < values.length
                      ? ' (${values[i]})'
                      : ''),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        );
      }),
    );
  }

  static BarChartData createVerticalBarChart({
    required List<BarChartGroupData> barGroups,
    required double maxY,
    required List<String> bottomTitles,
    bool showLeftTitles = true,
    bool showBottomTitles = true,
    double leftReservedSize = 40,
    double bottomReservedSize = 60,
    double leftTitleFontSize = 12,
    double bottomTitleFontSize = 12,
  }) {
    return BarChartData(
      alignment: BarChartAlignment.center,
      maxY: maxY,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showLeftTitles,
            reservedSize: leftReservedSize,
            getTitlesWidget:
                (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: leftTitleFontSize),
                    textAlign: TextAlign.right,
                  ),
                ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showBottomTitles,
            reservedSize: bottomReservedSize,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= bottomTitles.length) {
                return const SizedBox.shrink();
              }
              final label =
                  bottomTitles[idx].length > 14
                      ? '${bottomTitles[idx].substring(0, 14)}…'
                      : bottomTitles[idx];
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: bottomTitleFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final label = bottomTitles[group.x.toInt()];
            return BarTooltipItem(
              '$label\n${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      gridData: FlGridData(show: true, drawHorizontalLine: true),
      borderData: FlBorderData(show: false),
    );
  }
}

class BarChartGroups {
  static BarChartGroupData createBarGroup({
    required int x,
    required double y,
    required Color color,
    double width = 16,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: width,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
