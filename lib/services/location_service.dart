import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _locationApiKey = 'pk.0118ee540ae83cd72685cbb10ef7cfd2';

  // ฟังก์ชันสำหรับเรียกจังหวัดจาก Latitude และ Longitude
  static Future<String?> getProvinceFromCoordinates(
      double lat, double lon) async {
    final locationUrl =
        'https://us1.locationiq.com/v1/reverse.php?key=$_locationApiKey&lat=$lat&lon=$lon&format=json';

    try {
      final response = await http.get(Uri.parse(locationUrl));
      print('Response body: ${response.body}'); // แสดงผลลัพธ์ของ Response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? province = data['address']['province'];
        print('Province: $province'); // แสดงชื่อจังหวัด

        // Map ของชื่อจังหวัดภาษาอังกฤษเป็นภาษาไทย
        Map<String, String> provinceMapping = {
          'Bangkok Province': 'กรุงเทพมหานคร',
          'Krabi Province': 'กระบี่',
          'Kanchanaburi Province': 'กาญจนบุรี',
          'Kalasin Province': 'กาฬสินธุ์',
          'Kamphaeng Phet Province': 'กำแพงเพชร',
          'Khon Kaen Province': 'ขอนแก่น',
          'Chanthaburi Province': 'จันทบุรี',
          'Chachoengsao Province': 'ฉะเชิงเทรา',
          'Chonburi Province': 'ชลบุรี',
          'Chainat Province': 'ชัยนาท',
          'Chaiyaphum Province': 'ชัยภูมิ',
          'Chumphon Province': 'ชุมพร',
          'Chiang Mai Province': 'เชียงใหม่',
          'Chiang Rai Province': 'เชียงราย',
          'Trang Province': 'ตรัง',
          'Trat Province': 'ตราด',
          'Tak Province': 'ตาก',
          'Nakhon Nayok Province': 'นครนายก',
          'Nakhon Pathom Province': 'นครปฐม',
          'Nakhon Phanom Province': 'นครพนม',
          'Nakhon Ratchasima Province': 'นครราชสีมา',
          'Nakhon Si Thammarat Province': 'นครศรีธรรมราช',
          'Nakhon Sawan Province': 'นครสวรรค์',
          'Nonthaburi Province': 'นนทบุรี',
          'Narathiwat Province': 'นราธิวาส',
          'Nan Province': 'น่าน',
          'Bueng Kan Province': 'บึงกาฬ',
          'Buri Ram Province': 'บุรีรัมย์',
          'Pathum Thani Province': 'ปทุมธานี',
          'Prachuap Khiri Khan Province': 'ประจวบคีรีขันธ์',
          'Prachin Buri Province': 'ปราจีนบุรี',
          'Pattani Province': 'ปัตตานี',
          'Phra Nakhon Si Ayutthaya Province': 'พระนครศรีอยุธยา',
          'Phangnga Province': 'พังงา',
          'Phatthalung Province': 'พัทลุง',
          'Phichit Province': 'พิจิตร',
          'Phitsanulok Province': 'พิษณุโลก',
          'Phetchaburi Province': 'เพชรบุรี',
          'Phetchabun Province': 'เพชรบูรณ์',
          'Phrae Province': 'แพร่',
          'Phayao Province': 'พะเยา',
          'Phuket Province': 'ภูเก็ต',
          'Maha Sarakham Province': 'มหาสารคาม',
          'Mukdahan Province': 'มุกดาหาร',
          'Mae Hong Son Province': 'แม่ฮ่องสอน',
          'Yala Province': 'ยะลา',
          'Yasothon Province': 'ยโสธร',
          'Roi Et Province': 'ร้อยเอ็ด',
          'Ranong Province': 'ระนอง',
          'Rayong Province': 'ระยอง',
          'Ratchaburi Province': 'ราชบุรี',
          'Lopburi Province': 'ลพบุรี',
          'Lampang Province': 'ลำปาง',
          'Lamphun Province': 'ลำพูน',
          'Loei Province': 'เลย',
          'Si Sa Ket Province': 'ศรีสะเกษ',
          'Sakon Nakhon Province': 'สกลนคร',
          'Songkhla Province': 'สงขลา',
          'Satun Province': 'สตูล',
          'Samut Prakan Province': 'สมุทรปราการ',
          'Samut Songkhram Province': 'สมุทรสงคราม',
          'Samut Sakhon Province': 'สมุทรสาคร',
          'Sa Kaeo Province': 'สระแก้ว',
          'Saraburi Province': 'สระบุรี',
          'Sing Buri Province': 'สิงห์บุรี',
          'Sukhothai Province': 'สุโขทัย',
          'Suphan Buri Province': 'สุพรรณบุรี',
          'Surat Thani Province': 'สุราษฎร์ธานี',
          'Surin Province': 'สุรินทร์',
          'Nong Khai Province': 'หนองคาย',
          'Nong Bua Lamphu Province': 'หนองบัวลำภู',
          'Ang Thong Province': 'อ่างทอง',
          'Udon Thani Province': 'อุดรธานี',
          'Uthai Thani Province': 'อุทัยธานี',
          'Uttaradit Province': 'อุตรดิตถ์',
          'Ubon Ratchathani Province': 'อุบลราชธานี',
          'Amnat Charoen Province': 'อำนาจเจริญ'
        };

        return provinceMapping[province] ?? 'ไม่พบจังหวัด';
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching location: $error');
      return null;
    }
  }

  // ฟังก์ชันสำหรับดึงตำแหน่งปัจจุบันของผู้ใช้
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
