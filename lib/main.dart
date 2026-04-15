import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// No firebase options
import 'providers/auth_provider.dart';
import 'providers/tracker_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/home_tab.dart';
import 'screens/nutrition_tab.dart';
import 'screens/wellness_tab.dart';
import 'screens/profile_tab.dart';
import 'screens/tracker/maternal_tracker_screen.dart';
import 'screens/chat/ai_chat_screen.dart';
import 'screens/paywall_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. AI features may not work.");
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Request notification permissions
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Error requesting notification permissions: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MammaBuddyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const SetupScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const AppLayoutWrapper(child: HomeTab()),
    ),
    GoRoute(
      path: '/nutrition',
      builder: (context, state) => const AppLayoutWrapper(child: NutritionTab()),
    ),
    GoRoute(
      path: '/wellness',
      builder: (context, state) => const AppLayoutWrapper(child: WellnessTab()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const AppLayoutWrapper(child: ProfileTab()),
    ),
    GoRoute(
      path: '/tracker',
      builder: (context, state) => const MaternalTrackerScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);

class MammaBuddyApp extends StatelessWidget {
  const MammaBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp.router(
      title: 'Mamma Buddy',
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8748A),
          primary: const Color(0xFFE8748A),
          secondary: const Color(0xFF2E8B72),
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFAFBFA),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8748A),
          brightness: Brightness.dark,
          primary: const Color(0xFFE8748A),
          secondary: const Color(0xFF2E8B72),
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      themeMode: themeProvider.themeMode,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.firebaseUser == null) {
      context.go('/onboarding');
    } else {
      await authProvider.reloadUser();
      if (!mounted) return;
      if (authProvider.userData == null) {
        context.go('/setup');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌸', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AppLayoutWrapper extends StatelessWidget {
  final Widget child;
  const AppLayoutWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: Stack(
        children: [
          // Background blobs for consistency
          Positioned(
            top: -100,
            right: -100,
            child: _buildBgBlob(const Color(0xFFE8748A).withOpacity(isDark ? 0.1 : 0.05)),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBgBlob(const Color(0xFF2E8B72).withOpacity(isDark ? 0.1 : 0.05)),
          ),
          
          child,
          
          // Custom Bottom Navigation Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, Icons.home_rounded, '/', location == '/', isDark),
                    _buildNavItem(context, Icons.restaurant_menu_rounded, '/nutrition', location == '/nutrition', isDark),
                    const SizedBox(width: 40), // Space for FAB
                    _buildNavItem(context, Icons.spa_rounded, '/wellness', location == '/wellness', isDark),
                    _buildNavItem(context, Icons.person_rounded, '/profile', location == '/profile', isDark),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Action Button Center
          Positioned(
            bottom: 45,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: () => context.push('/chat'),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8748A), Color(0xFF6B4B9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8748A).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String path, bool isActive, bool isDark) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive 
                ? const Color(0xFFE8748A) 
                : (isDark ? Colors.white38 : const Color(0xFFB0A8C0)),
            size: 26,
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFE8748A),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBgBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}