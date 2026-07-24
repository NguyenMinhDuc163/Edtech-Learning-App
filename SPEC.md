# FINAL SPEC: Google AdMob Production Integration for Edu-Tech Flutter App

## 1. Mục tiêu

Tích hợp Google AdMob hoàn chỉnh cho ứng dụng Flutter Edu-Tech trên Android và iOS.

Đây là bản triển khai cuối cùng, không chia phase.

Hệ thống phải hỗ trợ đầy đủ:

1. Adaptive Banner Ad
2. Native Ad
3. Interstitial Ad
4. Rewarded Ad
5. Rewarded Interstitial Ad
6. App Open Ad

Yêu cầu:

* Dùng production AdMob App ID.
* Dùng production Ad Unit ID.
* Android và iOS có ID riêng.
* Toàn bộ ID và giới hạn quảng cáo đặt tại một file duy nhất.
* Không sử dụng Firebase Remote Config.
* Không sử dụng nhiều file environment phức tạp.
* Không hard-code ID tại từng màn hình.
* Quảng cáo lỗi không được làm app crash.
* Quảng cáo chưa sẵn sàng không được chặn navigation.
* Không hiển thị quảng cáo tại những màn gây ảnh hưởng đến việc học.
* Có frequency cap tập trung.
* Có lifecycle và dispose đầy đủ.
* Có test cho placement, frequency và rewarded quota.

---

# 2. Nguyên tắc cấu hình production

Source code sử dụng production AdMob ID.

Không tạo hai hệ thống key production và test trong Dart.

Khi development hoặc QA:

* Vẫn request bằng production Ad Unit ID.
* Thiết bị development phải được đăng ký là AdMob test device bằng `RequestConfiguration`.
* Không click quảng cáo live trên thiết bị không được đánh dấu test.
* Không commit test device ID cá nhân vào source production.

Khi release:

* Không cấu hình test device.
* App sử dụng production App ID và production Ad Unit ID đã khai báo.

---

# 3. Bối cảnh ứng dụng

Các luồng chính:

```text
Authentication
Splash → Onboarding → Sign In / Sign Up
→ Forgot Password → OTP → Reset Password

Dashboard
Home | Course | AI Chat | Quiz

Course
Course List
→ Search / Filter
→ Course Detail
→ Lesson
→ Video / Document

Quiz
Quiz List
→ Quiz Detail
→ Quiz Taking
→ Quiz Result
→ Leaderboard

AI Chat
AI Consent
→ ChatBot
→ Chat History

Profile
Profile
→ Edit Profile
→ Settings

Payment
Payment Method
→ Card
→ Confirmation
→ Payment WebView
→ Invoice
```

Mục tiêu là tạo doanh thu nhưng không phá vỡ trải nghiệm học tập.

---

# 4. Định dạng quảng cáo và vai trò

## 4.1 Adaptive Banner

Dùng cho những vị trí cố định, ít gây gián đoạn:

* Cuối Home.
* Cuối Chat History.
* Một số màn nội dung ngắn.
* Khu vực cuối Leaderboard nếu Native Ad không phù hợp.

Banner phải dùng Anchored Adaptive Banner theo chiều rộng thiết bị.

## 4.2 Native Ad

Dùng cho các danh sách và nội dung khám phá:

* Home feed.
* Course List.
* Course Search.
* Course Filter Result.
* Course Detail.
* Quiz List.
* Leaderboard.
* Chat History.

Native Ad phải được triển khai thật.

Không sử dụng Banner Ad để giả Native Ad.

Ưu tiên dùng Native Template của Google nếu phiên bản plugin hiện tại hỗ trợ ổn định trên cả Android và iOS.

Nếu project cần UI tùy chỉnh sâu, triển khai Native Factory riêng:

```text
Android:
NativeAdFactory.kt

iOS:
NativeAdFactory.swift
```

Native Ad phải có:

* Nhãn quảng cáo rõ ràng.
* Headline.
* Body nếu có.
* Advertiser nếu có.
* Icon hoặc media.
* Call-to-action.
* Không làm CTA quảng cáo giống nút chức năng của ứng dụng.

## 4.3 Interstitial

Dùng tại điểm chuyển tiếp tự nhiên nhưng không có reward:

* Rời Quiz Result.
* Hoàn thành lesson miễn phí theo chu kỳ.
* Rời một luồng học miễn phí sau khi hoàn thành tác vụ.

Không dùng khi:

* Người dùng bấm bottom tab.
* Mở Course Detail.
* Đang xem video.
* Đang làm quiz.
* Đang nhập form.
* Vừa mở ứng dụng.
* Vừa đóng một full-screen ad khác.

## 4.4 Rewarded

Dùng khi người dùng chủ động chọn xem quảng cáo để nhận quyền lợi:

