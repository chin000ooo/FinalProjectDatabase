import 'package:flutter/material.dart';
import '../features/auth/Forgot.dart';
import '../features/auth/Login.dart';
import '../features/auth/Newpass.dart';
import '../features/auth/Register.dart';
import '../features/settings/SettingsScreen.dart';
import '../main.dart'; // Import เพื่อใช้ MyAppState

// ฟังก์ชันกำหนดเส้นทางทั้งหมดในแอป
class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/settings': (context) => SettingsScreen(
          onThemeChange: (ThemeMode themeMode) {
            // เปลี่ยนธีมเมื่อมีการเลือก
            MyAppState().changeTheme(themeMode);
          },
          onAnimationSelected: (String selectedAnimationUrl) {
            // handle the selected animation URL here
            print('Selected animation URL: $selectedAnimationUrl');
          },
        ),
    '/login': (context) => Login(
          onLoginSuccess: () {
            print('Login success');
            Navigator.pop(context);
          },
        ),
    '/register': (context) => const Register(),
    '/forgot': (context) => const ForgotPasswordScreen(),
    '/newpass': (context) => const NewPasswordScreen(),
  };
}
