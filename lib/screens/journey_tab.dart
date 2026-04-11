import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/auth_provider.dart';

// Copying milestone logic for the Journey tab explicitly
class BabyMilestone {
  final int week;
  final String size;
  final String weight;
  final String length;
  final String comparison;
  final String comparisonIcon;
  final String development;

  const BabyMilestone({
    required this.week,
    required this.size,
    required this.weight,
    required this.length,
    required this.comparison,
    required this.comparisonIcon,
    required this.development,
  });
}

const _babyMilestones = [
  BabyMilestone(week: 4, size: 'Poppy seed', weight: '1g', length: '0.2cm', comparison: 'Poppy seed', comparisonIcon: '🌱', development: 'The blastocyst has implanted and is starting to develop into an embryo.'),
  BabyMilestone(week: 8, size: 'Raspberry', weight: '1g', length: '1.6cm', comparison: 'Raspberry', comparisonIcon: '🍓', development: "Your baby's heart is beating, and tiny fingers and toes are forming."),
  BabyMilestone(week: 12, size: 'Lime', weight: '14g', length: '5.4cm', comparison: 'Lime', comparisonIcon: '🍋', development: 'Your baby is fully formed and starting to move, though you cannot feel it yet.'),
  BabyMilestone(week: 16, size: 'Avocado', weight: '100g', length: '11.6cm', comparison: 'Avocado', comparisonIcon: '🥑', development: "Your baby's eyes are starting to move, and they can even make a fist."),
  BabyMilestone(week: 20, size: 'Banana', weight: '300g', length: '16.4cm', comparison: 'Banana', comparisonIcon: '🍌', development: "You're halfway there! Your baby is swallowing amniotic fluid and growing hair."),
  BabyMilestone(week: 24, size: 'Corn', weight: '600g', length: '30cm', comparison: 'Ear of Corn', comparisonIcon: '🌽', development: "Your baby's lungs are developing, and they are starting to have a sleep-wake cycle."),
  BabyMilestone(week: 28, size: 'Eggplant', weight: '1kg', length: '37.6cm', comparison: 'Eggplant', comparisonIcon: '🍆', development: 'Your baby can open their eyes and see light through the womb.'),
  BabyMilestone(week: 32, size: 'Squash', weight: '1.7kg', length: '42.4cm', comparison: 'Squash', comparisonIcon: '🎃', development: 'Your baby is practicing breathing and their bones are fully developed but soft.'),
  BabyMilestone(week: 36, size: 'Papaya', weight: '2.6kg', length: '47.4cm', comparison: 'Papaya', comparisonIcon: '🍈', development: 'Your baby is gaining weight rapidly and getting ready for birth.'),
  BabyMilestone(week: 40, size: 'Watermelon', weight: '3.5kg', length: '51.2cm', comparison: 'Watermelon', comparisonIcon: '🍉', development: 'Your baby is full term and ready to meet the world!'),
];

class JourneyTab extends StatelessWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentWeek = user.currentWeek.clamp(1, 40);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Enhanced Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Journey',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 32, 
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8748A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Currently Week $currentWeek',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, 
                                  color: const Color(0xFFE8748A), 
                                  fontWeight: FontWeight.w700
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${40 - currentWeek} weeks to go',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12, 
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8748A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.heart_fill, color: Color(0xFFE8748A), size: 28),
                  ),
                ],
              ),
            ),

            // ── Timeline List ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                itemCount: _babyMilestones.length,
                itemBuilder: (context, index) {
                  final milestone = _babyMilestones[index];
                  final isPast = milestone.week < currentWeek;
                  final isCurrent = milestone.week <= currentWeek && (index == _babyMilestones.length - 1 || _babyMilestones[index + 1].week > currentWeek);
                  final isFuture = milestone.week > currentWeek;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline Connector
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCurrent || isPast ? const Color(0xFFE8748A) : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCurrent ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isCurrent ? [
                                  BoxShadow(
                                    color: const Color(0xFFE8748A).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Center(
                                child: isPast 
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : Text(
                                      '${milestone.week}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold, 
                                        color: isCurrent || isPast ? Colors.white : Colors.grey.shade500
                                      ),
                                    ),
                              ),
                            ),
                            if (index < _babyMilestones.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isPast ? const Color(0xFFE8748A).withOpacity(0.5) : Colors.grey.shade200,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Milestone Card
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrent ? Colors.white : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCurrent ? const Color(0xFFE8748A).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                  width: isCurrent ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isCurrent ? 0.05 : 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        milestone.comparisonIcon,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Size of a ${milestone.comparison}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 15, 
                                                fontWeight: FontWeight.bold, 
                                                color: isCurrent ? const Color(0xFFE8748A) : Theme.of(context).colorScheme.onSurface
                                              ),
                                            ),
                                            Text(
                                              '${milestone.weight} • ${milestone.length}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11, 
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8748A),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'NOW',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9, 
                                              color: Colors.white, 
                                              fontWeight: FontWeight.w900
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  MarkdownBody(
                                    data: milestone.development,
                                    styleSheet: MarkdownStyleSheet(
                                      p: GoogleFonts.plusJakartaSans(
                                        fontSize: 13, 
                                        height: 1.5, 
                                        color: isFuture ? Colors.grey.shade500 : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
