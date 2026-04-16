import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../core/services/subscription_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _rose = Color(0xFFE8748A);
const _lavender = Color(0xFF6B4B9A);
const _sky = Color(0xFF2A7A90);
const _ink = Color(0xFF1A1A3E);
const _mauve = Color(0xFF5C5470);

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _showSettings = false;
  bool _isEditing = false;
  String _editName = '';
  bool _isUploading = false;
  String? _activeSection;
  bool _showCancelConfirm = false;
  bool _isCancelling = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Daily goals
  String _goalCalories = '2200';
  String _goalProtein = '75';
  String _goalWater = '8';

  // Notification settings
  bool _notifDaily = true;
  bool _notifWeekly = true;
  bool _notifPartner = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userData;
    if (user != null) {
      _editName = user.name;
      _goalCalories = (user.dailyGoals?.calories ?? 2200).toString();
      _goalProtein = (user.dailyGoals?.protein ?? 75).toString();
      _goalWater = (user.dailyGoals?.water ?? 8).toString();
    }
  }

  Future<void> _handleSignOut() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.signOut();
    if (mounted) context.go('/welcome');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final user = auth.userData;
        if (user != null) {
          final updatedUser = user.copyWith(photoUrl: pickedFile.path);
          await auth.saveUserData(updatedUser);
        }
      } catch (e) {
        debugPrint('Error picking image: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPremium = user.plan == 'premium';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              child: Column(
                children: [
                  // ── Profile Picture & Info ────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                            ),
                            child: Center(
                              child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: user.photoUrl!.startsWith('http')
                                        ? Image.network(user.photoUrl!, width: 92, height: 92, fit: BoxFit.cover)
                                        : Image.network(user.photoUrl!, width: 92, height: 92, fit: BoxFit.cover),
                                  )
                                : const Icon(CupertinoIcons.person_fill, size: 40, color: Colors.grey),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                ],
                              ),
                              child: const Icon(CupertinoIcons.camera_fill, size: 16, color: _rose),
                            ),
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 150,
                            child: TextField(
                              autofocus: true,
                              controller: TextEditingController(text: _editName),
                              onChanged: (v) => _editName = v,
                              style: GoogleFonts.plusJakartaSans(color: Theme.of(context).colorScheme.onSurface),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isEditing = false);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(color: _rose, shape: BoxShape.circle),
                              child: Icon(CupertinoIcons.check_mark, color: Theme.of(context).colorScheme.surface, size: 18),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(user.name, style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(width: 8),
                            const Icon(CupertinoIcons.pencil, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(user.email ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _mauve)),
                    if (isPremium) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('MamaBuddy Plus', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Badges Section (NEW) ──────────────────────────────────────
              _buildBadgesSection(user),
              const SizedBox(height: 24),

              // ── Account Settings ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8),
                child: Text('ACCOUNT', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1.2)),
              ),
              _buildSettingsGroup([
                if (!isPremium)
                  _buildListTile(
                    icon: Icons.workspace_premium,
                    iconColor: Colors.amber,
                    title: 'Upgrade to Premium',
                    subtitle: 'Unlock all features',
                    onTap: () => context.push('/paywall'),
                    showDivider: true,
                  ),
                if (isPremium)
                  _buildListTile(
                    icon: CupertinoIcons.star_fill,
                    iconColor: Colors.amber,
                    title: 'MamaBuddy Plus (Active)',
                    subtitle: 'Manage your subscription',
                    onTap: () => setState(() => _activeSection = 'subscription'),
                    showDivider: true,
                  ),
                _buildListTile(
                  icon: CupertinoIcons.flag_fill,
                  iconColor: _rose,
                  title: 'Daily Goals',
                  subtitle: '${user.dailyGoals?.calories ?? 2200} kcal · ${user.dailyGoals?.protein ?? 75}g protein',
                  onTap: () => setState(() => _showSettings = true),
                  showDivider: true,
                ),
                _buildListTile(
                  icon: CupertinoIcons.heart_fill,
                  iconColor: Colors.pink,
                  title: 'Partner Mode',
                  subtitle: user.partnerId != null ? 'Partner connected ✓' : 'Invite your partner',
                  onTap: () => context.go('/partner'),
                  showDivider: false,
                ),
              ]),

              // ── Preferences ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 16, bottom: 8),
                child: Text('PREFERENCES', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1.2)),
              ),
              _buildSettingsGroup([
                _buildListTile(
                  icon: CupertinoIcons.bell_fill,
                  iconColor: _lavender,
                  title: 'Notifications',
                  subtitle: 'Daily reminders & check-ins',
                  onTap: () => setState(() => _activeSection = 'notifications'),
                  showDivider: true,
                ),
                _buildListTile(
                  icon: CupertinoIcons.shield_fill,
                  iconColor: _sky,
                  title: 'Privacy & Data',
                  subtitle: 'Manage your data',
                  onTap: () => setState(() => _activeSection = 'privacy'),
                  showDivider: false,
                ),
              ]),

              // ── Danger Zone ───────────────────────────────────────────────
              const SizedBox(height: 16),
              _buildSettingsGroup([
                _buildListTile(
                  icon: Icons.bug_report,
                  iconColor: Colors.orange,
                  title: 'Debug: Reset Subscription',
                  onTap: () async {
                    final updatedUser = user.copyWith(plan: 'basic');
                    await auth.saveUserData(updatedUser);
                    await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'ai-studio-c578e6c9-8cd4-4412-bd62-c325f63dac05').collection('users').doc(user.uid).update({
                      'plan': 'basic',
                      'isPremium': false,
                      'premiumSince': FieldValue.delete(),
                    });
                    await auth.reloadUser();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Reset')));
                    }
                                    },
                  showDivider: true,
                ),
                _buildListTile(
                  icon: CupertinoIcons.square_arrow_right,
                  iconColor: Colors.red,
                  title: 'Log Out',
                  onTap: _handleSignOut,
                  showDivider: false,
                ),
              ]),
              
              const SizedBox(height: 24),
              Center(
                child: Text('MamaBuddy v1.0', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500)),
              ),
            ],
          ),
        ),

        // ── Settings Modal ───────────────────────────────────────────────
          if (_showSettings) _buildSettingsModal(user),

          // ── Subscription Panel ───────────────────────────────────────────
          if (_activeSection == 'subscription' && isPremium) _buildSubscriptionPanel(),

          // ── Notifications Panel ─────────────────────────────────────────
          if (_activeSection == 'notifications') _buildNotificationsPanel(),

          // ── Privacy Panel ────────────────────────────────────────────────
          if (_activeSection == 'privacy') _buildPrivacyPanel(),

          // ── Cancel Confirm Modal ─────────────────────────────────────────
          if (_showCancelConfirm) _buildCancelConfirmModal(),
        ],
      ),
    ),
  );
}

  Widget _buildBadgesSection(UserModel user) {
    final List<Map<String, dynamic>> allBadges = [
      {'id': 'streak_7', 'name': '7 Day Streak', 'icon': '🔥', 'desc': 'Logged for 7 days'},
      {'id': 'water_champ', 'name': 'Water Champ', 'icon': '💧', 'desc': 'Met water goal for 5 days'},
      {'id': 'ai_pioneer', 'name': 'AI Pioneer', 'icon': '🤖', 'desc': 'Used AI insights 10 times'},
      {'id': 'mother_nature', 'name': 'Nature Lover', 'icon': '🌿', 'desc': 'Tracked 5 symptoms'},
    ];

    final userBadges = user.achievedBadges ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Text('ACHIEVEMENTS', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 1.2)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              final isAchieved = userBadges.contains(badge['id']) || index == 0; // First one unlocked for demo
              return Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isAchieved ? _rose.withOpacity(0.1) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: isAchieved ? _rose : Colors.grey.shade300, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badge['icon'],
                          style: TextStyle(fontSize: 24, color: isAchieved ? null : Colors.black.withOpacity(0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge['name'],
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: isAchieved ? _ink : Colors.grey),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailingContent,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
          subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve)) : null,
          trailing: trailingContent ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 64, endIndent: 0, color: Color(0xFFF0F0F0)),
      ],
    );
  }

  // ── Settings Modal ────────────────────────────────────────────────────────
  Widget _buildSettingsModal(UserModel user) {
    return GestureDetector(
      onTap: () => setState(() => _showSettings = false),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.flag_fill, color: _rose, size: 20),
                        const SizedBox(width: 8),
                        Text('Daily Goals', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    IconButton(onPressed: () => setState(() => _showSettings = false), icon: const Icon(CupertinoIcons.xmark, color: _mauve)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGoalField('🔥 Calories (kcal)', _goalCalories, (v) => _goalCalories = v),
                const SizedBox(height: 12),
                _buildGoalField('🥩 Protein (g)', _goalProtein, (v) => _goalProtein = v),
                const SizedBox(height: 12),
                _buildGoalField('💧 Water (glasses)', _goalWater, (v) => _goalWater = v),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showSettings = false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('Save Goals', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _mauve)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: GoogleFonts.plusJakartaSans(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Subscription Panel ────────────────────────────────────────────────────
  Widget _buildSubscriptionPanel() {
    return GestureDetector(
      onTap: () => setState(() => _activeSection = null),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text('Your Subscription', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    IconButton(onPressed: () => setState(() => _activeSection = null), icon: const Icon(CupertinoIcons.xmark, color: _mauve)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.check_mark_circled, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                      Text('MamaBuddy Plus', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade800)),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final user = context.read<AuthProvider>().userData!;
                      return Text(
                        '${_subscriptionService.getCurrencySymbol(user.region)}${user.subscriptionType == 'yearly' ? '79.99/yr' : '7.99/mo'}', 
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade700)
                      );
                    }
                  ),
                ],
                  ),
                ),
                const SizedBox(height: 16),
                ...['Unlimited AI mood checks', 'AI meal analysis', 'Doctor report analysis', 'Weekly insights', 'Partner mode'].map((f) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.check_mark, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(f, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showCancelConfirm = true),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('Cancel Subscription', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Notifications Panel ──────────────────────────────────────────────────
  Widget _buildNotificationsPanel() {
    return GestureDetector(
      onTap: () => setState(() => _activeSection = null),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.bell_fill, color: _lavender, size: 20),
                        const SizedBox(width: 8),
                        Text('Notifications', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    IconButton(onPressed: () => setState(() => _activeSection = null), icon: const Icon(CupertinoIcons.xmark, color: _mauve)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildToggleRow('Daily Reminders', 'Meal logging, water, and exercise nudges', _notifDaily, (v) => setState(() => _notifDaily = v)),
                _buildToggleRow('Weekly Insights', 'AI-powered weekly progress summary', _notifWeekly, (v) => setState(() => _notifWeekly = v)),
                _buildToggleRow('Partner Alerts', 'When your partner sends a message', _notifPartner, (v) => setState(() => _notifPartner = v)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, String desc, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _mauve)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _rose,
          ),
        ],
      ),
    );
  }

  // ── Privacy Panel ─────────────────────────────────────────────────────────
  Widget _buildPrivacyPanel() {
    return GestureDetector(
      onTap: () => setState(() => _activeSection = null),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.shield_fill, color: _sky, size: 20),
                        const SizedBox(width: 8),
                        Text('Privacy & Data', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    IconButton(onPressed: () => setState(() => _activeSection = null), icon: const Icon(CupertinoIcons.xmark, color: _mauve)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _sky.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.lock_fill, color: _sky, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Your data is encrypted and secure', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...['Meal logs & nutrition data', 'Mood & symptom records', 'Doctor report images', 'Exercise & wellness activity'].map((item) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.check_mark_circled, color: _sky, size: 14),
                        const SizedBox(width: 8),
                        Text(item, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(foregroundColor: _sky, side: BorderSide(color: _sky.withOpacity(0.5)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('📥 Download My Data', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('🗑️ Delete Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Cancel Confirm Modal ─────────────────────────────────────────────────
  Widget _buildCancelConfirmModal() {
    return GestureDetector(
      onTap: () => setState(() => _showCancelConfirm = false),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Cancel Subscription?', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text("You'll lose access to all premium features. Your pregnancy data stays safe.", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _mauve), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showCancelConfirm = false),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Keep Premium', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_isCancelling) return;
                          setState(() {
                            _isCancelling = true;
                          });
                          try {
                            final auth = context.read<AuthProvider>();
                            final user = auth.userData;
                            if (user != null) {
                              // Use the logic to keep premium until end of period but turn off auto-renew
                              final updatedUser = user.copyWith(
                                autoRenew: false,
                                plan: 'premium', // Stay premium
                                isPremium: true,
                              );
                              await auth.saveUserData(updatedUser);
                            }
                          } catch (e) {
                            debugPrint('Cancellation error: $e');
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isCancelling = false;
                                _showCancelConfirm = false;
                                _activeSection = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Auto-renewal turned off. You retain access until expiry.')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isCancelling ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Yes, Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}