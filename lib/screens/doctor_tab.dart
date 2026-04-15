import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/services/openrouter_service.dart';
import '../core/services/firestore_service.dart';
import '../providers/auth_provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _sage = Color(0xFF2E8B72);
const _sky = Color(0xFF2A7A90);
const _rose = Color(0xFFE8748A);
const _ink = Color(0xFF1A1A3E);
const _mauve = Color(0xFF5C5470);

// ── Doctor Report Model ─────────────────────────────────────────────────────
class DoctorReport {
  final String id;
  final String timestamp;
  final String photoUrl;
  final String aiAnalysis;
  final int week;

  DoctorReport({
    required this.id,
    required this.timestamp,
    required this.photoUrl,
    required this.aiAnalysis,
    required this.week,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'photoUrl': photoUrl,
    'aiAnalysis': aiAnalysis,
    'week': week,
  };

  factory DoctorReport.fromJson(Map<String, dynamic> json) => DoctorReport(
    id: json['id'],
    timestamp: json['timestamp'],
    photoUrl: json['photoUrl'],
    aiAnalysis: json['aiAnalysis'],
    week: json['week'],
  );
}

class DoctorTab extends StatefulWidget {
  final int week;

  const DoctorTab({super.key, this.week = 20});

  @override
  State<DoctorTab> createState() => _DoctorTabState();
}

class _DoctorTabState extends State<DoctorTab> {
  final OpenRouterService _aiService = OpenRouterService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  File? _pickedImage;
  String? _base64Image;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  String? _aiResponse;
  String? _analyzeError;
  bool _showHistory = false;

