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

class AppLayoutWrapper extends StatelessWidget {
  final Widget child;

  const AppLayoutWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      extendBody: true,
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
          Positioned(
            top: -50,
            left: -50,
            child: _buildBlob(const Color(0xFF2E8B72).withOpacity(isDark ? 0.2 : 0.4)),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlob(const Color(0xFF2A7A90).withOpacity(isDark ? 0.2 : 0.4)),
          ),
          Positioned(
            bottom: 0,
            left: 50,
            child: _buildBlob(const Color(0xFF6B4B9A).withOpacity(isDark ? 0.2 : 0.4)),
          ),
          SafeArea(child: child),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: const Color(0xFF6B4B9A),
        elevation: 4,
        child: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(context, location),
    );
  }

  Widget _buildBlob(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String location) {
    int getIndex(String loc) {
      if (loc == '/') return 0;
      if (loc == '/journey') return 1;
      if (loc == '/tracker') return 2;
      if (loc == '/wellness') return 3;
      if (loc == '/profile') return 4;
      return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/journey');
          break;
        case 2:
          context.go('/tracker');
          break;
        case 3:
          context.go('/wellness');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: getIndex(location),
        onTap: onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.heart_fill), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.child_care), label: 'JOURNEY'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.graph_square_fill), label: 'TRACKER'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.sparkles), label: 'WELLNESS'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_fill), label: 'PROFILE'),
        ],
      ),
    );
  }
}