import 'package:flutter/material.dart';

class ThemeSelectionScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeSelected; // ฟังก์ชันสำหรับเปลี่ยนธีม

  const ThemeSelectionScreen({super.key, required this.onThemeSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Theme'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Light Theme'),
            onTap: () {
              onThemeSelected(ThemeMode.light); // เปลี่ยนเป็นธีม Light
              Navigator.pop(context); // ปิดหน้าหลังจากเลือก
            },
          ),
          ListTile(
            title: const Text('Dark Theme'),
            onTap: () {
              onThemeSelected(ThemeMode.dark); // เปลี่ยนเป็นธีม Dark
              Navigator.pop(context); // ปิดหน้าหลังจากเลือก
            },
          ),
        ],
      ),
    );
  }
}
