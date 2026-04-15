import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/tracker_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/home_tab.dart';
import 'screens/journey_tab.dart';
import 'screens/nutrition_tab.dart';
import 'screens/wellness_tab.dart';
import 'screens/profile_tab.dart';
import 'screens/doctor_tab.dart';
import 'screens/tracker/maternal_tracker_screen.dart';
import 'screens/tracker/tracker_history_screen.dart';
import 'screens/chat/ai_chat_screen.dart';

void main() async {
  // 1. Start the Flutter engine first
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load your environment variables (API Key)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Env file error: $e");
  }

  // 3. Wake up Firebase
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAyJ5GuJA-fk-OYoPW2G_8tfxFIEGlGewE",
          appId: "1:733225462613:web:44fffa9f94702629d1dddc",
          messagingSenderId: "733225462613",
          projectId: "gen-lang-client-0701710841",
          authDomain: "gen-lang-client-0701710841.firebaseapp.com",
          storageBucket: "gen-lang-client-0701710841.firebasestorage.app",
        )
      );
    } else {
      await Firebase.initializeApp();
    }

    // Tell Firestore to use your specific database name
    FirebaseFirestore.instanceFor(
      app: Firebase.app(), 
      databaseId: '(default)'
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // 4. Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
      ],
      child: const MammaBuddyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppLayoutWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeTab(),
        ),
        GoRoute(
          path: '/journey',
          builder: (context, state) => const JourneyTab(),
        ),
        GoRoute(
          path: '/nutrition',
          builder: (context, state) => const NutritionTab(),
        ),
        GoRoute(
          path: '/wellness',
          builder: (context, state) => const WellnessTab(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileTab(),
        ),
        GoRoute(
          path: '/doctor',
          builder: (context, state) => const DoctorTab(),
        ),
        GoRoute(
          path: '/tracker',
          builder: (context, state) => const MaternalTrackerScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const TrackerHistoryScreen(),
        ),
        GoRoute(
          path: '/chat',
          builder: (context, state) => const AiChatScreen(),
        ),
        GoRoute(
          path: '/partner',
          builder: (context, state) => const PartnerLinkingScreen(),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Check for logged in user
    final bool loggedIn = auth.firebaseUser != null;

    // Check if user has completed onboarding
    final bool hasUserData = auth.userData != null;

    final String location = state.uri.path;
    final bool goingToAuth = location == '/welcome' || location == '/splash' || location == '/setup';

    if (auth.isLoading) return null;

    // Flow: Splash -> Welcome -> Setup -> Home
    if (!loggedIn && !goingToAuth) {
      return '/welcome';
    }

    if (loggedIn && !hasUserData && location != '/setup') {
      return '/setup';
    }

    if (loggedIn && hasUserData && goingToAuth) {
      return '/';
    }

    return null;
  },
);

class MammaBuddyApp extends StatelessWidget {
  const MammaBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp.router(
      title: 'MammaBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}

class AppLayoutWrapper extends StatefulWidget {
  final Widget child;

  const AppLayoutWrapper({super.key, required this.child});

  @override
  State<AppLayoutWrapper> createState() => _AppLayoutWrapperState();
}

class _AppLayoutWrapperState extends State<AppLayoutWrapper> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      extendBody: true, // Allow body to flow under the bottom nav
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2E8B72), Color(0xFF6B4B9A)],
                ),
              ),
              child: const Icon(Icons.child_care, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              "MAMMA BUDDY",
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // ── Animated Background Blobs ──
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlob(const Color(0xFF2E8B72).withOpacity(isDark ? 0.1 : 0.2))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .move(begin: const Offset(-20, -20), end: const Offset(40, 40), duration: 10.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: _buildBlob(const Color(0xFF2A7A90).withOpacity(isDark ? 0.1 : 0.2))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .move(begin: const Offset(30, 0), end: const Offset(-30, 50), duration: 15.seconds, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -100,
            left: 50,
            child: _buildBlob(const Color(0xFF6B4B9A).withOpacity(isDark ? 0.1 : 0.2))
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .move(begin: const Offset(0, 30), end: const Offset(0, -30), duration: 12.seconds, curve: Curves.easeInOut),
          ),
          
          SafeArea(child: widget.child),
        ],
      ),
      floatingActionButton: location == '/chat'
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/chat'),
              backgroundColor: const Color(0xFF6B4B9A),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 20),
            ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: (location == '/chat' || location == '/setup') ? null : _buildBottomNav(context, location),
    );
  }

  Widget _buildBlob(Color color) {
    return Container(
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String location) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    int getIndex(String loc) {
      if (loc == '/') return 0;
      if (loc == '/journey') return 1;
      if (loc == '/tracker' || loc == '/history') return 2;
      if (loc == '/wellness') return 3;
      if (loc == '/profile' || loc == '/partner') return 4;
      return 0;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, CupertinoIcons.heart_fill, 'Home', getIndex(location) == 0, context),
          _buildNavItem(1, Icons.child_care_rounded, 'Baby', getIndex(location) == 1, context),
          _buildNavItem(2, CupertinoIcons.graph_square_fill, 'Vitals', getIndex(location) == 2, context),
          _buildNavItem(3, CupertinoIcons.sparkles, 'Wellness', getIndex(location) == 3, context),
          _buildNavItem(4, CupertinoIcons.person_fill, 'Profile', getIndex(location) == 4, context),
        ],
      ),
    ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isActive, BuildContext context) {
    final color = isActive ? const Color(0xFF6B4B9A) : Colors.grey.withOpacity(0.5);
    
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0: context.go('/'); break;
          case 1: context.go('/journey'); break;
          case 2: context.go('/tracker'); break;
          case 3: context.go('/wellness'); break;
          case 4: context.go('/profile'); break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: isActive ? 24 : 20),
          ),
          if (isActive)
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color))
              .animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
        ],
      ),
    );
  }
}