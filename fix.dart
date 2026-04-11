import 'dart:io';

void main() {
  // 1. profile_tab.dart
  var pFile = File('lib/screens/profile_tab.dart');
  var p = pFile.readAsStringSync();
  p = p.replaceAll('Image.file(File(user.photoUrl!),', 'Image.network(user.photoUrl!,');
  p = p.replaceAll('backgroundColor: Colors.grey[100]', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
  p = p.replaceAll('color: Colors.white,', 'color: Theme.of(context).colorScheme.surface,');
  // Be careful with Colors.white inside CircularProgressIndicator etc, those don't have commas
  p = p.replaceAll('color: _ink', 'color: Theme.of(context).colorScheme.onSurface');
  
  var oldCancel = '''
                        onPressed: () {
                          setState(() {
                            _isCancelling = true;
                            // Would cancel subscription
                            _showCancelConfirm = false;
                            _activeSection = null;
                          });
                        },''';
                        
  var newCancel = '''
                        onPressed: () async {
                          setState(() {
                            _isCancelling = true;
                          });
                          try {
                            final auth = context.read<AuthProvider>();
                            final user = auth.userData;
                            if (user != null) {
                              final updatedUser = user.copyWith(plan: 'basic');
                              await auth.saveUserData(updatedUser);
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                'plan': 'basic',
                                'isPremium': false,
                                'premiumSince': FieldValue.delete(),
                              });
                              await auth.reloadUser();
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isCancelling = false;
                                _showCancelConfirm = false;
                                _activeSection = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription Cancelled')));
                            }
                          }
                        },''';
  p = p.replaceAll(oldCancel, newCancel);
  pFile.writeAsStringSync(p);
  
  // 2. home_tab.dart
  var hFile = File('lib/screens/home_tab.dart');
  var h = hFile.readAsStringSync();
  h = h.replaceAll('backgroundColor: const Color(0xFFFAFBFA)', 'backgroundColor: Theme.of(context).scaffoldBackgroundColor');
  h = h.replaceAll('color: Colors.white,', 'color: Theme.of(context).colorScheme.surface,');
  h = h.replaceAll('color: _ink', 'color: Theme.of(context).colorScheme.onSurface');
  hFile.writeAsStringSync(h);
  
  print('done');
}
