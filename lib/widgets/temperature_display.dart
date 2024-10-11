import 'package:flutter/material.dart';

class TemperatureDisplay extends StatelessWidget {
  final String temperature;

  const TemperatureDisplay({super.key, required this.temperature});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$temperature°C',
      style: const TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