  // ── Pick image from gallery ───────────────────────────────────────────────
  Future<void> _handleUploadClick() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        setState(() {
          _pickedImage = File(file.path);
          _isUploading = true;
          _aiResponse = null;
          _analyzeError = null;
        });
        // Convert to base64
        final bytes = await _pickedImage!.readAsBytes();
        setState(() {
          _base64Image = base64Encode(bytes);
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _analyzeError = 'Failed to pick image: $e';
      });
    }
  }

  // ── Capture image from camera ─────────────────────────────────────────────
  Future<void> _handleCameraClick() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (file != null) {
        setState(() {
          _pickedImage = File(file.path);
          _isUploading = true;
          _aiResponse = null;
          _analyzeError = null;
        });
        final bytes = await _pickedImage!.readAsBytes();
        setState(() {
          _base64Image = base64Encode(bytes);
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _analyzeError = 'Failed to capture image: $e';
      });
    }
  }

  // ── Analyze the picked image via AI ───────────────────────────────────────
  Future<void> _handleAnalyze() async {
    if (_base64Image == null) return;

    setState(() {
      _isAnalyzing = true;
      _analyzeError = null;
    });

    try {
      final prompt = '''
      ROLE: You are Mamma Buddy, a highly supportive pregnancy companion.
      OBJECTIVE: Analyze this medical report or ultrasound image for a user in week ${widget.week} of pregnancy.
      LIMITATIONS: Explain medical terms in simple, gentle, reassuring language. Be extremely celebratory and positive!
      EXPECTATIONS: Provide 3-4 clear, encouraging sentences explaining the key takeaway from the image.
      ''';

      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!(auth.userData?.isPremium ?? false)) {
        context.push('/paywall');
        return;
      }

      final result = await _aiService.analyzeMedicalReport(
        prompt: prompt,
        base64Image: _base64Image!,
      );

      setState(() {
        _aiResponse = result;
      });
    } catch (e) {
      setState(() {
        _analyzeError = 'Failed to analyze. Please check your connection and try again.';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _saveReport() {
    if (_aiResponse != null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.userData;
      if (user == null) return;

      final now = DateTime.now();
      final report = DoctorReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: now.toIso8601String(),
        photoUrl: _pickedImage?.path ?? '',
        aiAnalysis: _aiResponse!,
        week: widget.week,
      );

      _firestoreService.saveDoctorReport(user.uid, report.toJson());

      setState(() {
        _pickedImage = null;
        _base64Image = null;
        _aiResponse = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved to My Reports 🗂️', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: _sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Reset state ────────────────────────────────────────────────────────────
  void _closeModal() {
    setState(() {
      _pickedImage = null;
      _base64Image = null;
      _aiResponse = null;
      _analyzeError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Text(
                  'Doctor Reports 🩺',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: _ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-powered insights for your peace of mind',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontStyle: FontStyle.italic, color: _mauve),
                ),
                const SizedBox(height: 24),

                // ── Understanding Your Reports ─────────────────────────────
                _buildUnderstandingCard(),
                const SizedBox(height: 20),

                // ── AI Features Info ───────────────────────────────────────
                _buildAIFeaturesInfo(),
                const SizedBox(height: 24),

                // ── My Reports History ─────────────────────────────────────
                _buildHistoryCard(),
              ],
            ),
          ),

          // ── Analysis Modal (full-screen overlay) ─────────────────────────
          if (_pickedImage != null || _isUploading)
            _buildAnalysisModal(),
        ],
      ),
    );
  }

  Widget _buildUnderstandingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sage.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _sage.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.info_outline, color: _sage, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Understanding Your Reports', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a photo of your ultrasound, blood test, or doctor\'s notes. Our AI will help explain the medical terms in simple language so you always feel informed and empowered. 🌸',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _mauve, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onPressed: _handleUploadClick,
                  icon: Icons.upload_file,
                  label: 'Upload',
                  color: _sage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  onPressed: _handleCameraClick,
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  color: _sky,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
      ),
    );
  }

  Widget _buildAIFeaturesInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_sage.withOpacity(0.08), const Color(0xFF6B4B9A).withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _sage.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6B4B9A), _rose]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Powered by GPT-4o Vision', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                Text('Understands blood reports, ultrasounds & more', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _mauve)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sage.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _showHistory = !_showHistory),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: _sage.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.folder_special, color: _sage, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Reports', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _ink)),
                        Text('Historical analyses', style: TextStyle(fontSize: 11, color: _mauve)),
                      ],
                    ),
                  ),
                  Icon(_showHistory ? Icons.expand_less : Icons.expand_more, color: _sage, size: 24),
                ],
              ),
            ),
          ),
          // History list
          if (_showHistory && user != null) ...[
            const Divider(height: 1),
            StreamBuilder(
              stream: _firestoreService.streamDoctorReports(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: _sage)),
                  );
                }
                
                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.description_outlined, color: Color(0x552E8B72), size: 48),
                        const SizedBox(height: 12),
                        Text('No reports uploaded yet.', style: GoogleFonts.plusJakartaSans(color: _mauve, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Upload your first report to see AI insights here.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final report = DoctorReport.fromJson(docs[index].data());
                    return _buildHistoryItem(report);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(DoctorReport report) {
    final date = DateTime.tryParse(report.timestamp);
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : 'Unknown';

    return ListTile(
      onTap: () => _showReportDetail(report),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: _sage.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.description, color: _sage, size: 20),
      ),
      title: Text('Report ${report.id.substring(0, 6)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('$dateStr • Week ${report.week}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _mauve)),
      trailing: const Icon(Icons.chevron_right, color: _sage, size: 20),
    );
  }

  void _showReportDetail(DoctorReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Report', style: GoogleFonts.dmSerifDisplay(color: _ink)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Week ${report.week}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _sage.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Text(report.aiAnalysis, style: GoogleFonts.plusJakartaSans(height: 1.5, fontSize: 14)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );
  }

  // ── Analysis Modal ────────────────────────────────────────────────────────
  Widget _buildAnalysisModal() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Analyze Report', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: _ink)),
                    IconButton(
                      icon: const Icon(Icons.close, color: _mauve),
                      onPressed: _closeModal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pickedImage != null
                    ? Image.file(_pickedImage!, height: 220, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        height: 220,
                        color: const Color(0xFFF5F5F5),
                        child: const Center(child: Icon(Icons.image_outlined, size: 60, color: Color(0x882E8B72))),
                      ),
                ),
                const SizedBox(height: 20),

                // State: Uploading
                if (_isUploading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _sage),
                    ),
                  ),

                // State: Error
                if (_analyzeError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_analyzeError!, style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _handleAnalyze,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Analysis'),
                    style: ElevatedButton.styleFrom(backgroundColor: _sage, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ]

                // State: Not yet analyzed
                else if (_aiResponse == null && !_isAnalyzing) ...[
                  ElevatedButton.icon(
                    onPressed: _handleAnalyze,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Analyze with Mamma Buddy AI'),
                    style: ElevatedButton.styleFrom(backgroundColor: _sage, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ]

                // State: Analyzing
                else if (_isAnalyzing) ...[
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: _sage),
                        const SizedBox(height: 16),
                        Text('Analyzing with AI...', style: GoogleFonts.plusJakartaSans(color: _mauve)),
                      ],
                    ),
                  ),
                ]

                // State: Response received
                else ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: _sage, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Insights', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: _sage, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _sage.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: _sage.withOpacity(0.15))),
                    child: Text(_aiResponse!, style: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 14, color: _ink)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('This is AI-generated guidance. Always consult your doctor.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.amber.shade900)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saveReport,
                    icon: const Icon(Icons.save),
                    label: const Text('Save to My Reports'),
                    style: ElevatedButton.styleFrom(backgroundColor: _sage, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}