import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../models/health_metrics_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MaternalTrackerScreen extends StatefulWidget {
  const MaternalTrackerScreen({super.key});

  @override
  State<MaternalTrackerScreen> createState() => _MaternalTrackerScreenState();
}

class _MaternalTrackerScreenState extends State<MaternalTrackerScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestRecord();
    });
  }

  Future<void> _loadLatestRecord() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tracker = Provider.of<TrackerProvider>(context, listen: false);
    if (auth.userData != null) {
      final latest = await tracker.getLatestRecord(auth.userData!.uid);
      if (latest != null && mounted) {
        _formKey.currentState?.patchValue({
          'lmp_date': DateTime.tryParse(latest.lmpDate ?? '') ?? DateTime.now().subtract(const Duration(days: 56)),
          'height': latest.heightCm.toString(),
          'pre_weight': latest.prePregnancyWeightKg.toString(),
          'current_weight': latest.currentWeightKg.toString(),
          'bp_systolic': latest.bloodPressureSystolic.toString(),
          'bp_diastolic': latest.bloodPressureDiastolic.toString(),
          'hemoglobin': latest.hemoglobin.toString(),
          'fundal_height': latest.fundalHeightCm.toString(),
          'fhr': latest.fetalHeartRateBpm.toString(),
          'urine_protein': latest.hasProtein,
          'urine_sugar': latest.hasSugar,
          'urine_bacteria': latest.hasBacteria,
          'symptoms': latest.symptomsDescription,
        });
      }
    }
  }

  int _calculateGestationalWeeks(DateTime lmp) {
    return DateTime.now().difference(lmp).inDays ~/ 7;
  }

  void _submitData() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final tracker = Provider.of<TrackerProvider>(context, listen: false);
      final user = auth.userData;

      if (user == null) return;

      int gestWeeks = _calculateGestationalWeeks(values['lmp_date']);

      final record = HealthRecord(
        userId: user.uid,
        timestamp: DateTime.now().toIso8601String(),
        gestationalWeeks: gestWeeks,
        lmpDate: (values['lmp_date'] as DateTime).toIso8601String(),
        heightCm: double.tryParse(values['height'].toString()) ?? 0,
        prePregnancyWeightKg: double.tryParse(values['pre_weight'].toString()) ?? 0,
        currentWeightKg: double.tryParse(values['current_weight'].toString()) ?? 0,
        bloodPressureSystolic: int.tryParse(values['bp_systolic']?.toString() ?? ''),
        bloodPressureDiastolic: int.tryParse(values['bp_diastolic']?.toString() ?? ''),
        hemoglobin: double.tryParse(values['hemoglobin']?.toString() ?? ''),
        fundalHeightCm: double.tryParse(values['fundal_height']?.toString() ?? ''),
        fetalHeartRateBpm: int.tryParse(values['fhr']?.toString() ?? ''),
        hasProtein: values['urine_protein'] ?? false,
        hasSugar: values['urine_sugar'] ?? false,
        hasBacteria: values['urine_bacteria'] ?? false,
        symptomsDescription: values['symptoms'] ?? '',
        aiAnalysis: '', // Handled by provider
      );

      await tracker.analyzeHealthMetrics(record, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackerProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Maternal Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4B9A).withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestational Age', style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: const Color(0xFF1A1A3E))),
                    const SizedBox(height: 12),
                    // Educational Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8748A).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8748A).withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFE8748A), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Gestational age is simply how far along you are. It is calculated from the first day of your Last Menstrual Period (LMP) — not the day of conception!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF5C5470),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Date Picker
                    FormBuilderDateTimePicker(
                      name: 'lmp_date',
                      inputType: InputType.date,
                      initialDate: DateTime.now().subtract(const Duration(days: 56)),
                      firstDate: DateTime.now().subtract(const Duration(days: 300)),
                      lastDate: DateTime.now(),
                      decoration: InputDecoration(
                        labelText: 'Select LMP Date',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF6B4B9A)),
                        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF6B4B9A)),
                        filled: true,
                        fillColor: const Color(0xFF6B4B9A).withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: const Color(0xFF6B4B9A).withOpacity(0.5), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {}); // trigger rebuild so builder can calculate
                      },
                      validator: FormBuilderValidators.required(),
                    ),
                    // Dynamic calculations
                    Builder(
                      builder: (context) {
                        final val = _formKey.currentState?.fields['lmp_date']?.value as DateTime?;
                        if (val == null) return const SizedBox.shrink();
                        
                        int weeks = _calculateGestationalWeeks(val);
                        DateTime due = val.add(const Duration(days: 280));
                        String formattedDue = "${due.month}/${due.day}/${due.year}";
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFF6B4B9A).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Text('Current Week', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF5C5470))),
                                      const SizedBox(height: 4),
                                      Text('Week $weeks', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF6B4B9A))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: const Color(0xFF2E8B72).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Text('Est. Due Date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF5C5470))),
                                      const SizedBox(height: 4),
                                      Text(formattedDue, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2E8B72))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BMI & Weight', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderDropdown<String>(
                              name: 'height',
                              decoration: const InputDecoration(labelText: 'Height (cm)'),
                              items: List.generate(101, (index) => 100 + index)
                                  .map((h) => DropdownMenuItem(
                                        value: h.toString(),
                                        child: Text('$h cm'),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'pre_weight',
                              decoration: const InputDecoration(labelText: 'Pre-weight (kg)'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'current_weight',
                              decoration: const InputDecoration(labelText: 'Current (kg)'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blood Pressure', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'bp_systolic',
                              decoration: const InputDecoration(labelText: 'Systolic'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'bp_diastolic',
                              decoration: const InputDecoration(labelText: 'Diastolic'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Other Readings', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      FormBuilderTextField(
                        name: 'hemoglobin',
                        decoration: const InputDecoration(labelText: 'Hemoglobin (g/dL)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      FormBuilderTextField(
                        name: 'fundal_height',
                        decoration: const InputDecoration(labelText: 'Fundal Height (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      FormBuilderTextField(
                        name: 'fhr',
                        decoration: const InputDecoration(labelText: 'Fetal Heart Rate (bpm)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Urine Test Results', style: Theme.of(context).textTheme.titleLarge),
                      FormBuilderSwitch(
                        name: 'urine_protein',
                        title: const Text('Protein (preeclampsia risk)'),
                      ),
                      FormBuilderSwitch(
                        name: 'urine_sugar',
                        title: const Text('Sugar (gestational diabetes risk)'),
                      ),
                      FormBuilderSwitch(
                        name: 'urine_bacteria',
                        title: const Text('Bacteria (infection risk)'),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Symptoms', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      FormBuilderTextField(
                        name: 'symptoms',
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe symptoms: cramping, spotting, headaches...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: tracker.isAnalyzing ? null : _submitData,
                icon: tracker.isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.analytics),
                label: const Text('Analyze with MammaAI 🤱'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              if (tracker.lastAiResponse != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Card(
                    color: Theme.of(context).primaryColorLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Analysis', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          MarkdownBody(
                            data: tracker.lastAiResponse!,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.plusJakartaSans(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, height: 1.5),
                              strong: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
