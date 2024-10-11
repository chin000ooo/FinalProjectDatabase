import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import Firebase Options
import 'navigation/routes.dart'; // Import routing
import 'features/weather/WeatherScreen.dart'; // Import WeatherScreen
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart'; // Import UserService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('th_TH', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; // ค่าเริ่มต้นคือ System Default
  String? _preferredProvince; // ตัวแปรเก็บ province ที่เลือกไว้
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserSettings(); // โหลดข้อมูลการตั้งค่าผู้ใช้
  }

  Future<void> _loadUserSettings() async {
    User? user = _auth.currentUser;

    if (user != null) {
      Map<String, dynamic> userSettings =
          await UserService.getUserSettings(user.uid);

      setState(() {
        _themeMode = _parseThemeMode(userSettings['theme']);
        _preferredProvince = userSettings['preferredProvince'] ??
            'Default Province'; // ค่า default
      });
    }
  }

  // แปลงข้อมูลธีมที่ได้จาก Firebase เป็น ThemeMode
  ThemeMode _parseThemeMode(String? theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // ฟังก์ชันเพื่อเปลี่ยนธีม
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });

    // อัปเดตธีมของผู้ใช้ใน Firebase เมื่อผู้ใช้เปลี่ยนธีม
    User? user = _auth.currentUser;
    if (user != null) {
      UserService.updateTheme(user.uid, themeMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // พื้นหลังของ Light Theme
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // พื้นหลังของ Dark Theme
        primarySwatch: Colors.grey,
        appBarTheme: const AppBarTheme(
          color: Colors.black, // สีของ AppBar ใน Dark Theme
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // สีของไอคอนใน Dark Theme
        ),
      ),
      themeMode: _themeMode, // ใช้ธีมที่ผู้ใช้เลือก
      home: WeatherScreen(
        onThemeChange: changeTheme,
        preferredProvince:
            _preferredProvince, // ส่งข้อมูล province ที่ผู้ใช้เลือกไปยัง WeatherScreen
        onAnimationSelected: (String selectedAnimationUrl) {
          // คุณสามารถใช้ selectedAnimationUrl ตรงนี้ หรือเก็บไว้ใน state ก็ได้
          print("Selected animation URL: $selectedAnimationUrl");
        },
      ),
      routes: AppRoutes.routes, // นำเส้นทางทั้งหมดมาจากไฟล์ routes.dart
    );
  }
}
