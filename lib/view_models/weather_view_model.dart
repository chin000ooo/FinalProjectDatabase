import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '/services/location_service.dart';
import '/services/weather_service.dart';

class WeatherViewModel extends ChangeNotifier {
  String? selectedProvince;
  Map<String, dynamic>? weatherData;
  String? dailyWeather;
  List<Map<String, String>> hourlyData = [];

  // Fetch current location
  Future<void> getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentLocation();
      String? province = await LocationService.getProvinceFromCoordinates(
          position.latitude, position.longitude);

      selectedProvince = province ?? 'ไม่พบจังหวัด';
      await fetchWeatherData();
      notifyListeners(); // Notify listeners after the data is fetched
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Fetch weather data based on the selected province
  Future<void> fetchWeatherData() async {
    if (selectedProvince != null) {
      var dailyResponse =
          await WeatherService.fetchDailyWeather(selectedProvince!);
      var hourlyResponse =
          await WeatherService.fetchHourlyWeather(selectedProvince!);

      if (dailyResponse != null && dailyResponse['WeatherForecasts'] != null) {
        List forecasts = dailyResponse['WeatherForecasts'][0]['forecasts'];

        DateTime today = DateTime.now();
        var todayForecast = forecasts.firstWhere(
            (forecast) => DateTime.parse(forecast['time']).day == today.day,
            orElse: () => null);

        if (todayForecast != null) {
          DateTime date = DateTime.parse(todayForecast['time']);
          String dayOfWeek = date.weekday.toString();
          int maxTemp = todayForecast['data']['tc_max'].round();
          dailyWeather = '$dayOfWeek $maxTemp°C';
        } else {
          print('No weather data found for today');
        }
      }

      if (hourlyResponse != null &&
          hourlyResponse['WeatherForecasts'] != null) {
        hourlyData =
            (hourlyResponse['WeatherForecasts'][0]['forecasts'] as List)
                .map((forecast) {
          DateTime dateTime =
              DateTime.parse(forecast['time']).toLocal(); // ใช้เวลาเป็นท้องถิ่น
          String formattedTime = "${dateTime.hour}:00";
          double temperature = forecast['data']['tc'];
          double humidity = forecast['data']['rh'];
          double windSpeed = forecast['data']['ws10m'];

          return {
            "time": formattedTime,
            "temperature": temperature.toStringAsFixed(0),
            "humidity": humidity.toStringAsFixed(0),
            "windSpeed": windSpeed.toStringAsFixed(0)
          };
        }).toList();
      }

      notifyListeners(); // Notify listeners after the weather data is updated
    }
  }

  // Method to update selected province and fetch data
  void updateSelectedProvince(String province) {
    selectedProvince = province;
    fetchWeatherData(); // Fetch new weather data when the province is updated
    notifyListeners(); // Notify listeners to update the UI
  }
}
