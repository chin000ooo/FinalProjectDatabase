import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/Login.dart';
import 'ThemeSelectionScreen.dart'; // Import ThemeSelectionScreen
import '/services/user_service.dart'; // Import UserService
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:file_picker/file_picker.dart'; // Import File Picker
import 'package:path/path.dart' as path; // สำหรับการจัดการชื่อไฟล์
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChange;
  final Function(String) onAnimationSelected; // เพิ่ม callback สำหรับแอนิเมชัน

  const SettingsScreen({
    super.key,
    required this.onThemeChange,
    required this.onAnimationSelected, // เพิ่ม callback สำหรับแอนิเมชัน
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  String? _selectedProvince;
  ThemeMode _currentTheme = ThemeMode.system;
  String? selectedAnimationUrl; // เพิ่มตัวแปรเก็บ URL ของภาพเคลื่อนไหวที่เลือก

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

  // อัปเดต URL ของภาพเคลื่อนไหวใน Firestore
  Future<void> _updateAnimationInFirestore(String animationUrl) async {
    if (_user != null) {
      await UserService.updateSelectedAnimation(_user!.uid, animationUrl);
    }
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
    });
    print('User has logged out.');
  }

  Future<void> _uploadAnimationFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      String fileName = path.basename(result.files.single.name);
      String fileExtension =
          path.extension(fileName).toLowerCase(); // ดึงนามสกุลไฟล์
      PlatformFile file = result.files.first;

      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        TaskSnapshot uploadTask =
            await storage.ref('animation/$fileName').putData(file.bytes!);

        String downloadURL = await uploadTask.ref.getDownloadURL();

        // ตรวจสอบนามสกุลไฟล์ และบันทึกชนิดไฟล์ใน Firestore
        String fileType = fileExtension == '.mp4'
            ? 'video'
            : 'image'; // ตรวจสอบไฟล์ .mp4 หรือไฟล์รูปภาพอื่น ๆ

        // อัปเดตข้อมูลไฟล์และชนิดไฟล์ลง Firestore
        await FirebaseFirestore.instance
            .collection('userSettings')
            .doc(_user!.uid)
            .set({
          'selectedAnimation': downloadURL,
          'fileType': fileType, // บันทึกประเภทของไฟล์
        });

        setState(() {
          selectedAnimationUrl = downloadURL;
        });

        // ส่ง URL ของแอนิเมชันกลับไปยัง WeatherScreen
        widget.onAnimationSelected(downloadURL); // เรียก callback

        print('File uploaded! Download URL: $downloadURL');
        print('File type: $fileType');
      } catch (e) {
        print('Failed to upload file: $e');
      }
    } else {
      print('No file selected');
    }
  }

  // ฟังก์ชันลบไฟล์จาก Storage และ Firestore
  Future<void> _deleteAnimationFile(String fileName) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      // ลบไฟล์จาก Firebase Storage
      await storage.ref('animation/$fileName').delete();

      // ลบข้อมูลที่เกี่ยวข้องใน Firestore
      await FirebaseFirestore.instance
          .collection('userSettings')
          .doc(_user!.uid)
          .update({
        'selectedAnimation': FieldValue.delete(),
        'fileType': FieldValue.delete(),
      });

      setState(() {
        selectedAnimationUrl = null; // รีเซ็ต URL ของภาพเคลื่อนไหว
      });

      print('File deleted successfully!');
    } catch (e) {
      print('Failed to delete file: $e');
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
                  title: Text(animationFiles[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      // ยืนยันก่อนลบ
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this file?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true) {
                        await _deleteAnimationFile(animationFiles[index]);
                      }
                    },
                  ),
                  onTap: () async {
                    String selectedFileUrl = await FirebaseStorage.instance
                        .ref('animation/${animationFiles[index]}')
                        .getDownloadURL();

                    setState(() {
                      selectedAnimationUrl = selectedFileUrl;
                    });

                    // อัปเดต URL ของภาพเคลื่อนไหวใน Firestore
                    await _updateAnimationInFirestore(selectedFileUrl);

                    // ส่ง URL ของแอนิเมชันกลับไปยัง WeatherScreen
                    widget
                        .onAnimationSelected(selectedFileUrl); // เรียก callback

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
            leading: const Icon(Icons.add_photo_alternate),
            title: const Text('Add Picture Animation'),
            onTap: () {
              _uploadAnimationFile();
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
