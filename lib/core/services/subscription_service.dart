import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import 'firestore_service.dart';

class SubscriptionService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Returns true if the user has an active premium plan or is in the 7-day trial.
  bool isPremium(UserModel? user) {
    if (user == null) return false;
    
    // Check if explicitly premium
    if (user.plan == 'premium' || user.isPremium == true) {
      // If expired, check expiry date
      if (user.subscriptionExpiryDate != null) {
        final expiry = DateTime.tryParse(user.subscriptionExpiryDate!);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          return false;
        }
      }
      return true;
    }

    // Check 7-day trial
    if (user.trialStartDate != null) {
      final trialStart = DateTime.tryParse(user.trialStartDate!);
      if (trialStart != null) {
        final trialEnd = trialStart.add(const Duration(days: 7));
        if (trialEnd.isAfter(DateTime.now())) {
          return true;
        }
      }
    }

    return false;
  }

  /// Calculates remaining trial days
  int getTrialDaysRemaining(UserModel? user) {
    if (user == null || user.trialStartDate == null) return 0;
    final trialStart = DateTime.tryParse(user.trialStartDate!);
    if (trialStart == null) return 0;
    final trialEnd = trialStart.add(const Duration(days: 7));
    final remaining = trialEnd.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  Future<Uri> getPayPalUrl({required String amount, required String currency}) async {
    final business = dotenv.env['PAYPAL_EMAIL'] ?? 'punkesh93@gmail.com';
    return Uri.parse(
      'https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=$business&amount=$amount&currency_code=$currency&item_name=MammaBuddy+Premium'
    );
  }

  /// Activates premium for a user (called after successful payment)
  Future<void> activatePremium(UserModel user, String planId, int months) async {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: 30 * months));
    
    final updatedUser = user.copyWith(
      plan: 'premium',
      isPremium: true,
      subscriptionType: planId,
      subscriptionExpiryDate: expiry.toIso8601String(),
      autoRenew: true,
      lastLoginDate: DateTime.now().toIso8601String(), // Force a refresh state
    );

    await _firestoreService.createUser(updatedUser);
  }

  /// Cancels subscription auto-renewal
  Future<void> cancelSubscription(UserModel user) async {
    // We keep the plan as 'premium' until expiry, but set autoRenew to false
    final updatedUser = user.copyWith(
      autoRenew: false,
    );
    
    await _firestoreService.createUser(updatedUser);
  }

  /// Returns the currency symbol based on the user's region
  String getCurrencySymbol(String? region) {
    if (region == 'IN') return '₹';
    return '\$';
  }
}
