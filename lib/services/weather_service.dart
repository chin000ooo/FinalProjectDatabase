import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImY3NDAzZjU3NTZjNTljZmI3NmViMmE3MmE4ZjE4NmE4MDU1NGEwZGM4NjJlNTI1NDgwZTk3NmRlNGE3ODBkNGFmNWRiMmNjNjk2NTk2ZGJlIn0.eyJhdWQiOiIyIiwianRpIjoiZjc0MDNmNTc1NmM1OWNmYjc2ZWIyYTcyYThmMTg2YTgwNTU0YTBkYzg2MmU1MjU0ODBlOTc2ZGU0YTc4MGQ0YWY1ZGIyY2M2OTY1OTZkYmUiLCJpYXQiOjE3MjUyMTIzMDcsIm5iZiI6MTcyNTIxMjMwNywiZXhwIjoxNzU2NzQ4MzA3LCJzdWIiOiIzNDE0Iiwic2NvcGVzIjpbXX0.SR_TtdFSx6iKbhkcmhRwnfVK3xD5Zex6cMR07wKglB4jdjdgS4_d9Imm0eiqsYFz_OttF095wYvCDbOjgpj7G-oBde4SzGhOF1DZW1CYd1lArS1HZzYNz17-JMBzj7P3CKypyzkoOyWAW9FLzldscsaZ3vzCxbyaroS6GRBRNgI1UK1CexekTwKRvFhHgQHjOxWF9aZMmN2cyR8PyNZfRunXSoZt_CgPBAR7hpSTvt7F23fYtTqI4M7UKjl7a11Qpw3szDcTgPjb8Ss-ZD3eX4eLQjGW8DzYj6B72BRoo81hPbkTKxL7DCywE9Y77NoE4DZKf59uXMwecA8AhuBvGtSYRDFJ8y_iUcqNPdDSFO39lVrj-9XKt4BdfQioV30XEGPph0gtg-TvhrUiLJhHyLt35oVt9byD3nSKjlptcVzk492VJnD-lRFWM3r_s1RhsrY9Kw6f27LRZTqq_cj6dy9eMDp4Jzci2an7EhtQeWUqqfAbdy3AuXr9MOePfnlkJrrq6Y3LgHIFMIwHIYn3L4JuVgNojPxXZXuecLOcfGkowiQjBf6QEWVsA6txtwmm6mO2XZbRVWUCL-VxRt2ZDwk8R8wZMR5e-TedWputjwIYM4Ltr9Pb88R_slJmQYqMZKRnzEh6MNNXf-9nDdRRw7VEGmIm4sgHPcXiJcEmz1c'; // ใส่ API Key ของคุณที่นี่

  // ดึงข้อมูลพยากรณ์รายวัน
  static Future<Map<String, dynamic>?> fetchDailyWeather(
      String province) async {
    String dailyUrl =
        'https://data.tmd.go.th/nwpapi/v1/forecast/location/daily/place?province=$province&duration=7&fields=tc_max';

    try {
      final response = await http.get(
        Uri.parse(dailyUrl),
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching daily weather data: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching daily weather data: $error');
      return null;
    }
  }

  // ดึงข้อมูลพยากรณ์รายชั่วโมง
  static Future<Map<String, dynamic>?> fetchHourlyWeather(
      String province) async {
    String date = DateTime.now().toIso8601String().split('T')[0];
    String hour = DateTime.now().hour.toString();
    int startHour =
        (int.tryParse(hour) ?? 0) + 1; // บวก 1 ชั่วโมงจากเวลาปัจจุบัน

    String hourlyUrl =
        'https://data.tmd.go.th/nwpapi/v1/forecast/location/hourly/place?province=$province&date=$date&hour=$startHour&duration=6&fields=tc,rh,ws10m,wd10m';

    try {
      final response = await http.get(
        Uri.parse(hourlyUrl),
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching hourly weather data: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching hourly weather data: $error');
      return null;
    }
  }
}
