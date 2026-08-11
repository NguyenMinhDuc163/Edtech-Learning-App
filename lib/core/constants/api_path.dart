import 'package:envied/envied.dart';

import 'environment_files.dart';

part 'api_path.g.dart';

@Envied(path: pathToEnv, requireEnvFile: true)
class ApiPath {
  /// Base URL
  @EnviedField(varName: 'BASE_URL', obfuscate: true)
  static String baseUrl = _ApiPath.baseUrl;
  // static String baseUrl = "http://172.17.9.122:3000";
  @EnviedField(varName: 'REGISTER_ID', obfuscate: true)
  static String registerId = _ApiPath.registerId;
  @EnviedField(varName: 'REVENUECAT_IOS_PUBLIC_API_KEY', obfuscate: true)
  static String revenueCatIosPublicApiKey = _ApiPath.revenueCatIosPublicApiKey;
  @EnviedField(varName: 'REVENUECAT_ANDROID_PUBLIC_API_KEY', obfuscate: true)
  static String revenueCatAndroidPublicApiKey = _ApiPath.revenueCatAndroidPublicApiKey;

  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/password/forgot';
  static const String changePassword = '/auth/password/change';
  static const String publicCourse = '/student/courses';
  static const String verifyOtp = '/auth/verif11y-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String loginSocial = '/auth/google/login';
  static const String checkUserName = '/auth/check-username-exist';
  static const String checkMail = '/auth/check-email-exist';
  static const String chatBot = '/chat/ai';
  static const String chatSessions = '/chat/sessions';
  static const String listQuiz = '/student/quiz/list';
  static const String quizDetail = '/student/quiz/detail';
  static const String submitQuiz = '/student/quiz/submit';
  static const String quizHistory = '/student/quiz/history';
  static const String searchCourses = '/search/courses';
  static const String searchHistory = '/search/history';
  static const String searchAutocomplete = '/search/autocomplete';
  static const String createPayment = '/api/create-qr';
  static const String mobileIapConfig = '/api/mobile-iap/config';
  static const String mobileIapSync = '/api/mobile-iap/sync';
  static const String mobileIapStatus = '/api/mobile-iap/status';
  static const String myPayments = '/api/my-payments';
  static const String studentRegistrations = '/student/registrations';
  static const String createRefund = '/api/refund/create';
  static const String hybridRecommendations = '/recommendations/hybrid';
  static const String courseStats = '/student/courses/stats';
  static const String purchasedCourses = '/courses/purchased/list';
  static const String leaderboard = '/quizzes/leaderboard';
  static const String courseReviews = '/courses';
  static const String coursesList = '/courses/list';
  static const String learningProgress = '/learning/progress';
  static const String updateProfile = '/users/me/profile';
  static const String deleteAccount = '/users/delete';
  static const String chatBase = 'https://ai.nguyenduc.click/base';
}

// TODO trong intercepter => ds api can truyen id
// TODO o trong path chi dinh san ky tu => nhan dien duoc de truyen them id
// TODO tim hieu app error state
