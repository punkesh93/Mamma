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

    if (auth.userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Tracker History')),
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
            return const Center(child: Text('No records found. Start tracking!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E8B72),
                    child: Text('W${record.gestationalWeeks}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(DateFormat.yMMMd().format(DateTime.parse(record.timestamp))),
                  subtitle: Text("BP: ${record.bloodPressureSystolic ?? '--'}/${record.bloodPressureDiastolic ?? '--'} • Wt: ${record.currentWeightKg}kg"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDetails(context, record),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
