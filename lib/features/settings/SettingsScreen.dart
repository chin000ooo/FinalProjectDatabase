import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/Login.dart';
import 'ThemeSelectionScreen.dart'; // Import ThemeSelectionScreen
import '/services/user_service.dart'; // Import UserService
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:path/path.dart' as path; // สำหรับการจัดการชื่อไฟล์

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChange;
  final Function(String) onAnimationSelected; // Callback สำหรับแอนิเมชัน

  const SettingsScreen({
    super.key,
    required this.onThemeChange,
    required this.onAnimationSelected, // Callback สำหรับแอนิเมชัน
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  String? _selectedProvince;
  ThemeMode _currentTheme = ThemeMode.system;
  String? selectedAnimationUrl; // ตัวแปรเก็บ URL ของภาพเคลื่อนไหวที่เลือก

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    setState(() {
      _user = FirebaseAuth.instance.currentUser;
    });
    if (_user != null) {
      _loadUserSettings();
    }
  }

  Future<void> _loadUserSettings() async {
    if (_user != null) {
      Map<String, dynamic> settings =
          await UserService.getUserSettings(_user!.uid);
      setState(() {
        _selectedProvince = settings['preferredProvince'];
        _currentTheme = _parseThemeMode(settings['theme']);
        selectedAnimationUrl =
            settings['selectedAnimation']; // โหลด URL ของภาพเคลื่อนไหว
      });
      widget.onThemeChange(_currentTheme);
    }
  }

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

  Future<void> _updateThemeInFirestore(ThemeMode themeMode) async {
    if (_user != null) {
      await UserService.updateTheme(_user!.uid, themeMode);
    }
  }

  Future<void> _updateProvinceInFirestore(String province) async {
    if (_user != null) {
      await UserService.updatePreferredProvince(_user!.uid, province);
    }
  }

  Future<List<String>> _fetchAnimationFiles() async {
    List<String> fileNames = [];
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      ListResult result = await storage.ref('animation').listAll();
      for (Reference ref in result.items) {
        fileNames.add(ref.name);
      }
    } catch (e) {
      print('Error fetching files: $e');
    }
    return fileNames;
  }

  void _showAnimationFiles(BuildContext context) async {
    List<String> animationFiles = await _fetchAnimationFiles();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Animation File'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: animationFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(path.basenameWithoutExtension(animationFiles[
                      index])), // ใช้ path.basenameWithoutExtension เพื่อแสดงชื่อไฟล์โดยไม่มีนามสกุล
                  onTap: () async {
                    String selectedFileUrl = await FirebaseStorage.instance
                        .ref('animation/${animationFiles[index]}')
                        .getDownloadURL();

                    setState(() {
                      selectedAnimationUrl = selectedFileUrl;
                    });

                    // อัปเดต URL ของภาพเคลื่อนไหวใน Firestore
                    await UserService.updateSelectedAnimation(
                        _user!.uid, selectedFileUrl);

                    // ส่ง URL ของแอนิเมชันกลับไปยัง WeatherScreen
                    widget.onAnimationSelected(selectedFileUrl);

                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
    });
    print('User has logged out.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(_user == null ? Icons.login : Icons.logout),
            title: Text(_user == null ? 'Login' : 'Logout'),
            onTap: () async {
              if (_user == null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(onLoginSuccess: () {
                      setState(() {
                        _user = FirebaseAuth.instance.currentUser;
                        _loadUserSettings();
                      });
                    }),
                  ),
                );
                if (result == true) {
                  _checkLoginStatus();
                }
              } else {
                _handleLogout();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThemeSelectionScreen(
                    onThemeSelected: (ThemeMode mode) {
                      setState(() {
                        _currentTheme = mode;
                      });
                      widget.onThemeChange(mode);
                      _updateThemeInFirestore(mode);
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Set Favorite Province'),
            subtitle: Text(_selectedProvince ?? 'Select your province'),
            onTap: () {
              _selectProvince(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.animation),
            title: const Text('Animation Files'),
            onTap: () {
              _showAnimationFiles(context);
            },
          ),
        ],
      ),
    );
  }

  void _selectProvince(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Province'),
          content: DropdownButton<String>(
            value: _selectedProvince,
            onChanged: (String? newValue) {
              setState(() {
                _selectedProvince = newValue;
                _updateProvinceInFirestore(newValue!);
              });
              Navigator.of(context).pop();
            },
            items: <String>[
              'กรุงเทพมหานคร',
              'กระบี่',
              'กาญจนบุรี',
              'กาฬสินธุ์',
              'กำแพงเพชร',
              'ขอนแก่น',
              'จันทบุรี',
              'ฉะเชิงเทรา',
              'ชลบุรี',
              'ชัยนาท',
              'ชัยภูมิ',
              'ชุมพร',
              'เชียงใหม่',
              'เชียงราย',
              'ตรัง',
              'ตราด',
              'ตาก',
              'นครนายก',
              'นครปฐม',
              'นครพนม',
              'นครราชสีมา',
              'นครศรีธรรมราช',
              'นครสวรรค์',
              'นนทบุรี',
              'นราธิวาส',
              'น่าน',
              'บึงกาฬ',
              'บุรีรัมย์',
              'ปทุมธานี',
              'ประจวบคีรีขันธ์',
              'ปราจีนบุรี',
              'ปัตตานี',
              'พระนครศรีอยุธยา',
              'พังงา',
              'พัทลุง',
              'พิจิตร',
              'พิษณุโลก',
              'เพชรบุรี',
              'เพชรบูรณ์',
              'แพร่',
              'พะเยา',
              'ภูเก็ต',
              'มหาสารคาม',
              'มุกดาหาร',
              'แม่ฮ่องสอน',
              'ยะลา',
              'ยโสธร',
              'ร้อยเอ็ด',
              'ระนอง',
              'ระยอง',
              'ราชบุรี',
              'ลพบุรี',
              'ลำปาง',
              'ลำพูน',
              'เลย',
              'ศรีสะเกษ',
              'สกลนคร',
              'สงขลา',
              'สตูล',
              'สมุทรปราการ',
              'สมุทรสงคราม',
              'สมุทรสาคร',
              'สระแก้ว',
              'สระบุรี',
              'สิงห์บุรี',
              'สุโขทัย',
              'สุพรรณบุรี',
              'สุราษฎร์ธานี',
              'สุรินทร์',
              'หนองคาย',
              'หนองบัวลำภู',
              'อ่างทอง',
              'อุดรธานี',
              'อุทัยธานี',
              'อุตรดิตถ์',
              'อุบลราชธานี',
              'อำนาจเจริญ'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
