import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/core/ads/ad_manager.dart';
import 'package:ed_tech/core/ads/ad_storage.dart';
import 'package:ed_tech/core/ads/app_open_ad_manager.dart';
import 'package:ed_tech/core/app_bloc_observer.dart';
import 'package:ed_tech/core/theme/locale_service.dart';
import 'package:ed_tech/data/services/auth_service.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'modules/app.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();
  Bloc.observer = AppBlocObserver();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();

  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Initialize ad storage (SharedPreferences-backed)
  await AdStorage.initialize();

  AuthService authService = await AuthService.initialize();
  await UserService.initialize();

  final defaultLocale = LocaleService.load();

  // Preload full-screen ads after SDK init
  AdManager.instance.preloadFullScreenAds();
  AppOpenAdManager.instance.preload();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('vi', 'VN')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: defaultLocale,
      child: App(authService: authService),
    ),
  );
}
