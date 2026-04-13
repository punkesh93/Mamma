import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import '../core/services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'yearly';
  bool _isProcessing = false;
  String? _successPlan;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Design tokens
  static const _rose = Color(0xFFE8748A);
  static const _ink = Color(0xFF1A1A3E);
  static const _mauve = Color(0xFF5C5470);

  List<Map<String, dynamic>> _getPlans(String region) {
    if (region == 'IN') {
      return [
        {
          'id': 'monthly',
          'name': 'Monthly',
          'price': '₹499',
          'priceNum': 499,
          'period': '/mo',
          'originalPrice': '₹998',
          'features': ['AI Pregnancy Chat', 'Meal Analysis', 'Wellness Studio'],
        },
        {
          'id': 'yearly',
          'name': 'Yearly',
          'price': '₹3999',
          'priceNum': 3999,
          'period': '/yr',
          'originalPrice': '₹7998',
          'features': ['All Monthly features', 'Partner Mode', 'Doctor Report AI', '20% Savings'],
          'recommended': true,
        },
      ];
    }
    if (region == 'EU') {
      return [
        {
          'id': 'monthly',
          'name': 'Monthly',
          'price': '€7.99',
          'priceNum': 7.99,
          'period': '/mo',
          'originalPrice': '€15.98',
          'features': ['AI Pregnancy Chat', 'Meal Analysis', 'Wellness Studio'],
        },
        {
          'id': 'yearly',
          'name': 'Yearly',
          'price': '€79.99',
          'priceNum': 79.99,
          'period': '/yr',
          'originalPrice': '€159.98',
          'features': ['All Monthly features', 'Partner Mode', 'Doctor Report AI', '25% Savings'],
          'recommended': true,
        },
      ];
    }
    // US Default
    return [
      {
        'id': 'monthly',
        'name': 'Monthly',
        'price': '\$7.99',
        'priceNum': 7.99,
        'period': '/mo',
        'originalPrice': '\$15.98',
        'features': ['AI Pregnancy Chat', 'Meal Analysis', 'Wellness Studio'],
      },
      {
        'id': 'yearly',
        'name': 'Yearly',
        'price': '\$79.99',
        'priceNum': 79.99,
        'period': '/yr',
        'originalPrice': '\$159.98',
        'features': ['All Monthly features', 'Partner Mode', 'Doctor Report AI', '15% Savings'],
        'recommended': true,
      },
    ];
  }

  Future<void> _activatePremium(String planId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userData;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final region = user.region;
      final plan = _getPlans(region).firstWhere((p) => p['id'] == planId);
      final amount = plan['priceNum'].toString();
      
      Uri url;
      if (region == 'IN') {
        url = await _subscriptionService.getRazorpayUrl(amount: amount);
      } else {
        url = await _subscriptionService.getPayPalUrl(amount: amount, currency: 'USD');
      }

      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        // Show a "Waiting for payment" dialog or similar
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Payment Initiated'),
              content: const Text('We have opened the payment gateway in your browser. Once completed, your premium status will update automatically.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                if (kDebugMode)
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _simulateSuccess(planId);
                    },
                    child: const Text('Simulate Success (Dev)', style: TextStyle(color: _rose)),
                  ),
              ],
            ),
          );
        }
      } catch (e) {
        throw Exception('Could not launch payment gateway: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _simulateSuccess(String planId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userData;
    if (user == null) return;

    setState(() => _isProcessing = true);
    try {
      final months = planId == 'monthly' ? 1 : 12;
      await _subscriptionService.activatePremium(user, planId, months);
      await auth.reloadUser();
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _successPlan = planId;
        });
      }
    } catch (e) {
       if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;
    final region = user?.region ?? 'US';
    final plans = _getPlans(region);
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
                  ]
                : [
                    const Color(0xFFFAF5F0),
                    const Color(0xFFFFE4E6).withOpacity(0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Launch offer badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_rose, const Color(0xFFF48FB1)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _rose.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 4),
                          Text(
                            '50% OFF Launch Offer!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _rose.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.flash_on, color: _rose, size: 32),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Mamma Buddy Premium',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlock the full ecosystem for your journey.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? const Color(0xFFB0A8C0) : _mauve,
                      ),
                    ),
                  ],
                ),
              ),

              // Plans List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isSelected = _selectedPlan == plan['id'];
                    final isRecommended = plan['recommended'] == true;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? _rose
                                : (_rose.withOpacity(0.1)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _rose.withOpacity(0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Best Value badge
                            if (isRecommended)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: _rose,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Best Value',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['name'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark ? Colors.white : _ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          plan['originalPrice'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _mauve,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          plan['price'],
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: _rose,
                                          ),
                                        ),
                                        Text(
                                          plan['period'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark
                                                ? const Color(0xFFB0A8C0)
                                                : _mauve,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Radio button
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _rose
                                          : (_rose.withOpacity(0.3)),
                                      width: 2,
                                    ),
                                    color: isSelected ? _rose : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(CupertinoIcons.check_mark,
                                          color: Colors.white, size: 14)
                                      : null,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Features
                            ...List.generate(
                              (plan['features'] as List).length,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.check_mark,
                                        color: _rose, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        plan['features'][i],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xFFB0A8C0)
                                              : _mauve,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Payment Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Selected plan info
                    Text(
                      'Selected Plan: ${plans.firstWhere((p) => p['id'] == _selectedPlan)['name']} - ${plans.firstWhere((p) => p['id'] == _selectedPlan)['price']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : _ink,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Success state
                    if (_successPlan != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.check_mark_circled, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Premium Activated! 🎉',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Pay button
                      GestureDetector(
                        onTap: _isProcessing
                            ? null
                            : () => _activatePremium(_selectedPlan),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_rose, const Color(0xFFF48FB1)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _rose.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    region == 'IN'
                                        ? 'Pay with Razorpay'
                                        : 'Pay with PayPal',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Security text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield,
                              color: _mauve, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Secured by ${region == 'IN' ? 'Razorpay' : 'PayPal'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFB0A8C0)
                                  : _mauve,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.public,
                              color: _mauve, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$region Pricing',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFB0A8C0)
                                  : _mauve,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(CupertinoIcons.star_fill,
                              color: _mauve, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Cancel Anytime',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFB0A8C0)
                                  : _mauve,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}