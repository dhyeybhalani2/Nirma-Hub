import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'features/timetable/presentation/providers/timetable_provider.dart';
import 'dart:ui' as ui;
import 'home_screen.dart';

const nirmaRed = Color(0xFFE53935);
const baseNavy = Color(0xFF0F1A2C);
const textGray = Color(0xFF8A92A6);
const borderGray = Color(0xFFE2E8F0);

class AnimatedSemesterProgress extends ConsumerStatefulWidget {
  const AnimatedSemesterProgress({super.key});

  @override
  ConsumerState<AnimatedSemesterProgress> createState() => _AnimatedSemesterProgressState();
}

class _AnimatedSemesterProgressState extends ConsumerState<AnimatedSemesterProgress> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final startDate = DateTime(now.year, 6, 5); // June 5
    final endDate = DateTime(now.year, 11, 11); // Nov 11
    
    // --- DEMO OVERRIDE ---
    double progress = 0.90;
    progress = progress.clamp(0.0, 1.0);
    final isCompleted = progress >= 0.9;
    final int progressPercent = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.transparent, width: 0),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: nirmaRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bar_chart, color: nirmaRed, size: 24),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Semester Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: baseNavy)),
                      SizedBox(height: 6),
                      Text("3rd Semester", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: nirmaRed)),
                    ],
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: nirmaRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("$progressPercent%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: nirmaRed)),
              )
            ],
          ),
          SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  Text("Jun 5", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: nirmaRed)),
                  SizedBox(height: 4),
                  Container(width: 1.5, height: 22, color: nirmaRed),
                  SizedBox(height: 4),
                  Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: nirmaRed)),
                ],
              ),
              SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      const barHeight = 22.0;
                      
                      return AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          final val = _waveController.value;
                          const waveAmplitude = 2.5;
                          final waveY = waveAmplitude * math.sin((progress * math.pi * 4) - (val * math.pi * 2)) + waveAmplitude + 2; 
                          final capTilt = math.cos((progress * math.pi * 4) - (val * math.pi * 2)) * 0.1;
                          final capSize = 16.0 + (progress * 12.0);
                          
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: barWidth,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F5),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: CustomPaint(
                                    painter: _WaterWavePainter(val, progress, isCompleted),
                                  ),
                                ),
                              ),
                              if (progress > 0) ...[
                                // Tooltip
                                Positioned(
                                  left: ((barWidth * progress) - 36).clamp(0.0, barWidth - 72.0), 
                                  bottom: barHeight - waveY + capSize - 4, 
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, color: Color(0xFFFF9E9E), size: 12),
                                      SizedBox(width: 4),
                                      Stack(
                                        alignment: Alignment.bottomCenter,
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))
                                              ],
                                            ),
                                            child: Text(
                                              "$progressPercent%",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: isCompleted ? const Color(0xFF10B981) : nirmaRed,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -3,
                                            child: Transform.rotate(
                                              angle: math.pi / 4,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                color: Theme.of(context).colorScheme.surface,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.auto_awesome, color: Color(0xFFFF9E9E), size: 16),
                                    ],
                                  ),
                                ),
                                // Cap
                                Positioned(
                                  left: (barWidth * progress) - (capSize / 2), 
                                  bottom: barHeight - waveY - 4, 
                                  child: Transform.rotate(
                                    angle: capTilt,
                                    child: Icon(
                                      Icons.school,
                                      color: isCompleted ? const Color(0xFF10B981) : nirmaRed,
                                      size: capSize,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                      );
                    }
                  ),
                ),
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  Text("Nov 11", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textGray)),
                  SizedBox(height: 4),
                  Container(width: 1.5, height: 22, color: textGray),
                  SizedBox(height: 4),
                  Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: textGray)),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              "✨ Just ${100 - progressPercent}% more to go!  💪",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textGray),
            ),
          )
        ],
      ),
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double animationValue;
  final double progress;
  final bool isCompleted;

  _WaterWavePainter(this.animationValue, this.progress, this.isCompleted);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final width = size.width * progress;
    final height = size.height;
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, height),
        isCompleted
            ? [const Color(0xFF34D399), const Color(0xFF059669)]
            : [const Color(0xFFFF7A7A), const Color(0xFFE53935)],
      );
    
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final highlightPath = Path();

    const waveAmplitude = 2.5;
    
    path.moveTo(0, height);
    path.lineTo(0, waveAmplitude);
    highlightPath.moveTo(0, waveAmplitude);

    for (double x = 0; x <= width; x++) {
      final normalizedX = x / size.width;
      final waveY = waveAmplitude * math.sin((normalizedX * math.pi * 4) - (animationValue * math.pi * 2)) + waveAmplitude + 2; 
      
      path.lineTo(x, waveY);
      highlightPath.lineTo(x, waveY);
    }

    path.lineTo(width, height);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(highlightPath, highlightPaint);

    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    void drawBubble(double startX, double speedMultiplier, double bubbleSize) {
      if (startX > width) return;
      double progressY = (animationValue * speedMultiplier) % 1.0;
      double y = height - (progressY * height);
      double xOffset = math.sin(progressY * math.pi * 4) * 2;
      canvas.drawCircle(Offset(startX + xOffset, y), bubbleSize, bubblePaint);
    }
    
    drawBubble(width * 0.3, 1.2, 1.5);
    drawBubble(width * 0.7, 0.9, 1.2);
  }

  @override
  bool shouldRepaint(_WaterWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.progress != progress || 
           oldDelegate.isCompleted != isCompleted;
  }
}
