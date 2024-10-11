import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // นำเข้า Flutter สำหรับ ThemeMode

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงการตั้งค่าผู้ใช้จาก collection 'userSettings'
  static Future<Map<String, dynamic>> getUserSettings(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('userSettings').doc(uid).get();
    return userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};
  }

  // อัปเดตธีมของผู้ใช้ลงใน collection 'userSettings'
  static Future<void> updateTheme(String uid, ThemeMode themeMode) async {
    await _firestore.collection('userSettings').doc(uid).set({
      'theme': themeMode.toString().split('.').last,
    }, SetOptions(merge: true));
  }

  // อัปเดตจังหวัดโปรดของผู้ใช้ใน collection 'userSettings'
  static Future<void> updatePreferredProvince(
      String uid, String province) async {
    await _firestore.collection('userSettings').doc(uid).set({
      'preferredProvince': province,
    }, SetOptions(merge: true));
  }

  // ฟังก์ชันอัปเดต URL ของภาพเคลื่อนไหวที่เลือก
  static Future<void> updateSelectedAnimation(
      String uid, String animationUrl) async {
    await _firestore.collection('userSettings').doc(uid).set({
      'selectedAnimation': animationUrl, // อัปเดต URL ของภาพเคลื่อนไหว
    }, SetOptions(merge: true));
  }
}
