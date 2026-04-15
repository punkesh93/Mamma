import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';

// Ho'oponopono affirmations
const _hooponoponoAffirmations = [
  "I love you. I'm sorry. Please forgive me. Thank you. 💜",
  "I release all negative thoughts and welcome peace into my life.",
  "I am grateful for this miracle of life growing inside me.",
  "I forgive myself and others. I choose love and healing.",
  "Thank you for another day to appreciate the gift of life.",
  "I am at peace with my past, present, and future.",
  "My body is perfect. My baby is healthy and loved.",
  "I release all fear and welcome joy and excitement.",
  "I am surrounded by love and support.",
  "Every breath I take fills me with calm and gratitude.",
];

class WellnessTab extends StatefulWidget {
  const WellnessTab({super.key});

  @override
  State<WellnessTab> createState() => _WellnessTabState();
}

class _WellnessTabState extends State<WellnessTab> with TickerProviderStateMixin {
  final OpenRouterService _aiService = OpenRouterService();
  String? _wellnessTip;
  bool _isLoadingTip = false;

  // Breathing animation
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isBreathing = false;
  int _breathingSeconds = 0;
  static const int _breathingDuration = 60; // 1 minute breathing session

  // Design Tokens
  final Color _lavender = const Color(0xFF6B4B9A);
  final Color _rose = const Color(0xFFE8748A);
  final Color _sky = const Color(0xFF2A7A90);
  final Color _sage = const Color(0xFF2E8B72);
  final Color _ink = const Color(0xFF1A1A3E);

