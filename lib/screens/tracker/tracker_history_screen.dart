import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../models/health_metrics_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackerHistoryScreen extends StatelessWidget {
  const TrackerHistoryScreen({super.key});

  void _showDetails(BuildContext context, HealthRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Week ${record.gestationalWeeks} Record', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Logged on: ${DateFormat.yMMMd().format(DateTime.parse(record.timestamp))}'),
                  const Divider(height: 32),
                  const Text('AI Analysis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: record.aiAnalysis,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.plusJakartaSans(height: 1.6, fontSize: 14),
                      strong: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tracker = Provider.of<TrackerProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (auth.userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFAFBFA),
      appBar: AppBar(
        title: Text(
          'Journey Logs',
          style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: isDark ? Colors.white : const Color(0xFF1A1A3E)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : const Color(0xFF1A1A3E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<HealthRecord>>(
        stream: tracker.getHealthRecords(auth.userData!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.history_edu, size: 64, color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3)),
                   const SizedBox(height: 16),
                   Text('No logs yet', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? Colors.white38 : Colors.grey)),
                   const SizedBox(height: 8),
                   Text('Start tracking your vitals to see them here.', style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final date = DateTime.parse(record.timestamp);
              
              return IntrinsicHeight(
                child: Row(
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE8748A),
                            boxShadow: [BoxShadow(color: const Color(0xFFE8748A).withOpacity(0.4), blurRadius: 8)],
                          ),
                        ),
                        if (index != records.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: const Color(0xFFE8748A).withOpacity(0.15),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: () => _showDetails(context, record),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03)),
                              boxShadow: isDark ? [] : [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Week ${record.gestationalWeeks}',
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: 18,
                                        color: const Color(0xFFE8748A),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd').format(date),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: isDark ? Colors.white38 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildSmallMetric(Icons.favorite_outline, '${record.bloodPressureSystolic}/${record.bloodPressureDiastolic}', isDark),
                                    const SizedBox(width: 16),
                                    _buildSmallMetric(Icons.scale_outlined, '${record.currentWeightKg}kg', isDark),
                                  ],
                                ),
                                if (record.aiAnalysis.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E8B72).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2E8B72)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Analysis Ready',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E8B72)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSmallMetric(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.grey),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF1A1A3E),
          ),
        ),
      ],
    );
  }
}
