class WaterQualityData {
  WaterQualityData({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.pH,
    required this.dissolvedOxygen,
    required this.salinity,
    this.location,
  });

  factory WaterQualityData.fromJson(Map<String, dynamic> json) => WaterQualityData(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    temperature: (json['temperature'] as num).toDouble(),
    pH: (json['pH'] as num).toDouble(),
    dissolvedOxygen: (json['dissolvedOxygen'] as num).toDouble(),
    salinity: (json['salinity'] as num).toDouble(),
    location: json['location'] as String?,
  );
  final String id;
  final DateTime timestamp;
  final double temperature;
  final double pH;
  final double dissolvedOxygen;
  final double salinity;
  final String? location;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'temperature': temperature,
    'pH': pH,
    'dissolvedOxygen': dissolvedOxygen,
    'salinity': salinity,
    'location': location,
  };

  @override
  String toString() =>
      'WaterQualityData(id: $id, temp: $temperature°C, pH: $pH, DO: $dissolvedOxygen, salinity: $salinity)';
}