  @override
  void initState() {
    super.initState();
    _loadDailyTip();

    // Breathing animation setup
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed && _isBreathing) {
        _breathingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _toggleBreathing() {
    setState(() {
      _isBreathing = !_isBreathing;
      if (_isBreathing) {
        _breathingController.forward();
        _startBreathingTimer();
      } else {
        _breathingController.stop();
        _breathingSeconds = 0;
      }
    });
  }

  void _startBreathingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isBreathing || !mounted) return false;
      setState(() => _breathingSeconds++);
      return _breathingSeconds < _breathingDuration && _isBreathing;
    });
  }

  Future<void> _loadDailyTip() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    if (!(user.isPremium ?? false)) {
      setState(() => _wellnessTip = _getHooponoponoAffirmation());
      return;
    }

    setState(() => _isLoadingTip = true);
    try {
      final prompt = 'You are a warm prenatal wellness coach. Give one short, actionable wellness tip for a mother in week ${user.currentWeek} of pregnancy. Focus on relaxation or gentle movement.';
      final response = await _aiService.chat(
        conversationHistory: [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': 'Give me today\'s tip.'},
        ],
        isWellnessTip: true,
      );
      setState(() => _wellnessTip = response);
    } catch (e) {
      // Use Ho'oponopono affirmation as fallback
      setState(() => _wellnessTip = _getHooponoponoAffirmation());
    } finally {
      setState(() => _isLoadingTip = false);
    }
  }

  String _getHooponoponoAffirmation() {
    final index = DateTime.now().day % _hooponoponoAffirmations.length;
    return _hooponoponoAffirmations[index];
  }

  Future<void> _openSpotifyPlaylist() async {
    final spotifyUrl = Uri.parse('https://open.spotify.com/playlist/37i9dQZF1DWTC99MCpbjP8');
    try {
      if (await canLaunchUrl(spotifyUrl)) {
        await launchUrl(spotifyUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Spotify. Please install Spotify app.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Spotify.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFFAFBFA),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background soft glow
          if (!isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rose.withOpacity(0.05),
                ),
              ).animate().fadeIn(duration: 2.seconds).scale(begin: const Offset(0.5, 0.5)),
            ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ───────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wellness Sanctuary',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 32,
                            color: isDark ? Colors.white : _ink,
                          ),
                        ),
                        Text(
                          'Find your inner peace today',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : const Color(0xFF5C5470),
                          ),
                        ),
                      ],
                    ),
                    _buildZenIcon(isDark),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Section: Daily Ritual ────────────────────────────────────
                _buildSectionHeader('Your Daily Ritual', CupertinoIcons.sparkles, _lavender, isDark),
                const SizedBox(height: 16),
                _buildAffirmationCard(isDark),
                const SizedBox(height: 32),

                // ── Section: A Moment of Calm ────────────────────────────────
                _buildSectionHeader('Sonic Peace', CupertinoIcons.music_note_2, const Color(0xFF1DB954), isDark),
                const SizedBox(height: 16),
                _buildSpotifyCard(isDark),
                const SizedBox(height: 32),

                // ── Section: Breathwork ──────────────────────────────────────
                _buildSectionHeader('Mindful Breath', CupertinoIcons.wind, _sky, isDark),
                const SizedBox(height: 16),
                _buildBreathingCard(isDark),
                const SizedBox(height: 32),

                // ── Section: Explore ─────────────────────────────────────────
                _buildSectionHeader('Guided Studio', CupertinoIcons.rectangle_grid_2x2, _sage, isDark),
                const SizedBox(height: 16),
                _buildActivityList(isDark),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZenIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _rose.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.self_improvement, color: _rose, size: 28),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white70 : _ink.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAffirmationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _lavender.withOpacity(0.2)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: _lavender.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _lavender.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('DAILY HIGHLIGHT', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: _lavender)),
              ),
              const Spacer(),
              if (_isLoadingTip)
                const CupertinoActivityIndicator(radius: 8)
              else
                IconButton(
                  onPressed: _loadDailyTip,
                  icon: Icon(Icons.refresh, size: 16, color: _lavender.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _wellnessTip ?? _getHooponoponoAffirmation(),
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              height: 1.4,
              color: isDark ? Colors.white : _ink,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildSpotifyCard(bool isDark) {
    return GestureDetector(
      onTap: _openSpotifyPlaylist,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1518005020251-58296d8ae178?auto=format&fit=crop&q=80&w=800'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Color(0xFF1DB954), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pregnancy Calm', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                  Text('Curated by MammaBuddy', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const Spacer(),
              const Icon(CupertinoIcons.music_note_2, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBreathingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _sky.withOpacity(0.1)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: _sky.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          _buildBreathingCircle(isDark),
          const SizedBox(height: 24),
          if (_isBreathing) ...[
            Text(
              _formatTime(_breathingSeconds),
              style: GoogleFonts.dmSerifDisplay(fontSize: 36, color: _sky),
            ).animate().fadeIn(),
            const SizedBox(height: 4),
            Text(
              'Synchronize your breath',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              _toggleBreathing();
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _sky,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              shadowColor: _sky.withOpacity(0.4),
            ),
            child: Text(
              _isBreathing ? 'Stop Session' : 'Start 1m Breathing',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle(bool isDark) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 140 * _breathingAnimation.value,
              height: 140 * _breathingAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _sky.withOpacity(0.3 * _breathingAnimation.value),
                    _sky.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            // Inner circle
            Container(
              width: 90 * _breathingAnimation.value,
              height: 90 * _breathingAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sky.withOpacity(0.4),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: Center(
                child: Text(
                  _breathingAnimation.value > 1.1 ? 'EXHALE' : 'INHALE',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityList(bool isDark) {
    return Column(
      children: [
        _buildImprovedActivityCard(
          'Prenatal Yoga', 
          '15 MIN • RELAXATION', 
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=800', 
          _sage,
          isDark,
        ),
        const SizedBox(height: 16),
        _buildImprovedActivityCard(
          'Bonding Meditation', 
          '10 MIN • CONNECTION', 
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&q=80&w=800', 
          _sky,
          isDark,
        ),
      ],
    );
  }

  Widget _buildImprovedActivityCard(String title, String meta, String imageUrl, Color accent, bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(meta, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: accent)),
                  const SizedBox(height: 4),
                  Text(title, style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: isDark ? Colors.white : _ink)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('START SESSION', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 10, color: isDark ? Colors.white38 : Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}