import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';

class PartnerLinkingScreen extends StatefulWidget {
  const PartnerLinkingScreen({super.key});

  @override
  State<PartnerLinkingScreen> createState() => _PartnerLinkingScreenState();
}

class _PartnerLinkingScreenState extends State<PartnerLinkingScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLinking = false;

  static const _rose = Color(0xFFE8748A);
  static const _lavender = Color(0xFF6B4B9A);
  static const _ink = Color(0xFF1A1A3E);
  static const _mauve = Color(0xFF5C5470);

  Future<void> _handleLinkByCode() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userData;
    if (user == null || _codeController.text.trim().isEmpty) return;

    setState(() => _isLinking = true);

    try {
      final targetId = _codeController.text.trim();
      final targetUser = await _firestoreService.getUser(targetId);

      if (targetUser == null) {
        throw Exception('User code not found. Please verify the code.');
      }

      if (targetUser.email == user.email) {
        throw Exception('You cannot link with yourself!');
      }

      await _firestoreService.linkPartnerAccount(user.uid, targetUser.email ?? '', targetId);
      await auth.reloadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully linked with partner! ❤️'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  void _shareInviteCode(String code) {
    Share.share('Join me on MammaBuddy! Use my invite code: $code to link our accounts.');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userData;
    if (user == null) return const SizedBox();

    final isPartner = user.isPartnerAccount == true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: Text('Partner Mode', style: GoogleFonts.dmSerifDisplay()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: _rose.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.heart_fill, color: _rose, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                isPartner ? 'Connect with Mom' : 'Invite your Partner',
                style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: isDark ? Colors.white : _ink),
              ),
              const SizedBox(height: 12),
              Text(
                isPartner 
                  ? 'Ask the mother for her invitation code to link your accounts and see her progress.'
                  : 'Share your code with your partner so he can follow your journey and support you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _mauve, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 48),

              if (isPartner) ...[
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'Enter Invite Code',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLinking ? null : _handleLinkByCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLinking 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Link Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _rose.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text('YOUR INVITE CODE', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: _mauve, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      SelectableText(
                        user.uid,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _rose, letterSpacing: 1),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _shareInviteCode(user.uid),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Invite Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _lavender,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
              if (user.partnerId != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Linked with ${user.partnerEmail ?? 'your partner'}',
                          style: GoogleFonts.plusJakartaSans(color: Colors.green.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
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
