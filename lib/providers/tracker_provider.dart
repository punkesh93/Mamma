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
      // Build a payload for the AI to analyze
      final payload = '''
        Patient Data:
        - Gestational Age: \${record.gestationalWeeks} weeks
        - Height: \${record.heightCm} cm
        - Pre-pregnancy weight: \${record.prePregnancyWeightKg} kg
        - Current weight: \${record.currentWeightKg} kg
        - Blood Pressure: \${record.bloodPressureSystolic}/\${record.bloodPressureDiastolic}
        - Hemoglobin: \${record.hemoglobin} g/dL
        - Fundal Height: \${record.fundalHeightCm} cm
        - Fetal Heart Rate: \${record.fetalHeartRateBpm} bpm
        - Urine Protein: \${record.hasProtein}
        - Urine Sugar: \${record.hasSugar}
        - Urine Bacteria: \${record.hasBacteria}
        - Symptoms: \${record.symptomsDescription}
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