* Nhận thêm lượt hỏi AI.
* Mở khóa một lesson preview bổ sung.
* Xem lời giải chi tiết của quiz nếu nghiệp vụ hiện tại hỗ trợ.
* Nhận thêm một lần thử quiz nếu có giới hạn lượt thử.

Rewarded không được tự động hiển thị.

## 4.5 Rewarded Interstitial

Dùng tại một chuyển tiếp tự nhiên và có phần thưởng tự động.

Trước khi hiển thị phải có màn giới thiệu:

```text
Xem quảng cáo để nhận phần thưởng
```

Màn giới thiệu phải có:

* Mô tả rõ phần thưởng.
* Nút tiếp tục xem quảng cáo.
* Nút bỏ qua.
* Không tự động mở ad ngay khi màn giới thiệu xuất hiện.

Vị trí phù hợp:

* Sau khi hoàn thành một quiz hợp lệ, đề nghị nhân đôi điểm thưởng hoặc nhận một lượt thử lại.
* Sau khi hoàn thành lesson miễn phí, đề nghị nhận một lượt hỏi AI bổ sung.
* Không dùng Rewarded Interstitial trong khi user đang học hoặc đang làm quiz.

Nếu app hiện chưa có điểm thưởng, energy hoặc retry limit, chỉ triển khai infrastructure và dùng placement được xác định trong spec này:

```text
Quiz Result → nhận thêm 1 lượt thử lại quiz
```

Nếu quiz hiện tại không có giới hạn số lần thử, Rewarded Interstitial sẽ cấp:

```text
+1 câu hỏi AI
```

Không được tạo phần thưởng giả không có giá trị.

## 4.6 App Open Ad

Dùng khi:

* App được đưa từ background trở lại foreground.
* Người dùng đang ở màn loading phù hợp.
* App đã được sử dụng ít nhất ba lần trước đó.
* App đã background đủ thời gian tối thiểu.

Không dùng:

* Lần mở app đầu tiên.
* Trong onboarding.
* Khi người dùng vừa đăng nhập.
* Khi người dùng đang ở Payment WebView.
* Khi người dùng đang làm quiz.
* Khi video đang phát.
* Khi một full-screen ad khác đang hiển thị.
* Khi app foreground sau khi user vừa chọn file, camera, thanh toán hoặc hệ thống permission.
* Cold start nếu app đã tải xong và người dùng đã vào nội dung chính.

App Open Ad đã load phải được coi là hết hạn sau thời gian an toàn quy định bởi SDK. Không giữ ad cũ vô thời hạn.

---

# 5. File cấu hình AdMob duy nhất

Tạo:

```text
lib/core/ads/admob_config.dart
```

Đây là file duy nhất chứa:

* App ID.
* Ad Unit ID.
* Factory ID.
* Tần suất quảng cáo.
* Quota rewarded.
* Các công tắc bật tắt dạng hằng số.

Không tạo Remote Config.

Không khai báo ID tại các file khác.

