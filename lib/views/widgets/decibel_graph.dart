import 'package:flutter/material.dart';

class DecibelGraphPainter extends StatelessWidget {
  final List<double> decibelHistory;
  final Color color;

  const DecibelGraphPainter({
    Key? key,
    required this.decibelHistory,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DecibelGraphPainter(
        decibelHistory: decibelHistory,
        color: color,
      ),
    );
  }
}

class _DecibelGraphPainter extends CustomPainter {
  final List<double> decibelHistory;
  final Color color;

  _DecibelGraphPainter({
    required this.decibelHistory,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (decibelHistory.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final xStep = width / (decibelHistory.length - 1);

    // Normalize values between 0 and 1
    final maxDecibel = decibelHistory.reduce((a, b) => a > b ? a : b);
    final minDecibel = decibelHistory.reduce((a, b) => a < b ? a : b);
    final range = maxDecibel - minDecibel;

    path.moveTo(0, height - ((decibelHistory[0] - minDecibel) / range * height));

    for (int i = 1; i < decibelHistory.length; i++) {
      final x = i * xStep;
      final normalizedValue = (decibelHistory[i] - minDecibel) / range;
      final y = height - (normalizedValue * height);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DecibelGraphPainter oldDelegate) {
    return oldDelegate.decibelHistory != decibelHistory ||
        oldDelegate.color != color;
  }
}