import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      dailyGoals: DailyGoals.fromJson(_dailyGoals),
      achievedToday: DailyGoals.fromJson(_achievedToday),
    );

    // Save to Firestore via auth provider
    await auth.saveUserData(userModel);

    if (mounted) {
      context.go('/');
    }
  }

  Widget _buildStep1() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Let's get to know you!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 32),

        // Name input
        Text(
          'What should we call you, Mama?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          onChanged: (v) => _formData['name'] = v,
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFE8748A).withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8748A), width: 2),
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 24),

        // Region selector
        Text(
          'Region & Units',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8748A).withOpacity(0.1),
            ),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _formData['region'] as String? ?? 'US',
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            items: const [
              DropdownMenuItem(value: 'US', child: Text('United States (Oz / Lb / USD)')),
              DropdownMenuItem(value: 'EU', child: Text('Europe (Gm / Kg / EUR)')),
              DropdownMenuItem(value: 'IN', child: Text('India (Gm / Kg / INR)')),
            ],
            onChanged: (val) {
              setState(() {
                _formData['region'] = val;
                _formData['country'] = val;
                _formData['units'] = val == 'US' ? 'imperial' : 'metric';
              });
            },
          ),
        ),
        const SizedBox(height: 40),

        // Continue button
        GestureDetector(
          onTap: () => setState(() => _step = 2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8748A), Color(0xFFF48FB1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8748A).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, duration: 300.ms);
  }

  Widget _buildStep2() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Pregnancy Details',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 32),

        // Last period date
        Text(
          'When was the first day of your last period?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 56)),
              firstDate: DateTime.now().subtract(const Duration(days: 280)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: const Color(0xFFE8748A),
                      onPrimary: Colors.white,
                      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      onSurface: isDark ? Colors.white : Colors.black87,
                    ),
                    textTheme: TextTheme(
                      headlineLarge: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      titleLarge: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                      ),
                      bodyLarge: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                      bodyMedium: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                      ),
                      labelSmall: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _formData['lastPeriodDate'] = date.toIso8601String().split('T')[0];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8748A).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formData['lastPeriodDate']?.isNotEmpty == true
                      ? _formData['lastPeriodDate']
                      : 'Select date',
                  style: TextStyle(
                    color: _formData['lastPeriodDate']?.isNotEmpty == true
                        ? (isDark ? Colors.white : const Color(0xFF1A1A3E))
                        : (isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470)),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFFE8748A), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Test date (optional)
        Text(
          'When did you get your positive test? (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 280)),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: const Color(0xFFE8748A),
                      onPrimary: Colors.white,
                      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      onSurface: isDark ? Colors.white : Colors.black87,
                    ),
                    textTheme: TextTheme(
                      headlineLarge: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      titleLarge: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                      ),
                      bodyLarge: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                      bodyMedium: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                      ),
                      labelSmall: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _formData['testDate'] = date.toIso8601String().split('T')[0];
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8748A).withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formData['testDate']?.isNotEmpty == true
                      ? _formData['testDate']
                      : 'Select date',
                  style: TextStyle(
                    color: _formData['testDate']?.isNotEmpty == true
                        ? (isDark ? Colors.white : const Color(0xFF1A1A3E))
                        : (isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470)),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFFE8748A), size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF5C5470).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF5C5470),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => setState(() => _step = 3),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8748A), Color(0xFFF48FB1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8748A).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, duration: 300.ms);
  }

  Widget _buildStep3() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isQuietMode = _formData['quietMode'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Privacy First',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Enable Quiet Mode to keep your journey private. This changes the app icon and hides pregnancy content from notifications.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
          ),
        ),
        const SizedBox(height: 24),

        // Quiet Mode Toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _formData['quietMode'] = !isQuietMode;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isQuietMode
                  ? const Color(0xFFE8748A).withOpacity(0.05)
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isQuietMode
                    ? const Color(0xFFE8748A)
                    : const Color(0xFFE8748A).withOpacity(0.1),
                width: isQuietMode ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Quiet Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A1A3E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can change this anytime in settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFB0A8C0)
                              : const Color(0xFF5C5470),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isQuietMode)
                  const Icon(
                    CupertinoIcons.check_mark_circled,
                    color: Color(0xFFE8748A),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Trial Activation Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6B4B9A).withOpacity(0.1), const Color(0xFFE8748A).withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6B4B9A).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Gift!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
                          ),
                        ),
                        Text(
                          '7-Day Premium Trial Activated',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Enjoy unlimited AI chats, meal analysis, and partner mode for 7 days. No payment required today!',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ).animate().shimmer(delay: 1.seconds, duration: 2.seconds).scale(delay: 500.ms),
        const SizedBox(height: 40),

        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _step = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF5C5470).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF5C5470),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _handleComplete,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8748A), Color(0xFFF48FB1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8748A).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Start My Journey',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.1, duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF121212),
                    const Color(0xFF1A1A3E).withOpacity(0.4),
                    const Color(0xFF2E8B72).withOpacity(0.1),
                  ]
                : [
                    const Color(0xFFFAF5F0),
                    const Color(0xFFFFE4E6).withOpacity(0.3),
                    const Color(0xFFE8EAF6).withOpacity(0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Progress indicator
                Row(
                  children: List.generate(3, (i) {
                    final isActive = i + 1 <= _step;
                    final isCurrent = i + 1 == _step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE8748A)
                              : (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),

                // Step content
                Expanded(
                  child: SingleChildScrollView(
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
      ),
    );
  }
}
