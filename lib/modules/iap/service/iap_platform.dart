import 'package:flutter/foundation.dart';

class IapPlatform {
  const IapPlatform._();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static String? get apiValue {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
    if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
    return null;
  }
}
