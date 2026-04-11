import 'dart:io';

void main() {
  final files = [
    'lib/screens/home_tab.dart',
    'lib/screens/profile_tab.dart',
    'lib/screens/setup_screen.dart',
    'lib/screens/paywall_screen.dart',
  ];

  final iconMap = {
    'Icons.favorite': 'CupertinoIcons.heart_fill',
    'Icons.person': 'CupertinoIcons.person_fill',
    'Icons.settings': 'CupertinoIcons.settings',
    'Icons.camera_alt': 'CupertinoIcons.camera_fill',
    'Icons.notifications': 'CupertinoIcons.bell_fill',
    'Icons.security': 'CupertinoIcons.shield_fill',
    'Icons.logout': 'CupertinoIcons.square_arrow_right',
    'Icons.check_circle': 'CupertinoIcons.check_mark_circle_fill',
    'Icons.check': 'CupertinoIcons.check_mark',
    'Icons.chevron_right': 'CupertinoIcons.chevron_right',
    'Icons.expand_more': 'CupertinoIcons.chevron_down',
    'Icons.expand_less': 'CupertinoIcons.chevron_up',
    'Icons.psychology': 'CupertinoIcons.brain',
    'Icons.mic': 'CupertinoIcons.mic_fill',
    'Icons.restaurant': 'CupertinoIcons.cart_fill',
    'Icons.flag': 'CupertinoIcons.flag_fill',
    'Icons.star': 'CupertinoIcons.star_fill',
    'Icons.lock': 'CupertinoIcons.lock_fill',
    'Icons.warning': 'CupertinoIcons.exclamationmark_triangle_fill',
    'Icons.close': 'CupertinoIcons.xmark',
    'Icons.mic_none': 'CupertinoIcons.mic',
    'Icons.sync': 'CupertinoIcons.arrow_2_circlepath',
    'Icons.refresh': 'CupertinoIcons.refresh',
    'Icons.edit': 'CupertinoIcons.pencil',
    'Icons.auto_awesome': 'CupertinoIcons.sparkles',
    'Icons.people': 'CupertinoIcons.person_2_fill',
  };

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // Ensure Cupertino is imported
    if (!content.contains('package:flutter/cupertino.dart')) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/cupertino.dart';",
      );
    }

    iconMap.forEach((oldIcon, newIcon) {
      content = content.replaceAll(oldIcon, newIcon);
    });
    
    file.writeAsStringSync(content);
  }
  print('Icons updated');
}
