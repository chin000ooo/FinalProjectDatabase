import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart'; // Import สำหรับวิดีโอ
import 'package:cached_network_image/cached_network_image.dart'; // Import สำหรับ CachedNetworkImage
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/humidity_display.dart';
import '../../widgets/province_picker.dart';
import '../../widgets/temperature_display.dart';
import '../../widgets/wind_speed_display.dart';
import '../forecast/DayForecastScreen.dart';
import '../settings/SettingsScreen.dart';
import '../../models/forecast_model.dart';

class WeatherScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChange;
  final String? preferredProvince;
  final Function(String)
      onAnimationSelected; // เพิ่ม parameter onAnimationSelected

  const WeatherScreen({
    super.key,
    required this.onThemeChange,
    this.preferredProvince,
    required this.onAnimationSelected, // required onAnimationSelected
  });

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String? selectedProvince;
  Map<String, dynamic>? weatherData;
  String? dailyWeather;
  List<Map<String, String>> hourlyData = [];
  String? selectedAnimationUrl; // URL ของภาพเคลื่อนไหวที่เลือกโดยผู้ใช้
  VideoPlayerController? _controller; // สำหรับควบคุมวิดีโอ
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<String> provinces = [
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
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferredProvince();
    _loadSelectedAnimation(); // โหลด URL ของภาพเคลื่อนไหวที่ผู้ใช้เลือกจาก Firestore
  }

  @override
  void dispose() {
    // ปิด VideoPlayerController เมื่อออกจากหน้านี้
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedAnimation() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      DocumentSnapshot userDoc =
          await firestore.collection('userSettings').doc(uid).get();

      if (userDoc.exists &&
          userDoc.data() != null &&
          (userDoc.data() as Map<String, dynamic>)
              .containsKey('selectedAnimation')) {
        setState(() {
          selectedAnimationUrl = (userDoc.data() as Map<String, dynamic>)[
              'selectedAnimation']; // โหลด URL ภาพเคลื่อนไหว

          if (selectedAnimationUrl != null &&
              selectedAnimationUrl!.endsWith('.mp4')) {
            _controller = VideoPlayerController.networkUrl(
                Uri.parse(selectedAnimationUrl!))
              ..initialize().then((_) {
                setState(() {});
                _controller!.play(); // เล่นวิดีโออัตโนมัติ
              });
          }

          widget.onAnimationSelected(selectedAnimationUrl!);
        });
      }
    }
  }

  Future<void> _loadPreferredProvince() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      if (widget.preferredProvince == null ||
          widget.preferredProvince!.isEmpty) {
        try {
          DocumentSnapshot userDoc =
              await firestore.collection('userSettings').doc(uid).get();

          if (userDoc.exists && userDoc['preferredProvince'] != null) {
            setState(() {
              selectedProvince = userDoc['preferredProvince'];
            });
            _fetchWeatherData();
          } else {
            _getCurrentLocation();
          }
        } catch (e) {
          _getCurrentLocation();
        }
      } else {
        setState(() {
          selectedProvince = widget.preferredProvince;
        });
        _fetchWeatherData();
      }
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentLocation();
      String? province = await LocationService.getProvinceFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        selectedProvince = province ?? 'ไม่พบจังหวัด';
      });

      await _fetchWeatherData();
    } catch (e) {
      setState(() {
        selectedProvince = 'ไม่พบจังหวัด';
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    if (selectedProvince != null) {
      try {
        var dailyResponse =
            await WeatherService.fetchDailyWeather(selectedProvince!);
        var hourlyResponse =
            await WeatherService.fetchHourlyWeather(selectedProvince!);

        if (dailyResponse?['WeatherForecasts'] != null) {
          List forecasts = dailyResponse!['WeatherForecasts'][0]['forecasts'];
          DateTime today = DateTime.now();
          Map<String, dynamic>? todayForecast;

          try {
            todayForecast = forecasts.firstWhere(
              (forecast) => DateTime.parse(forecast['time']).day == today.day,
            );
          } catch (e) {
            todayForecast = null;
          }

          if (todayForecast != null) {
            setState(() {
              DateTime date = DateTime.parse(todayForecast!['time']);
              String dayOfWeek = DateFormat('EEEE', 'th_TH').format(date);
              var maxTempData = todayForecast['data']['tc_max'];
              int maxTemp = maxTempData != null ? maxTempData.round() : 0;
              dailyWeather = '$dayOfWeek ${maxTemp > 0 ? maxTemp : '-'}°C';
            });
          }
        }

        if (hourlyResponse?['WeatherForecasts'] != null) {
          hourlyData =
              (hourlyResponse!['WeatherForecasts'][0]['forecasts'] as List)
                  .map((forecast) {
            var hourlyForecast = ForecastModel.fromJson(forecast);
            DateTime dateTime = DateTime.parse(hourlyForecast.time).toLocal();
            String formattedTime = DateFormat("HH:mm").format(dateTime);

            double temperature = hourlyForecast.weather.temperature ?? 0.0;
            double humidity = hourlyForecast.weather.humidity ?? 0.0;
            double windSpeed = hourlyForecast.weather.windSpeed ?? 0.0;

            return {
              "time": formattedTime,
              "temperature": temperature.toStringAsFixed(0),
              "humidity": humidity.toStringAsFixed(2),
              "windSpeed": windSpeed.toStringAsFixed(2),
            };
          }).toList();

          if (hourlyData.isNotEmpty) {
            setState(() {
              weatherData = {
                "temperature": hourlyData[0]['temperature'],
                "humidity": hourlyData[0]['humidity'],
                "windSpeed": hourlyData[0]['windSpeed'],
              };
            });
          }
        }
      } catch (e) {
        print("Error fetching weather data: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double widgetHeight = screenHeight * 0.25;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      resizeToAvoidBottomInset: true, // ช่วยในการปรับหน้าจอเมื่อแป้นพิมพ์ปรากฏ
      body: SingleChildScrollView(
        // ครอบทั้งหมดด้วย SingleChildScrollView เพื่อให้เลื่อนขึ้นลงได้
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize:
                MainAxisSize.min, // ปรับขนาดของ Column ให้พอดีกับเนื้อหา
            children: [
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.03),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showProvincePicker(context),
                      child: Container(
                        width: screenWidth * 0.85,
                        height: widgetHeight,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize
                              .min, // ปรับขนาดของ Column ให้พอดีกับเนื้อหา
                          children: [
                            TemperatureDisplay(
                              temperature: weatherData?['temperature'] ?? 'N/A',
                            ),
                            Text(
                              selectedProvince != null
                                  ? '$selectedProvince\nประเทศไทย'
                                  : 'ไม่พบจังหวัด',
                              style: TextStyle(
                                fontSize: 22,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateFormat("HH:mm").format(DateTime.now()),
                              style: TextStyle(
                                fontSize: 20,
                                color: isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        color: isDarkMode ? Colors.grey.shade300 : Colors.black,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(
                                onThemeChange: widget.onThemeChange,
                                onAnimationSelected: (newAnimationUrl) {
                                  setState(() {
                                    selectedAnimationUrl = newAnimationUrl;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Flexible(
                fit: FlexFit
                    .loose, // ใช้ Flexible แทน Expanded เพื่อรองรับ ScrollView
                child: Container(
                  width: screenWidth * 0.85,
                  height: widgetHeight * 0.6,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: hourlyData.map((data) {
                          String hour = data['time']!;
                          String temperature = data['temperature']!;

                          return Column(
                            children: [
                              Text(
                                hour,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.042,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$temperature°',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.black,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.4,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ความชื้น',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey.shade300
                                : Colors.black,
                          ),
                        ),
                        HumidityDisplay(
                          humidity: weatherData?['humidity'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.05),
                  Container(
                    width: screenWidth * 0.4,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ความเร็วลม',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? Colors.grey.shade300
                                : Colors.black,
                          ),
                        ),
                        WindSpeedDisplay(
                          windSpeed: weatherData?['windSpeed'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SevenDayForecastScreen(
                            province: selectedProvince!)),
                  );
                },
                child: Container(
                  width: screenWidth * 0.85,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    dailyWeather ?? 'Loading daily data...',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Flexible(
                fit: FlexFit.loose,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: screenHeight * 0.03), // ระยะห่างจากด้านล่าง
                  child: GestureDetector(
                    child: Container(
                      width: screenWidth * 0.85,
                      height: widgetHeight * 0.999,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: selectedAnimationUrl != null
                            ? (selectedAnimationUrl!.endsWith('.mp4') &&
                                    _controller != null)
                                ? _controller!.value.isInitialized
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _controller!.value.size.width,
                                          height:
                                              _controller!.value.size.height,
                                          child: VideoPlayer(_controller!),
                                        ),
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                : CachedNetworkImage(
                                    imageUrl: selectedAnimationUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Center(
                                      child:
                                          Text('Failed to load image or video'),
                                    ),
                                  )
                            : const Center(
                                child: Text(
                                  'กรุณาเลือกภาพหรือวิดีโอจาก Settings',
                                  style: TextStyle(
                                    fontSize: 22,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvincePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          // เพิ่ม SingleChildScrollView ครอบ widget picker
          child: ProvincePicker(
            provinces: provinces,
            onProvinceSelected: (String selected) {
              setState(() {
                selectedProvince = selected;
                weatherData = null;
                dailyWeather = null;
              });
              _fetchWeatherData();
            },
          ),
        );
      },
    );
  }
}
