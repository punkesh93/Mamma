import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../models/health_metrics_model.dart';
import '../../models/user_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
    final user = Provider.of<AuthProvider>(context).userData;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Design Tokens
    const sage = Color(0xFF2E8B72);
    const rose = Color(0xFFE8748A);
    const sky = Color(0xFF2A7A90);
    const ink = Color(0xFF1A1A3E);

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFAFBFA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'MammaAI Vitals',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            color: isDark ? Colors.white : ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF0F0F1A), const Color(0xFF1A1A2E)]
                    : [const Color(0xFFFDFCFD), const Color(0xFFFAFBFA)],
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: Gestational Section ──────────────────────────────
                  _buildSectionHeader('Pregnancy Status', Icons.auto_awesome, sky, isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoBox(
                          'Gestational age counts from your LMP, not conception. 🌸',
                          rose,
                          isDark,
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(isDark),
                        const SizedBox(height: 20),
                        _buildDynamicMetrics(isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Section: Vitals ──────────────────────────────────────────
                  _buildSectionHeader('Body & Vitals', Icons.monitor_heart_outlined, rose, isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildMetricRow([
                          _buildTextField('height', 'Height (cm)', Icons.height, isDark, keyboardType: TextInputType.number),
                          _buildTextField('pre_weight', 'Pre-weight', Icons.fitness_center, isDark, keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 16),
                        _buildTextField('current_weight', 'Current Weight (kg)', Icons.scale, isDark, keyboardType: TextInputType.number),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        _buildMetricRow([
                          _buildTextField('bp_systolic', 'Systolic BP', Icons.favorite_outline, isDark, keyboardType: TextInputType.number),
                          _buildTextField('bp_diastolic', 'Diastolic BP', Icons.favorite_outline, isDark, keyboardType: TextInputType.number),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Section: Clinical ─────────────────────────────────────────
                  _buildSectionHeader('Clinical Readings', Icons.biotech_outlined, sage, isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildMetricRow([
                          _buildTextField('hemoglobin', 'Hb (g/dL)', Icons.bloodtype_outlined, isDark, keyboardType: TextInputType.number),
                          _buildTextField('fundal_height', 'Fundal (cm)', Icons.straighten_outlined, isDark, keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 16),
                        _buildTextField('fhr', 'Fetal Heart Rate (bpm)', Icons.favorite_rounded, isDark, keyboardType: TextInputType.number),
                        const SizedBox(height: 24),
                        _buildSwitchTile('urine_protein', 'Protein in Urine', 'Preeclampsia risk marker', isDark),
                        _buildSwitchTile('urine_sugar', 'Sugar in Urine', 'Gestational diabetes marker', isDark),
                        _buildSwitchTile('urine_bacteria', 'Infection Check', 'UTI/Bacteria marker', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Section: Symptoms ────────────────────────────────────────
                  _buildSectionHeader('Daily Symptoms', Icons.psychology_outlined, Colors.amber, isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    padding: EdgeInsets.zero,
                    child: FormBuilderTextField(
                      name: 'symptoms',
                      maxLines: 4,
                      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : ink, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Any cramping, headaches, or spotting? Describe feelings here...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.grey, fontSize: 13),
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Submit & Analyze Button ──────────────────────────────────
                  _buildAnalyzeButton(tracker, user, isDark),
                  
                  // ── AI Response Section ─────────────────────────────────────
                  if (tracker.lastAiResponse != null)
                    _buildAIAnalysisResult(tracker.lastAiResponse!, isDark),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoBox(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return FormBuilderDateTimePicker(
      name: 'lmp_date',
      inputType: InputType.date,
      decoration: InputDecoration(
        labelText: 'Last Menstrual Period Date',
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey),
        prefixIcon: Icon(Icons.calendar_month, color: isDark ? Colors.white60 : const Color(0xFF6B4B9A)),
        filled: true,
        fillColor: isDark ? Colors.black26 : const Color(0xFFF8F7FF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black, fontSize: 14),
      onChanged: (val) => setState(() {}),
    );
  }

  Widget _buildDynamicMetrics(bool isDark) {
    final val = _formKey.currentState?.fields['lmp_date']?.value as DateTime?;
    if (val == null) return const SizedBox.shrink();

    int weeks = _calculateGestationalWeeks(val);
    DateTime due = val.add(const Duration(days: 280));

    return Row(
      children: [
        Expanded(
          child: _buildCompactIndicator('Status', 'Week $weeks', const Color(0xFF6B4B9A), isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCompactIndicator('Due Date', DateFormat('MMM dd, yyyy').format(due), const Color(0xFF2E8B72), isDark),
        ),
      ],
    );
  }

  Widget _buildCompactIndicator(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(List<Widget> children) {
    return Row(
      children: children.expand((w) => [Expanded(child: w), const SizedBox(width: 16)]).toList()..removeLast(),
    );
  }

  Widget _buildTextField(String name, String label, IconData icon, bool isDark, {TextInputType? keyboardType}) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
        prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8748A))),
      ),
    );
  }

  Widget _buildSwitchTile(String name, String title, String subtitle, bool isDark) {
    return FormBuilderSwitch(
      name: name,
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A3E))),
      subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
      activeColor: const Color(0xFFE8748A),
      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
    );
  }

  Widget _buildAnalyzeButton(TrackerProvider tracker, UserModel? user, bool isDark) {
    final isPremium = user?.isPremium ?? false;

    return ElevatedButton.icon(
      onPressed: tracker.isAnalyzing ? null : () {
        if (!isPremium) {
          context.push('/paywall');
          return;
        }
        _submitData();
      },
      icon: tracker.isAnalyzing
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Icon(isPremium ? Icons.auto_awesome_rounded : Icons.lock_outline, size: 20),
      label: Text(
        isPremium ? 'Analyze with MammaAI ✨' : 'Unlock AI Health Analysis',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B4B9A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        shadowColor: const Color(0xFF6B4B9A).withOpacity(0.4),
      ),
    );
  }

  Widget _buildAIAnalysisResult(String result, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF2E8B72), size: 20),
              const SizedBox(width: 8),
              Text(
                'MammaAI Insights',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: const Color(0xFF2E8B72), fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            isDark: isDark,
            child: MarkdownBody(
              data: result,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A1A3E), height: 1.6),
                strong: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFFE8748A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
