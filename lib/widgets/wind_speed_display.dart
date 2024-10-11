import 'package:flutter/material.dart';

class WindSpeedDisplay extends StatelessWidget {
  final String windSpeed;

  const WindSpeedDisplay({super.key, required this.windSpeed});

  @override
  Widget build(BuildContext context) {
    // แสดงความเร็วลมเป็นจำนวนเต็ม
    return Text(
      '${double.tryParse(windSpeed)?.toStringAsFixed(0) ?? 'N/A'} m/s', // แปลงเป็นจำนวนเต็ม
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