```dart
import 'dart:io';

abstract final class AdMobConfig {
  AdMobConfig._();

  // =========================================================
  // GLOBAL SWITCHES
  // =========================================================

  static const bool adsEnabled = true;

  static const bool bannerEnabled = true;
  static const bool nativeEnabled = true;
  static const bool interstitialEnabled = true;
  static const bool rewardedEnabled = true;
  static const bool rewardedInterstitialEnabled = true;
  static const bool appOpenEnabled = true;

  // =========================================================
  // ADMOB APP IDS - PRODUCTION
  // =========================================================

  static const String androidAppId =
      'YOUR_ANDROID_PRODUCTION_ADMOB_APP_ID';

  static const String iosAppId =
      'YOUR_IOS_PRODUCTION_ADMOB_APP_ID';

  // =========================================================
  // ANDROID PRODUCTION AD UNIT IDS
  // =========================================================

  static const String androidBannerAdUnitId =
      'YOUR_ANDROID_PRODUCTION_BANNER_AD_UNIT_ID';

  static const String androidNativeAdUnitId =
      'YOUR_ANDROID_PRODUCTION_NATIVE_AD_UNIT_ID';

  static const String androidInterstitialAdUnitId =
      'YOUR_ANDROID_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';

  static const String androidRewardedAdUnitId =
      'YOUR_ANDROID_PRODUCTION_REWARDED_AD_UNIT_ID';

  static const String androidRewardedInterstitialAdUnitId =
      'YOUR_ANDROID_PRODUCTION_REWARDED_INTERSTITIAL_AD_UNIT_ID';

  static const String androidAppOpenAdUnitId =
      'YOUR_ANDROID_PRODUCTION_APP_OPEN_AD_UNIT_ID';

  // =========================================================
  // IOS PRODUCTION AD UNIT IDS
  // =========================================================

  static const String iosBannerAdUnitId =
      'YOUR_IOS_PRODUCTION_BANNER_AD_UNIT_ID';

  static const String iosNativeAdUnitId =
      'YOUR_IOS_PRODUCTION_NATIVE_AD_UNIT_ID';

  static const String iosInterstitialAdUnitId =
      'YOUR_IOS_PRODUCTION_INTERSTITIAL_AD_UNIT_ID';

  static const String iosRewardedAdUnitId =
      'YOUR_IOS_PRODUCTION_REWARDED_AD_UNIT_ID';

  static const String iosRewardedInterstitialAdUnitId =
      'YOUR_IOS_PRODUCTION_REWARDED_INTERSTITIAL_AD_UNIT_ID';

  static const String iosAppOpenAdUnitId =
      'YOUR_IOS_PRODUCTION_APP_OPEN_AD_UNIT_ID';

  // =========================================================
  // NATIVE FACTORY
  // =========================================================

  static const String nativeFactoryId =
      'eduTechNativeAdFactory';

  // =========================================================
  // INTERSTITIAL RULES
  // =========================================================

  static const Duration minimumTimeAfterAppStart =
      Duration(minutes: 3);

  static const Duration minimumInterstitialInterval =
      Duration(minutes: 5);

  static const int maximumInterstitialPerSession = 3;

  static const int maximumInterstitialPerDay = 6;

  static const int quizCompletedInterstitialInterval = 2;

  static const int lessonCompletedInterstitialInterval = 3;

  static const Duration minimumQuizDuration =
      Duration(minutes: 2);

  // =========================================================
  // APP OPEN RULES
  // =========================================================

  static const int minimumAppLaunchesBeforeAppOpen = 3;

  static const Duration minimumBackgroundDurationForAppOpen =
      Duration(minutes: 5);

  static const Duration minimumAppOpenInterval =
      Duration(hours: 4);

  static const int maximumAppOpenPerDay = 3;

  static const Duration appOpenAdMaximumAge =
      Duration(hours: 4);

  // =========================================================
  // REWARDED CHAT RULES
  // =========================================================

  static const int freeChatQuestionsPerDay = 5;

  static const int rewardedChatQuestions = 3;

  static const int maximumRewardedAdsPerDay = 3;

  // =========================================================
  // REWARDED INTERSTITIAL RULES
  // =========================================================

  static const int rewardedInterstitialExtraChatQuestions = 1;

  static const int maximumRewardedInterstitialPerDay = 2;

  static const Duration minimumRewardedInterstitialInterval =
      Duration(minutes: 10);

  // =========================================================
  // NATIVE LIST RULES
  // =========================================================

  static const int courseListNativeInterval = 6;

  static const int courseListMaximumNativeAds = 2;

  static const int searchNativePosition = 5;

  static const int filterNativePosition = 5;

  static const int quizListNativePosition = 5;

  static const int leaderboardNativePosition = 7;

  // =========================================================
  // PLATFORM HELPERS
  // =========================================================

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return androidBannerAdUnitId;
    if (Platform.isIOS) return iosBannerAdUnitId;

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) return androidNativeAdUnitId;
    if (Platform.isIOS) return iosNativeAdUnitId;

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return androidInterstitialAdUnitId;
    }

    if (Platform.isIOS) {
      return iosInterstitialAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedAdUnitId;
    }

    if (Platform.isIOS) {
      return iosRewardedAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedInterstitialAdUnitId;
    }

    if (Platform.isIOS) {
      return iosRewardedInterstitialAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return androidAppOpenAdUnitId;
    }

    if (Platform.isIOS) {
      return iosAppOpenAdUnitId;
    }

    throw UnsupportedError(
      'AdMob only supports Android and iOS',
    );
  }
}
```

Agent phải thay toàn bộ placeholder bằng production key do người dùng cung cấp.

Không được để lại:

```text
YOUR_*
```

trong bản release cuối.

---

# 6. Android App ID

File:

```text
android/app/src/main/AndroidManifest.xml
```

Trong `<application>`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_ANDROID_PRODUCTION_ADMOB_APP_ID" />
```

Giá trị phải giống:

```dart
AdMobConfig.androidAppId
```

Do AndroidManifest không thể đọc Dart constant, Android App ID phải được cập nhật tại hai vị trí:

1. `admob_config.dart`
2. `AndroidManifest.xml`

Không sử dụng sample App ID.

---

# 7. iOS App ID

File:

```text
ios/Runner/Info.plist
```

Thêm:

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_IOS_PRODUCTION_ADMOB_APP_ID</string>
```

Giá trị phải giống:

```dart
AdMobConfig.iosAppId
```

iOS App ID phải được cập nhật tại:

1. `admob_config.dart`
2. `Info.plist`

Không sử dụng sample App ID.

---

# 8. Cấu trúc thư mục

Tạo:

