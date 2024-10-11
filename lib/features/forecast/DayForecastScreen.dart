import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart'; // สำหรับจัดการวันที่ในท้องถิ่น
import 'package:intl/intl.dart';

import '/widgets/province_picker.dart'; // Import ProvincePicker

class SevenDayForecastScreen extends StatefulWidget {
  final String province;

  const SevenDayForecastScreen({super.key, required this.province});

  @override
  _SevenDayForecastScreenState createState() => _SevenDayForecastScreenState();
}

class _SevenDayForecastScreenState extends State<SevenDayForecastScreen> {
  List<Map<String, String>> forecastData = [];
  String? selectedProvince;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null); // Initialize date formatting
    selectedProvince = widget.province;
    fetchSevenDayForecast(selectedProvince!);
  }

  Future<void> fetchSevenDayForecast(String province) async {
    DateTime now = DateTime.now();
    String date = DateFormat("yyyy-MM-dd").format(now);
    String url =
        'https://data.tmd.go.th/nwpapi/v1/forecast/location/daily/place?province=$province&date=$date&duration=7&fields=tc_max';

    const apiKey =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImY3NDAzZjU3NTZjNTljZmI3NmViMmE3MmE4ZjE4NmE4MDU1NGEwZGM4NjJlNTI1NDgwZTk3NmRlNGE3ODBkNGFmNWRiMmNjNjk2NTk2ZGJlIn0.eyJhdWQiOiIyIiwianRpIjoiZjc0MDNmNTc1NmM1OWNmYjc2ZWIyYTcyYThmMTg2YTgwNTU0YTBkYzg2MmU1MjU0ODBlOTc2ZGU0YTc4MGQ0YWY1ZGIyY2M2OTY1OTZkYmUiLCJpYXQiOjE3MjUyMTIzMDcsIm5iZiI6MTcyNTIxMjMwNywiZXhwIjoxNzU2NzQ4MzA3LCJzdWIiOiIzNDE0Iiwic2NvcGVzIjpbXX0.SR_TtdFSx6iKbhkcmhRwnfVK3xD5Zex6cMR07wKglB4jdjdgS4_d9Imm0eiqsYFz_OttF095wYvCDbOjgpj7G-oBde4SzGhOF1DZW1CYd1lArS1HZzYNz17-JMBzj7P3CKypyzkoOyWAW9FLzldscsaZ3vzCxbyaroS6GRBRNgI1UK1CexekTwKRvFhHgQHjOxWF9aZMmN2cyR8PyNZfRunXSoZt_CgPBAR7hpSTvt7F23fYtTqI4M7UKjl7a11Qpw3szDcTgPjb8Ss-ZD3eX4eLQjGW8DzYj6B72BRoo81hPbkTKxL7DCywE9Y77NoE4DZKf59uXMwecA8AhuBvGtSYRDFJ8y_iUcqNPdDSFO39lVrj-9XKt4BdfQioV30XEGPph0gtg-TvhrUiLJhHyLt35oVt9byD3nSKjlptcVzk492VJnD-lRFWM3r_s1RhsrY9Kw6f27LRZTqq_cj6dy9eMDp4Jzci2an7EhtQeWUqqfAbdy3AuXr9MOePfnlkJrrq6Y3LgHIFMIwHIYn3L4JuVgNojPxXZXuecLOcfGkowiQjBf6QEWVsA6txtwmm6mO2XZbRVWUCL-VxRt2ZDwk8R8wZMR5e-TedWputjwIYM4Ltr9Pb88R_slJmQYqMZKRnzEh6MNNXf-9nDdRRw7VEGmIm4sgHPcXiJcEmz1c'; // Replace with your actual API key

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var forecasts = data['WeatherForecasts']?[0]?['forecasts'];

        if (forecasts != null && forecasts.isNotEmpty) {
          List<Map<String, String>> tempForecastData = [];
          for (var i = 1; i < 7; i++) {
            DateTime date =
                now.add(Duration(days: i)); // เพิ่มวันในอนาคตทีละ 1 วัน
            String dayOfWeek = DateFormat('EEEE', 'th_TH')
                .format(date); // แสดงเฉพาะวันในภาษาไทย

            int temperature = forecasts[i]['data']['tc_max'].toInt();
            tempForecastData.add({
              'date': dayOfWeek,
              'temperature': '$temperature°',
            });
          }

          setState(() {
            forecastData = tempForecastData;
          });
        } else {
          print('No forecast data available');
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching seven day forecast: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('พยากรณ์อากาศ'),
      ),
      body: Center(
        child: forecastData.isEmpty
            ? const CircularProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: forecastData.map((day) {
                  return GestureDetector(
                    onTap: () => _showProvincePicker(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 16.0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              day['date']!,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            day['temperature']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  void _showProvincePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ProvincePicker(
          provinces: const [
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
          ],
          onProvinceSelected: (String selected) {
            setState(() {
              selectedProvince = selected;
              forecastData = [];
            });
            fetchSevenDayForecast(selectedProvince!);
          },
        );
      },
    );
  }
}
