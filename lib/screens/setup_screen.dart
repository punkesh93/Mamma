import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _step = 1;
  final _formData = <String, dynamic>{
    'name': '',
    'country': 'US',
    'region': 'US',
    'lastPeriodDate': '',
    'testDate': '',
    'quietMode': false,
    'units': 'imperial',
    'plan': 'trial',
    'streakDays': 0,
    'totalPoints': 0,
    'isPartnerAccount': false,
    'partnerEmail': '',
  };

  final _nameController = TextEditingController();

  // Daily goals defaults
  final _dailyGoals = {
    'calories': 2200,
    'protein': 75,
    'water': 2500,
    'walking': 5000,
    'iron': 27,
    'calcium': 1000,
  };

  final _achievedToday = {
    'calories': 0,
    'protein': 0,
    'water': 0,
    'walking': 0,
    'iron': 0,
    'calcium': 0,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int _calcCurrentWeek(String? lastPeriod, String? testDate) {
    if (lastPeriod == null || lastPeriod.isEmpty) return 8;
    try {
      final lmp = DateTime.parse(lastPeriod);
      final days = DateTime.now().difference(lmp).inDays;
      final week = (days / 7).floor();
      return week.clamp(1, 40);
    } catch (_) {
      return 8;
    }
  }

  String _calcDueDate(String? lastPeriod, String? testDate) {
    if (lastPeriod == null || lastPeriod.isEmpty) {
      final due = DateTime.now().add(const Duration(days: 280));
      return due.toIso8601String().split('T')[0];
    }
    try {
      final lmp = DateTime.parse(lastPeriod);
      final due = lmp.add(const Duration(days: 280));
      return due.toIso8601String().split('T')[0];
    } catch (_) {
      final due = DateTime.now().add(const Duration(days: 280));
      return due.toIso8601String().split('T')[0];
    }
  }

  Future<void> _handleComplete() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final firebaseUser = auth.firebaseUser;

    if (firebaseUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
      }
      return;
    }

    // Calculate week and due date
    final currentWeek = _calcCurrentWeek(
      _formData['lastPeriodDate'] as String?,
      _formData['testDate'] as String?,
    );
    final dueDate = _calcDueDate(
      _formData['lastPeriodDate'] as String?,
      _formData['testDate'] as String?,
    );

    // Create user model
    final userModel = UserModel(
      uid: firebaseUser.uid,
      name: _formData['name'] as String? ?? 'Mama',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL ?? '',
      lastPeriodDate: _formData['lastPeriodDate'] as String?,
      testDate: _formData['testDate'] as String?,
      dueDate: dueDate,
      currentWeek: currentWeek,
      country: _formData['country'] as String? ?? 'US',
      language: 'en',
      streakDays: 0,
      totalPoints: 0,
      plan: 'trial',
      trialStartDate: DateTime.now().toIso8601String(),
      quietMode: _formData['quietMode'] as bool? ?? false,
      units: _formData['units'] as String? ?? 'imperial',
      createdAt: DateTime.now().toIso8601String(),
      region: _formData['region'] as String? ?? 'US',
      isPartnerAccount: _formData['isPartnerAccount'] as bool? ?? false,
      partnerEmail: _formData['partnerEmail'] as String?,
      dailyGoals: DailyGoals.fromJson(_dailyGoals),
      achievedToday: DailyGoals.fromJson(_achievedToday),
    );

    // Save to Firestore via auth provider
    try {
      await auth.saveUserData(userModel);
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const rose = Color(0xFFE8748A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Let's get to know you!",
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        Text(
          "Personalize your experience with MammaBuddy",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 48),

        // Account Type
        _buildSubtitle('WHO IS USING THE APP?', isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRoleCard('Mother 🌸', false, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildRoleCard('Partner 🤝', true, isDark)),
          ],
        ),
        const SizedBox(height: 32),

        // Name input
        _buildSubtitle('WHAT SHOULD WE CALL YOU?', isDark),
        const SizedBox(height: 12),
        _buildNameField(isDark),
        const SizedBox(height: 32),

        // Region selector
        _buildSubtitle('REGION & UNITS', isDark),
        const SizedBox(height: 12),
        _buildRegionSelector(isDark),
        const SizedBox(height: 48),

        // Continue button
        _buildPrimaryButton('Continue', () => setState(() => _step = 2), rose),
      ],
    );
  }

  Widget _buildRoleCard(String label, bool isPartner, bool isDark) {
    final isSelected = _formData['isPartnerAccount'] == isPartner;
    const rose = Color(0xFFE8748A);

    return GestureDetector(
      onTap: () => setState(() => _formData['isPartnerAccount'] = isPartner),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected 
              ? rose.withOpacity(0.1) 
              : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? rose : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(
              color: isSelected ? rose : (isDark ? Colors.white70 : const Color(0xFF1A1A3E)),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 16,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : const Color(0xFF5C5470).withOpacity(0.6),
      ),
    );
  }

  Widget _buildNameField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: _nameController,
        onChanged: (v) => _formData['name'] = v,
        style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : const Color(0xFF1A1A3E)),
        decoration: InputDecoration(
          hintText: 'Enter your name',
          hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person_outline, color: isDark ? Colors.white38 : Colors.grey, size: 20),
        ),
      ),
    );
  }

  Widget _buildRegionSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: DropdownButtonFormField<String>(
        value: _formData['region'] as String? ?? 'US',
        style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : const Color(0xFF1A1A3E)),
        decoration: const InputDecoration(border: InputBorder.none),
        dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        items: const [
          DropdownMenuItem(value: 'US', child: Text('United States (Oz / Lb / USD)')),
          DropdownMenuItem(value: 'EU', child: Text('Europe (Gm / Kg / EUR)')),
          DropdownMenuItem(value: 'IN', child: Text('India (Gm / Kg / INR)')),
        ],
        onChanged: (val) {
          setState(() {
            _formData['region'] = val;
            _formData['units'] = val == 'US' ? 'imperial' : 'metric';
          });
        },
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPartner = _formData['isPartnerAccount'] == true;
    const rose = Color(0xFFE8748A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isPartner ? 'Link Accounts' : 'Timeline Details',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        Text(
          isPartner ? "Connect with her MammaBuddy profile" : "Tell us about your miracle journey",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 48),

        if (isPartner) ...[
          _buildSubtitle("MOTHER'S EMAIL", isDark),
          const SizedBox(height: 12),
          _buildTextField('partnerEmail', "Enter her email address", Icons.alternate_email, isDark),
        ] else ...[
          _buildSubtitle('LAST PERIOD DATE', isDark),
          const SizedBox(height: 12),
          _buildDatePicker('lastPeriodDate', isDark),
          const SizedBox(height: 32),
          _buildSubtitle('POSITIVE TEST DATE (OPTIONAL)', isDark),
          const SizedBox(height: 12),
          _buildDatePicker('testDate', isDark),
        ],

        const SizedBox(height: 64),
        Row(
          children: [
            Expanded(child: _buildSecondaryButton('Back', () => setState(() => _step = 1), isDark)),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                'Next Step',
                () {
                  final isPartner = _formData['isPartnerAccount'] == true;
                  if (isPartner && (_formData['partnerEmail'] as String? ?? '').trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter the mother's email address."),
                        backgroundColor: Color(0xFFE8748A),
                      ),
                    );
                    return;
                  }
                  setState(() => _step = 3);
                },
                rose,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String key, String hint, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        onChanged: (v) => _formData[key] = v.trim(),
        style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : const Color(0xFF1A1A3E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white24 : Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey, size: 20),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String key, bool isDark) {
    final value = _formData[key] as String? ?? '';
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 56)),
          firstDate: DateTime.now().subtract(const Duration(days: 300)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _formData[key] = date.toIso8601String().split('T')[0];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: isDark ? Colors.white38 : Colors.grey, size: 18),
            const SizedBox(width: 12),
            Text(
              value.isEmpty ? 'Select Date' : value,
              style: GoogleFonts.plusJakartaSans(
                color: value.isEmpty ? (isDark ? Colors.white24 : Colors.grey) : (isDark ? Colors.white : const Color(0xFF1A1A3E)),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF5C5470),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const rose = Color(0xFFE8748A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Almost There',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        Text(
          "Complete your setup and start tracking",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 48),

        _buildSubtitle('PRIVACY SETTINGS', isDark),
        const SizedBox(height: 12),
        _buildQuietModeToggle(isDark),
        const SizedBox(height: 32),

        _buildSubtitle('YOUR WELCOME GIFT', isDark),
        const SizedBox(height: 12),
        _buildTrialCard(isDark),

        const SizedBox(height: 64),
        Row(
          children: [
            Expanded(child: _buildSecondaryButton('Back', () => setState(() => _step = 2), isDark)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildPrimaryButton('Experience MammaBuddy', _handleComplete, rose)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuietModeToggle(bool isDark) {
    final isQuiet = _formData['quietMode'] as bool? ?? false;
    const rose = Color(0xFFE8748A);

    return GestureDetector(
      onTap: () => setState(() => _formData['quietMode'] = !isQuiet),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isQuiet ? rose.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isQuiet ? rose : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)), width: isQuiet ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(isQuiet ? Icons.visibility_off : Icons.visibility, color: isQuiet ? rose : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiet Mode', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: isQuiet ? rose : (isDark ? Colors.white : const Color(0xFF1A1A3E)))),
                  Text('Discreet icon and private notifications', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF2E8B72).withOpacity(0.15), const Color(0xFF6B4B9A).withOpacity(0.15)]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2E8B72).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-Day Premium Trial', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A3E))),
                  Text('No credit card required today!', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explore full AI health tracking, partner mode, and all premium recipes and wellness tips instantly.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.5, color: isDark ? Colors.white38 : Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -150,
            right: -100,
            child: _buildBgBlob(const Color(0xFFE8748A).withOpacity(0.1)),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildBgBlob(const Color(0xFF2E8B72).withOpacity(0.1)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Progress
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i + 1 <= _step;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFE8748A) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 64),

                  // Step Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _step == 1
                          ? _buildStep1()
                          : _step == 2
                              ? _buildStep2()
                              : _buildStep3(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgBlob(Color color) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