```text
lib/core/ads/
```

Cấu trúc:

```text
lib/core/ads/
  admob_config.dart
  ad_manager.dart
  ad_frequency_manager.dart
  ad_storage.dart
  app_open_ad_manager.dart
  chat_ai_quota_manager.dart
  rewarded_interstitial_reward_manager.dart

  models/
    ad_show_result.dart

  widgets/
    adaptive_banner_ad_widget.dart
    native_ad_widget.dart
    rewarded_interstitial_intro_dialog.dart
```

Platform native:

```text
android/app/src/main/kotlin/.../
  EduTechNativeAdFactory.kt
```

```text
ios/Runner/
  EduTechNativeAdFactory.swift
```

Không tạo:

* Remote Config service.
* Environment service.
* Nhiều file key.
* Placement config phức tạp.

---

# 9. Khởi tạo Mobile Ads

Thêm package:

```yaml
dependencies:
  google_mobile_ads: <stable version tương thích>
```

Agent phải chọn version stable tương thích với Flutter hiện tại.

Không tự ý nâng Flutter major version.

Trong bootstrap:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const App());
}
```

Điều chỉnh theo initialization hiện tại của project.

Không phá:

* Firebase initialization.
* Localization.
* Shared storage.
* Dependency injection.
* Authentication bootstrap.

Sau khi SDK initialize:

```dart
AdManager.instance.preloadFullScreenAds();
AppOpenAdManager.instance.preload();
```

Nếu AdMob initialization lỗi:

* Log lỗi.
* Cho phép ứng dụng tiếp tục chạy.
* Không crash startup.

---

# 10. Development bằng production ID

Production key vẫn được sử dụng trong source.

Đối với thiết bị development:

```dart
await MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    testDeviceIds: [
      'LOCAL_TEST_DEVICE_ID',
    ],
  ),
);
```

Yêu cầu:

* Chỉ bật cấu hình này trong development.
* Không commit ID thiết bị cá nhân nếu repository public.
* Production release không chứa test device ID.
* Không click quảng cáo live trên thiết bị không được đánh dấu test.

---

# 11. Native Ad hoàn chỉnh

## 11.1 Không dùng placeholder

Không tạo:

```text
NativeAdPlaceholderWidget
```

Tạo thật:

```text
NativeAdWidget
```

Native Ad sử dụng:

```dart
NativeAd(
  adUnitId: AdMobConfig.nativeAdUnitId,
  factoryId: AdMobConfig.nativeFactoryId,
  request: const AdRequest(),
  listener: NativeAdListener(...),
)
```

## 11.2 Android Native Factory

Tạo:

```text
EduTechNativeAdFactory.kt
```

Layout Native Ad phải phù hợp Course Card nhưng vẫn phân biệt rõ là quảng cáo.

Hiển thị:

* Ad attribution.
* Icon.
* Headline.
* Body nếu có.
* Advertiser nếu có.
* Media nếu có.
* CTA.

Đăng ký factory trong Android application/plugin initialization.

Hủy đăng ký khi engine bị dispose nếu kiến trúc yêu cầu.

## 11.3 iOS Native Factory

Tạo:

```text
EduTechNativeAdFactory.swift
```

Hiển thị cùng cấu trúc với Android.

Phải đặt width và height rõ ràng cho Native Ad container.

Đăng ký cùng `factoryId`:

```text
eduTechNativeAdFactory
```

## 11.4 Lifecycle

Mỗi `NativeAdWidget`:

* Chỉ load một lần cho widget instance.
* Dispose NativeAd khi widget dispose.
* Dispose ad ngay khi load fail.
* Không dùng cùng NativeAd object cho nhiều `AdWidget`.
* Không reload khi parent setState nhỏ.
* Không giữ quảng cáo của item đã ra khỏi list quá lâu.

---

# 12. Vị trí quảng cáo chi tiết

## 12.1 Splash

Không hiển thị Banner hoặc Native.

App Open chỉ được phép khi:

* Không phải lần chạy đầu.
* App đang trong trạng thái loading.
* Quảng cáo đã load sẵn.
* User chưa vào Home.
* Không làm chậm app chỉ để đợi quảng cáo.

Nếu app load xong trước ad:

```text
Bỏ qua App Open và đi tiếp.
```

Không được đưa user vào Home rồi mới bất ngờ mở App Open.

---

## 12.2 Onboarding

Không quảng cáo.

---

## 12.3 Authentication

Không quảng cáo tại:

* Sign In.
* Sign Up.
* Forgot Password.
* OTP.
* Reset Password.

---

## 12.4 Home Screen

Thứ tự:

```text
HomeHeaderWidget
HomePromoCarousel
LearningPlanWidget
NativeAdWidget - small style
CourseSuggestionsWidget
AdaptiveBannerAdWidget
Bottom spacing
```

Quy tắc:

* Một Native Ad sau Learning Plan.
* Một Adaptive Banner gần cuối Home.
* Không đặt banner sát bottom navigation.
* Nếu nội dung Home ngắn, chỉ dùng Native Ad và bỏ banner để tránh hai ad xuất hiện cùng viewport.
* Hai quảng cáo không được đồng thời xuất hiện trong cùng một màn hình điện thoại.

---

## 12.5 Course List

Dùng Native Ad, không dùng banner giữa danh sách.

Vị trí:

```text
Course 1
Course 2
Course 3
Course 4
Course 5
Course 6
Native Ad
Course 7
...
Course 12
Native Ad
```

Quy tắc:

* Native sau item 6.
* Native tiếp theo sau item 12.
* Tối đa 2 Native Ad.
* Dưới 6 khóa học không hiển thị.
* Không lặp hoặc mất course.
* Không hiển thị banner trong list nếu đã dùng Native Ad.

---

## 12.6 Search Course

Sau khi có kết quả:

```text
Result 1
Result 2
Result 3
Result 4
Result 5
Native Ad
Result 6
...
```

Quy tắc:

* Ít nhất 6 kết quả.
* Chỉ 1 Native Ad.
* Không hiện trước khi tìm.
* Không hiện trong search history.
* Không hiện khi đang gõ.
* Không hiện trong loading, error hoặc empty.

---

## 12.7 Filter Result

Vị trí:

```text
Result 1
Result 2
Result 3
Result 4
Result 5
Native Ad
Result 6
...
```

Quy tắc:

* Ít nhất 6 kết quả.
* Chỉ 1 Native Ad.
* Không hiện khi loading, error hoặc empty.

---

## 12.8 Course Detail

Thứ tự:

```text
Course Header
Video Preview
Course Information
About
Lesson Preview
Reviews
Native Ad - medium style
Bottom action spacing
```

Quy tắc:

* Chỉ 1 Native Ad.
* Không đặt trên video.
* Không đặt sát video.
* Không đặt giữa lesson list.
* Không đặt sát CTA Enroll, Buy, Start hoặc Continue.
* Không hiển thị nếu course đã mua.
* Không hiển thị nếu user có quyền ad-free.
* Không hiển thị trong lesson bottom sheet.

---

## 12.9 Lesson Content

Không Banner hoặc Native trong nội dung đang học.

Interstitial có thể xét sau khi hoàn thành lesson miễn phí.

Rule:

```text
Mỗi 3 lesson miễn phí hoàn thành
→ kiểm tra frequency
→ hiển thị Interstitial
```

Không hiển thị nếu:

* Lesson thuộc course đã mua.
* User vừa xem một full-screen ad.
* Video vẫn đang phát.
* Completion chưa được lưu thành công.
* Người dùng đang chuyển sang lesson tiếp theo bằng auto-play.

Nếu ad chưa ready:

```text
Tiếp tục navigation bình thường.
```

---

## 12.10 Video Player

Không quảng cáo khi video đang phát:

* Không Banner.
* Không Native.
* Không Interstitial.
* Không Rewarded Interstitial.
* Không App Open.

Khi app foreground và video đang active:

```text
Không hiển thị App Open.
```

Không hiển thị Interstitial khi thoát fullscreen video.

---

## 12.11 Document Reader

Không Banner hoặc Native phủ lên nội dung.

Không App Open khi user vừa quay lại từ:

* File picker.
* Share sheet.
* System preview.

Có thể đặt một Adaptive Banner ở cuối tài liệu chỉ khi:

* Document được render như nội dung scroll trong app.
* Banner nằm sau toàn bộ nội dung.
* Không che nội dung.
* Không có nút thao tác quan trọng bên cạnh.

Nếu document reader là fullscreen PDF viewer thì không đặt quảng cáo.

---

## 12.12 Quiz List

Vị trí:

```text
Quiz 1
Quiz 2
Quiz 3
Quiz 4
Quiz 5
Native Ad
Quiz 6
...
```

Quy tắc:

* Ít nhất 6 quiz.
* Chỉ 1 Native Ad.
* Không hiện loading, error hoặc empty.
* Không đặt sát nút Start Quiz.

---

## 12.13 Quiz Detail

Đặt một Native Ad nhỏ gần cuối nội dung, trước khoảng trống dẫn tới CTA.

Không đặt sát nút:

```text
Start Quiz
```

Không đặt nếu Quiz Detail quá ngắn khiến ad và CTA cùng nằm trong một vùng dễ bấm nhầm.

---

## 12.14 Quiz Taking

Không được có bất kỳ quảng cáo nào.

Không App Open nếu app foreground trong lúc làm quiz.

Không sửa:

* Timer.
* Answer state.
* Question navigation.
* Submit logic.
* API chấm điểm.

---

## 12.15 Quiz Result

Không mở quảng cáo khi result vừa xuất hiện.

Thứ tự:

```text
Hiển thị điểm
Hiển thị đáp án
Hiển thị giải thích
Hiển thị CTA
Native Ad gần cuối nếu màn result dài
```

### Interstitial

Khi user bấm:

* Back.
* Continue.
* Back to Quiz List.

Thực hiện:

```text
Record quiz completion
→ kiểm tra mỗi 2 quiz
→ kiểm tra quiz kéo dài tối thiểu 2 phút
→ kiểm tra session và cooldown
→ show Interstitial
→ chờ dismiss hoặc fail
→ navigation
```

### Rewarded Interstitial

Hiển thị lựa chọn sau khi result đã hiển thị đầy đủ:

```text
Nhận thêm 1 lượt hỏi AI bằng cách xem quảng cáo
```

Trước khi mở phải có dialog:

```text
Bạn sẽ nhận thêm 1 lượt hỏi AI sau khi xem quảng cáo.

