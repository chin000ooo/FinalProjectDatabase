import 'weather_model.dart';

class ForecastModel {
  final String time;
  final WeatherModel weather;

  ForecastModel({
    required this.time,
    required this.weather,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      time: json['time'],
      weather: WeatherModel.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'data': weather.toJson(),
    };
  }
}
