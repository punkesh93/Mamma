import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _view = 'options'; // options, email-signup, email-login, forgot-password

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  String? _message;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _error = null;
      _message = null;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithGoogle();

      if (mounted) {
        context.go('/setup');
      }
    } catch (err) {
      String errorMsg = 'An unexpected error occurred during sign-in.';
      final errorString = err.toString().toLowerCase();

      if (errorString.contains('cancelled') || errorString.contains('popup closed')) {
        errorMsg = 'Sign-in was cancelled. Please try again.';
      } else if (errorString.contains('popup blocked')) {
        errorMsg = 'Popup was blocked by your browser. Please allow popups or try email login.';
      } else if (errorString.contains('popup request')) {
        errorMsg = 'A sign-in window is already open. Please check your other tabs.';
      }

      setState(() => _error = errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth(bool isSignUp) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (isSignUp) {
        await auth.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await auth.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      if (mounted) {
        context.go('/setup');
      }
    } catch (err) {
      setState(() => _error = 'Auth error: ${err.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _error = 'Please enter your email to reset your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.sendPasswordReset(_emailController.text.trim());

      setState(() {
        _message = 'Password reset email sent! Check your inbox.';
        _view = 'email-login';
      });
    } catch (err) {
      setState(() => _error = 'Error: ${err.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildOptionsView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome to Mamma Buddy',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "A safe, friendly place for you and your growing baby. We're here to help every step of the way!",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),

        // Google Sign In Button
        GestureDetector(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8748A).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE8748A),
                    ),
                  )
                else
                  const Icon(Icons.account_circle, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _isLoading ? 'Signing in...' : 'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A3E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideX(begin: 0.1, duration: 300.ms),
        const SizedBox(height: 16),

        // Email Sign Up Button
        GestureDetector(
          onTap: () {
            setState(() {
              _view = 'email-signup';
              _error = null;
            });
          },
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
              'Sign up with Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, duration: 300.ms),
        const SizedBox(height: 24),

        // Login link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _view = 'email-login';
                  _error = null;
                });
              },
              child: const Text(
                'Log in',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE8748A),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Privacy notice with glass effect
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : const Color(0xFFE8748A).withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield,
                color: Color(0xFFE8748A),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is private and encrypted. We never sell your information.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFFB0A8C0)
                        : const Color(0xFF5C5470),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            setState(() {
              _view = 'options';
              _clearMessages();
              _emailController.clear();
              _passwordController.clear();
            });
          },
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back,
                color: Color(0xFFE8748A),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE8748A) : const Color(0xFFE8748A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          _view == 'email-login'
              ? 'Welcome Back'
              : _view == 'email-signup'
                  ? 'Create Account'
                  : 'Reset Password',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 32),

        // Error message
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

        // Success message
        if (_message != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _message!,
                    style: const TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email address',
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFFE8748A).withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE8748A), width: 2),
            ),
            labelStyle: TextStyle(
              color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
            ),
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A3E),
          ),
        ),
        const SizedBox(height: 16),

        // Password field (not shown for forgot password)
        if (_view != 'forgot-password')
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFFE8748A).withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE8748A), width: 2),
              ),
              labelStyle: TextStyle(
                color: isDark ? const Color(0xFFB0A8C0) : const Color(0xFF5C5470),
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A1A3E),
            ),
          ),

        // Forgot password link (only for login)
        if (_view == 'email-login')
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() => _view = 'forgot-password');
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE8748A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Submit button
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  if (_view == 'forgot-password') {
                    _handleForgotPassword();
                  } else {
                    _handleEmailAuth(_view == 'email-signup');
                  }
                },
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
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _view == 'email-login'
                          ? 'Log In'
                          : _view == 'email-signup'
                              ? 'Sign Up'
                              : 'Send Reset Link',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
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
            child: Center(
              child: SingleChildScrollView(
                child: _view == 'options'
                    ? _buildOptionsView(context)
                    : _buildEmailForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}