[Bỏ qua] [Xem quảng cáo]
```

Rewarded Interstitial không thay thế Interstitial trong cùng lần rời màn.

Rule:

```text
Nếu Rewarded Interstitial đã hiển thị hoặc người dùng đã chọn xem:
không được hiển thị Interstitial khi rời màn đó.
```

---

## 12.16 Leaderboard

Thứ tự:

```text
Top 3
Ranking 4
Ranking 5
Ranking 6
Ranking 7
Native Ad
Ranking 8...
Adaptive Banner cuối màn nếu danh sách đủ dài
```

Quy tắc:

* Không đặt ad trên top 3.
* Native sau item 7.
* Nếu Native đã visible gần cuối màn, không thêm Banner.
* Banner chỉ dùng nếu ranking dài và Native không nằm gần cuối.

---

## 12.17 Chat AI

Không Banner hoặc Native trong danh sách tin nhắn.

Không đặt ad gần:

* Input.
* Send button.
* Keyboard.
* Tin nhắn.

Quota:

```text
5 câu miễn phí mỗi ngày.
Rewarded Ad nhận thêm 3 câu.
Tối đa 3 Rewarded Ad mỗi ngày.
```

Luồng:

```text
User bấm Send
→ kiểm tra quota
→ còn lượt: gửi
→ hết lượt: dialog
→ user chọn xem Rewarded
→ SDK xác nhận reward
→ cộng 3 lượt
```

Không tự động mở Rewarded.

Không cộng quota nếu đóng sớm.

Không xóa nội dung đang nhập nếu ad chưa sẵn sàng.

---

## 12.18 Chat History

Dùng Native Ad sau conversation thứ 5.

Nếu danh sách ít hơn 6 conversation:

* Không Native.
* Có thể dùng một Adaptive Banner cuối màn nếu không làm UI chật.

Không hiển thị quảng cáo trong conversation detail.

---

## 12.19 Profile

Profile Overview có thể có một Adaptive Banner cuối màn.

Không quảng cáo tại:

* Edit Profile.
* Change Password.
* Delete Account.
* Form nhập dữ liệu.
* Privacy Settings.

---

## 12.20 Payment

Không quảng cáo tại toàn bộ payment flow:

* Address.
* Payment Method.
* Add Card.
* Confirm.
* Payment WebView.
* Invoice.
* Transaction Result.

Không App Open khi app foreground trong payment flow.

---

# 13. Full-screen frequency manager

Tạo:

```text
lib/core/ads/ad_frequency_manager.dart
```

Quản lý chung:

* Interstitial.
* Rewarded.
* Rewarded Interstitial.
* App Open.

Trạng thái:

```dart
DateTime appStartedAt;
DateTime? lastInterstitialAt;
DateTime? lastRewardedInterstitialAt;
DateTime? lastAppOpenAt;
DateTime? backgroundStartedAt;

