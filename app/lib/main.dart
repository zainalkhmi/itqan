import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Open all boxes
  await Hive.openBox('settings');
  await Hive.openBox('sessions');
  await Hive.openBox('reading_positions');
  await Hive.openBox('srs_cards');
  await Hive.openBox('tashih_submissions');
  await Hive.openBox('sync_queue');
  await Hive.openBox('sync_account');
  await Hive.openBox('ijazah_box');

  final onboardingDone = Hive.box('settings').get('onboarding_done', defaultValue: false) as bool;

  runApp(ProviderScope(
    child: ItqanApp(showOnboarding: !onboardingDone),
  ));
}
