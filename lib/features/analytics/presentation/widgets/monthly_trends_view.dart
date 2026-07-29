import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/domain/models/task_log.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/custom_card.dart';

class MonthlyTrendsView extends StatefulWidget {
  final Map<String, TaskLog> taskLogs;

  const MonthlyTrendsView({super.key, required this.taskLogs});

  @override
  State<MonthlyTrendsView> createState() => _MonthlyTrendsViewState();
}

class _MonthlyTrendsViewState extends State<MonthlyTrendsView> {
  bool _isCompoundTrend = false;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Past 30 days data (index 0 = 29 days ago, index 29 = today)
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    final List<int> dailyCounts = [];
    final List<int> cumulativeCounts = [];
    int runningSum = 0;

    for (final day in days) {
      final dateStr = AppDateUtils.toLocalYYYYMMDD(day);
      final log = widget.taskLogs[dateStr];
      final count = log?.completedCount ?? 0;
      dailyCounts.add(count);
      runningSum += count;
      cumulativeCounts.add(runningSum);
    }

    final dataPoints = _isCompoundTrend ? cumulativeCounts : dailyCounts;
    final maxValRaw = dataPoints.fold<int>(0, math.max);
    final maxVal = maxValRaw > 0 ? maxValRaw : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Subheader & Compound Trend Toggle Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '30-DAY PRODUCTIVITY VIEW',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            // ✨ COMPOUND TREND Toggle Button
            InkWell(
              onTap: () {
                setState(() {
                  _isCompoundTrend = !_isCompoundTrend;
                  _selectedIndex = null;
                });
              },
              borderRadius: BorderRadius.circular(20.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: _isCompoundTrend
                      ? const Color(0xFFA855F7)
                      : const Color(0xFFA855F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 13.0,
                      color: _isCompoundTrend ? Colors.white : const Color(0xFFA855F7),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'COMPOUND TREND',
                      style: TextStyle(
                        color: _isCompoundTrend ? Colors.white : const Color(0xFFA855F7),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Line Chart Container
        CustomCard(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 20.0, 16.0),
          child: Column(
            children: [
              // Chart Area with Y-Axis Labels
              SizedBox(
                height: 200.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Y-Axis Labels Column (e.g. 4, 3, 2, 1, 0)
                    SizedBox(
                      width: 24.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(5, (i) {
                          final val = (maxVal * (4 - i) / 4).round();
                          return Text(
                            '$val',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    // Interactive Line Chart
                    Expanded(
                      child: GestureDetector(
                        onTapDown: (details) {
                          final width = context.size?.width ?? 300.0;
                          final step = width / 29;
                          final idx = (details.localPosition.dx / step).round().clamp(0, 29);
                          setState(() {
                            _selectedIndex = idx;
                          });
                        },
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _MonthlyTrendsPainter(
                            dataPoints: dataPoints,
                            maxValue: maxVal,
                            selectedIndex: _selectedIndex,
                            lineColor: const Color(0xFFA855F7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),

              // X-Axis Labels Row (showing dates Jul 1, Jul 3, ...)
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (i) {
                    final idx = (i * 29 / 9).round().clamp(0, 29);
                    final d = days[idx];
                    final monthStr = _getMonthAbbr(d.month);
                    final dayStr = '$monthStr ${d.day}';
                    return Text(
                      dayStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _MonthlyTrendsPainter extends CustomPainter {
  final List<int> dataPoints;
  final int maxValue;
  final int? selectedIndex;
  final Color lineColor;

  _MonthlyTrendsPainter({
    required this.dataPoints,
    required this.maxValue,
    required this.selectedIndex,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final width = size.width;
    final height = size.height;
    final count = dataPoints.length;
    final stepX = width / (count - 1);

    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = height - (dataPoints[i] / maxValue) * (height - 20) - 10;
      points.add(Offset(x, y));
    }

    // Dashed Horizontal Grid Lines (5 levels)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = (height - 20) * (i / 4) + 10;
      _drawDashedLine(canvas, Offset(0, y), Offset(width, y), gridPaint);
    }

    // Smooth Bezier Curve Path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient Fill Under Line
    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withValues(alpha: 0.30),
        lineColor.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(fillPath, fillPaint);

    // Smooth Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Selected Point Vertical Line & Tooltip Circle
    if (selectedIndex != null && selectedIndex! < points.length) {
      final p = points[selectedIndex!];

      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, height),
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.0,
      );

      canvas.drawCircle(p, 6.0, Paint()..color = lineColor);
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendsPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxValue != maxValue;
  }
}