int sessionInterstitialCount;
int dailyInterstitialCount;
int dailyRewardedCount;
int dailyRewardedInterstitialCount;
int dailyAppOpenCount;
int validQuizCompletedCount;
int freeLessonCompletedCount;
int appLaunchCount;

bool isFullScreenAdShowing;
bool isQuizTaking;
bool isVideoPlaying;
bool isPaymentFlowActive;
```

Rule chung:

* Chỉ một full-screen ad được mở.
* Rewarded do user chủ động mở được ưu tiên.
* Sau Rewarded hoặc Rewarded Interstitial, không mở Interstitial ngay.
* Sau App Open, không mở Interstitial trong cooldown chung.
* Ad show fail không tăng count.
* Count chỉ tăng khi ad thực sự hiển thị hoặc ghi nhận impression.
* Daily count reset theo ngày local.
* Không dùng daily count local để bảo vệ nghiệp vụ có chi phí cao.

---

# 14. AdManager

Tạo:

```text
lib/core/ads/ad_manager.dart
```

Quản lý:

```dart
InterstitialAd? _interstitialAd;
RewardedAd? _rewardedAd;
RewardedInterstitialAd? _rewardedInterstitialAd;

bool _isLoadingInterstitial;
bool _isLoadingRewarded;
bool _isLoadingRewardedInterstitial;
```

Interface:

```dart
enum AdShowResult {
  shownAndDismissed,
  notReady,
  blockedByFrequency,
  blockedByScreen,
  alreadyShowing,
  rewardEarned,
  dismissedWithoutReward,
  failedToShow,
}
```

Methods:

```dart
Future<void> preloadFullScreenAds();

