class WeatherModel {
  final double? temperature;
  final double? humidity;
  final double? windSpeed;

  WeatherModel({
    this.temperature,
    this.humidity,
    this.windSpeed,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: json['tc']?.toDouble(),
      humidity: json['rh']?.toDouble(),
      windSpeed: json['ws10m']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tc': temperature,
      'rh': humidity,
      'ws10m': windSpeed,
    };
  }
}
