class HealthRecord {
  final String? id;
  final String userId;
  final String timestamp;
  final int gestationalWeeks;
  final String lmpDate;
  
  // BMI & Weight
  final double heightCm;
  final double prePregnancyWeightKg;
  final double currentWeightKg;
  
  // Vitals
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? hemoglobin; // g/dL
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  
  // Urine Tests (boolean switches)
  final bool hasProtein;
  final bool hasSugar;
  final bool hasBacteria;
  
  // Symptoms
  final String symptomsDescription;
  
  // AI Response
  final String aiAnalysis;

  HealthRecord({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.gestationalWeeks,
    required this.lmpDate,
    required this.heightCm,
    required this.prePregnancyWeightKg,
    required this.currentWeightKg,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.hemoglobin,
    this.fundalHeightCm,
    this.fetalHeartRateBpm,
    required this.hasProtein,
    required this.hasSugar,
    required this.hasBacteria,
    required this.symptomsDescription,
    required this.aiAnalysis,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json, String id) {
    return HealthRecord(
      id: id,
      userId: json['userId'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      gestationalWeeks: json['gestationalWeeks'] ?? 0,
      lmpDate: json['lmpDate'] ?? '',
      heightCm: (json['heightCm'] ?? 0).toDouble(),
      prePregnancyWeightKg: (json['prePregnancyWeightKg'] ?? 0).toDouble(),
      currentWeightKg: (json['currentWeightKg'] ?? 0).toDouble(),
      bloodPressureSystolic: json['bloodPressureSystolic'],
      bloodPressureDiastolic: json['bloodPressureDiastolic'],
      hemoglobin: json['hemoglobin']?.toDouble(),
      fundalHeightCm: json['fundalHeightCm']?.toDouble(),
      fetalHeartRateBpm: json['fetalHeartRateBpm'],
      hasProtein: json['hasProtein'] ?? false,
      hasSugar: json['hasSugar'] ?? false,
      hasBacteria: json['hasBacteria'] ?? false,
      symptomsDescription: json['symptomsDescription'] ?? '',
      aiAnalysis: json['aiAnalysis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'timestamp': timestamp,
      'gestationalWeeks': gestationalWeeks,
      'lmpDate': lmpDate,
      'heightCm': heightCm,
      'prePregnancyWeightKg': prePregnancyWeightKg,
      'currentWeightKg': currentWeightKg,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'hemoglobin': hemoglobin,
      'fundalHeightCm': fundalHeightCm,
      'fetalHeartRateBpm': fetalHeartRateBpm,
      'hasProtein': hasProtein,
      'hasSugar': hasSugar,
      'hasBacteria': hasBacteria,
      'symptomsDescription': symptomsDescription,
      'aiAnalysis': aiAnalysis,
    };
  }
}