Future<AdShowResult> showInterstitialIfAllowed();

Future<AdShowResult> showRewarded({
  required Future<void> Function(RewardItem reward) onRewardEarned,
});

Future<AdShowResult> showRewardedInterstitial({
  required Future<void> Function(RewardItem reward) onRewardEarned,
});
```

Yêu cầu:

* Dùng `Completer`.
* Future chỉ complete sau dismiss hoặc fail.
* Không return ngay sau `show()`.
* Dispose sau dismiss hoặc fail.
* Preload lại quảng cáo mới.
* Reward callback chỉ xử lý một lần.
* Không cộng reward khi user đóng sớm.
* Không mở hai full-screen ad cùng lúc.

---

# 15. AppOpenAdManager

Tạo:

```text
lib/core/ads/app_open_ad_manager.dart
```

Quản lý:

```dart
AppOpenAd? _appOpenAd;
DateTime? _loadedAt;
bool _isLoading;
```

Lắng nghe lifecycle:

```dart
AppLifecycleState.paused
AppLifecycleState.resumed
```

Khi paused:

```text
Lưu backgroundStartedAt.
```

Khi resumed:

Kiểm tra:

* App Open enabled.
* Đã launch tối thiểu 3 lần.
* Background ít nhất 5 phút.
* Không ở auth/payment/quiz/video.
* Không có full-screen ad.
* Chưa quá daily cap.
* App Open trước đó cách ít nhất 4 giờ.
* Ad chưa quá 4 giờ từ khi load.

Nếu không đủ điều kiện:

```text
Không show.
```

Sau dismiss hoặc fail:

* Dispose.
* Clear reference.
* Preload lại.
* Không show Interstitial ngay sau đó.

---

# 16. Rewarded Interstitial intro

Tạo:

```text
lib/core/ads/widgets/rewarded_interstitial_intro_dialog.dart
```

Dialog phải nhận:

```dart
title
description
rewardText
onContinue
```

Bắt buộc có:

```text
Bỏ qua
Xem quảng cáo
```

Không tự động gọi ad khi dialog mở.

Không làm nút bỏ qua khó nhìn hoặc khó bấm.

---

# 17. Chat AI quota

Tạo:

```text
lib/core/ads/chat_ai_quota_manager.dart
```

Rule:

```text
5 lượt miễn phí/ngày.
Rewarded: +3 lượt.
Rewarded Interstitial từ Quiz Result: +1 lượt.
Rewarded tối đa 3 lần/ngày.
Rewarded Interstitial tối đa 2 lần/ngày.
```

Không giảm quota:

* Khi text rỗng.
* Khi API chưa thực sự gửi.
* Khi send bị chặn trước request.

Không cộng reward:

* Khi đóng sớm.
* Khi callback lặp.
* Khi reward transaction đã xử lý.

Nếu AI có chi phí đáng kể, backend phải trở thành source of truth. Local storage chỉ đủ cho UX, không chống được reinstall hoặc đổi thiết bị.

---

# 18. Không quảng cáo tại màn cấm

Không thêm quảng cáo trong:

```text
lib/modules/auth/**
lib/modules/payment/**
lib/modules/assessment/screen/quiz_taking_screen.dart
```

Không quảng cáo khi:

* Video đang phát.
* User nhập form.
* OTP.
* Payment.
* Camera/file picker vừa đóng.
* System permission vừa trả kết quả.
* Full-screen ad khác đang active.

---

# 19. Test bắt buộc

## Unit test

### Frequency

```text
Không Interstitial trong 3 phút đầu.
Cooldown 5 phút.
Tối đa 3/session.
Tối đa 6/day.
Quiz đầu tiên không có Interstitial.
Sau mỗi 2 quiz hợp lệ mới xét.
Quiz dưới 2 phút không tính.
Lesson Interstitial sau mỗi 3 lesson.
Show fail không tăng count.
Hai full-screen ad không mở đồng thời.
```

### App Open

```text
Không hiện lần chạy đầu.
Không hiện trước 3 app launches.
Không hiện nếu background dưới 5 phút.
Không hiện trong quiz.
Không hiện trong video.
Không hiện trong payment.
Không dùng ad đã load quá 4 giờ.
Không vượt 3 lần/ngày.
```

### Reward

```text
Rewarded cộng 3 lượt.
Rewarded Interstitial cộng 1 lượt.
Đóng sớm không cộng.
Callback lặp không cộng hai lần.
Đạt daily cap thì không cho mở tiếp.
```

### List placement

```text
Course:
0–5 item → 0 Native
6–11 item → 1 Native
12+ item → 2 Native tối đa

Search:
5 item → 0 Native
6+ item → 1 Native sau item 5

Quiz:
5 item → 0 Native
6+ item → 1 Native sau item 5

Không mất item.
Không lặp item.
Không out-of-range.
```

## Widget test

```text
Native Ad dispose đúng.
Banner load fail không để khoảng trống.
Purchased course không có ad.
Quiz Taking không có ad.
Payment không có ad.
Search empty/loading/error không có ad.
Rewarded Interstitial có intro và nút skip.
```

## Android manual test

```text
App ID production đúng.
Tất cả 6 Ad Unit ID Android đúng.
Native Factory đăng ký thành công.
Native layout không lỗi.
Banner đúng chiều rộng.
Interstitial dismiss rồi mới navigation.
Rewarded cộng đúng reward.
Rewarded Interstitial có intro.
App Open không xuất hiện sai màn.
Release AAB build thành công.
```

## iOS manual test

```text
GADApplicationIdentifier đúng.
Tất cả 6 Ad Unit ID iOS đúng.
Native Factory đăng ký thành công.
Native view có width/height rõ ràng.
Banner đúng safe area.
Full-screen callback hoạt động.
App Open lifecycle đúng.
Reward không cộng hai lần.
IPA archive thành công.
```

---

# 20. AdMob Console cần tạo

Android:

```text
1 Android AdMob App
1 Banner Ad Unit
1 Native Ad Unit
1 Interstitial Ad Unit
1 Rewarded Ad Unit
1 Rewarded Interstitial Ad Unit
1 App Open Ad Unit
```

iOS:

```text
1 iOS AdMob App
1 Banner Ad Unit
1 Native Ad Unit
1 Interstitial Ad Unit
1 Rewarded Ad Unit
1 Rewarded Interstitial Ad Unit
1 App Open Ad Unit
```

Android và iOS không dùng chung Ad Unit ID.

---

# 21. Build commands

```bash
flutter pub get
flutter analyze
flutter test
```

Android:

```bash
flutter build apk --debug
flutter build appbundle --release
```

iOS:

```bash
cd ios
pod install
cd ..

flutter build ios --debug
flutter build ipa --release
```

Nếu dùng FVM, thay `flutter` bằng:

```bash
fvm flutter
```

---

# 22. Definition of Done

Task hoàn thành khi:

```text
[ ] Có đủ 6 định dạng quảng cáo.
[ ] Không còn Native placeholder.
[ ] Native Ad chạy thật trên Android.
[ ] Native Ad chạy thật trên iOS.
[ ] Android production App ID đã cấu hình.
[ ] iOS production App ID đã cấu hình.
[ ] Có đủ 6 production Ad Unit ID cho Android.
[ ] Có đủ 6 production Ad Unit ID cho iOS.
[ ] Tất cả ID nằm tại admob_config.dart.
[ ] Không có ID rải trong screen.
[ ] Banner placement đúng.
[ ] Native placement đúng.
[ ] Interstitial frequency đúng.
[ ] Rewarded Chat quota đúng.
[ ] Rewarded Interstitial có intro và skip.
[ ] App Open không hiện tại màn bị cấm.
[ ] Không có ad trong auth.
[ ] Không có ad trong payment.
[ ] Không có ad trong Quiz Taking.
[ ] Không có ad khi video đang phát.
[ ] Full-screen ad không mở chồng.
[ ] Ad lỗi không làm app crash.
[ ] flutter analyze pass.
[ ] flutter test pass.
[ ] Android AAB build pass.
[ ] iOS IPA/archive config pass.
[ ] Có hướng dẫn thay toàn bộ production ID.
```

---

# 23. Yêu cầu báo cáo của agent

Sau khi triển khai, agent phải trả về:

1. Danh sách file tạo mới.
2. Danh sách file chỉnh sửa.
3. Version `google_mobile_ads` được sử dụng.
4. Danh sách sáu Ad Unit ID Android cần điền.
5. Danh sách sáu Ad Unit ID iOS cần điền.
6. Kết quả `flutter analyze`.
7. Kết quả `flutter test`.
8. Kết quả Android build.
9. Kết quả iOS build.
10. Placement đã tích hợp.
11. Các bước phải thực hiện trên AdMob Console.
12. Những phần chưa thể xác minh.
