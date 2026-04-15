import 'package:flutter/material.dart';
import '../core/services/openrouter_service.dart';
import '../core/services/firestore_service.dart';
import '../models/health_metrics_model.dart';
import '../models/user_model.dart';

class TrackerProvider extends ChangeNotifier {
  final OpenRouterService _openRouterService = OpenRouterService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  String? _lastAiResponse;
  String? get lastAiResponse => _lastAiResponse;

  Future<void> analyzeHealthMetrics(HealthRecord record, UserModel user) async {
    _isAnalyzing = true;
    _lastAiResponse = null;
    notifyListeners();

    try {
      // Calculate BMI and Weight Gain
      double heightM = record.heightCm / 100;
      double preBmi = record.prePregnancyWeightKg / (heightM * heightM);
      double weightGain = record.currentWeightKg - record.prePregnancyWeightKg;

      final payload = '''
        USER PROFILE:
        - Gestational Age: ${record.gestationalWeeks} weeks
        - Height: ${record.heightCm} cm
        - Pre-pregnancy weight: ${record.prePregnancyWeightKg} kg
        - Pre-pregnancy BMI: ${preBmi.toStringAsFixed(1)}
        - Current weight: ${record.currentWeightKg} kg
        - Total weight gain: ${weightGain.toStringAsFixed(1)} kg
        
        VITALS & CLINICAL:
        - Blood Pressure: ${record.bloodPressureSystolic}/${record.bloodPressureDiastolic}
        - Hemoglobin: ${record.hemoglobin ?? 'N/A'} g/dL
        - Fundal Height: ${record.fundalHeightCm ?? 'N/A'} cm
        - FHR (Fetal Heart Rate): ${record.fetalHeartRateBpm ?? 'N/A'} bpm
        
        SCREENINGS:
        - Urine Protein: ${record.hasProtein ? 'PRESENT' : 'ABSENT'}
        - Urine Sugar: ${record.hasSugar ? 'PRESENT' : 'ABSENT'}
        - Urine Bacteria: ${record.hasBacteria ? 'PRESENT' : 'ABSENT'}
        
        SYMPTOMS:
        - ${record.symptomsDescription.isEmpty ? "None reported" : record.symptomsDescription}
      ''';

      final aiAnalysis = await _openRouterService.analyzeMaternalMetrics(metricsPayload: payload);
      _lastAiResponse = aiAnalysis;

      // Save to Firebase
      final completeRecord = HealthRecord(
        userId: record.userId,
        timestamp: record.timestamp,
        gestationalWeeks: record.gestationalWeeks,
        lmpDate: record.lmpDate,
        heightCm: record.heightCm,
        prePregnancyWeightKg: record.prePregnancyWeightKg,
        currentWeightKg: record.currentWeightKg,
        bloodPressureSystolic: record.bloodPressureSystolic,
        bloodPressureDiastolic: record.bloodPressureDiastolic,
        hemoglobin: record.hemoglobin,
        fundalHeightCm: record.fundalHeightCm,
        fetalHeartRateBpm: record.fetalHeartRateBpm,
        hasProtein: record.hasProtein,
        hasSugar: record.hasSugar,
        hasBacteria: record.hasBacteria,
        symptomsDescription: record.symptomsDescription,
        aiAnalysis: aiAnalysis,
      );

      await _firestoreService.saveHealthRecord(completeRecord);

      // Save analysis record generic collection as well (part 9 rule)
      await _firestoreService.saveAiAnalysis(user.uid, "Maternal Metrics", payload, aiAnalysis);

    } catch (e) {
      _lastAiResponse = "Error analyzing metrics. Please try again.";
      rethrow;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Stream<List<HealthRecord>> getHealthRecords(String userId) {
    return _firestoreService.streamHealthRecords(userId);
  }

  Future<HealthRecord?> getLatestRecord(String userId) async {
    try {
      final records = await _firestoreService.streamHealthRecords(userId).first;
      return records.isNotEmpty ? records.first : null;
    } catch (e) {
      return null;
    }
  }
}
