import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/common/app_event_service.dart';
import 'package:ed_tech/core/constants/api_path.dart';
import 'package:ed_tech/core/constants/app_constants.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/data/models/request_method.dart';
import 'package:ed_tech/data/services/auth_service.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/modules/auth/login/model/login_social_response.dart';
import 'package:ed_tech/modules/auth/sign_in/model/login_response.dart';
import 'package:ed_tech/modules/iap/service/revenuecat_service.dart';
import 'package:ed_tech/modules/iap/service/iap_platform.dart';
import 'package:ed_tech/modules/iap/repository/iap_repository.dart';

class SignInRepo {
  final ApiClient apiClient;
  final AuthService authService;

  SignInRepo({required this.apiClient, required this.authService});

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final res = await apiClient.fetch(
      ApiPath.login,
      RequestMethod.post,
      rawData: {"username": username, "password": password},
    );
    if (res.code != 200) {
      throw res.message;
    }

    LoginResponse loginResponse = LoginResponse.fromJson(res.json);

    // Tính thời điểm hết hạn = hiện tại + thời gian cố định
    final currentTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresTime = currentTimeSeconds + AppConst.tokenExpirationSeconds;

    authService.saveToken(
      accessToken: loginResponse.data!.accessToken!,
      refreshToken: loginResponse.data!.refreshToken!,
      tokenExpiresTime: expiresTime,
    );

    if (loginResponse.data?.user != null) {
      final user = loginResponse.data!.user!;
      await UserService.instance.saveUserData(
        UserData(
          id: user.id ?? '',
          username: user.username ?? '',
          email: user.email ?? '',
          role: user.role ?? 'student',
          isPayment: loginResponse.data!.isPayment,
          isAds: loginResponse.data!.isAds,
          fullName: user.fullName,
          avatarUrl: user.avatarUrl,
          phone: user.phone,
          grade: user.grade,
          subjectSpecialty: user.subjectSpecialty,
          certificates:
              user.certificates
                  ?.map(
                    (cert) => CertificateData(
                      id: cert.id,
                      title: cert.title,
                      description: cert.description,
                      issuedBy: cert.issuedBy,
                      issuedAt: cert.issuedAt,
                      expiresAt: cert.expiresAt,
                      fileUrl: cert.fileUrl,
                      createdAt: cert.createdAt,
                      updatedAt: cert.updatedAt,
                    ),
                  )
                  .toList(),
        ),
      );
    }
    await _initializeIap();
  }

  Future<bool> loginSocial({required String token}) async {
    final res = await apiClient.fetch(
      ApiPath.loginSocial,
      RequestMethod.post,
      rawData: {"idToken": token},
    );

    LoginSocialResponse loginSocialResponse = LoginSocialResponse.fromJson(
      res.data,
    );

    if (res.code != 200) {
      throw res.message;
    }
    final authService = AuthService.instance;

    // Tính thời điểm hết hạn = hiện tại + thời gian cố định
    final currentTimeSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresTime = currentTimeSeconds + AppConst.tokenExpirationSeconds;

    authService.saveToken(
      accessToken: loginSocialResponse.accessToken!,
      refreshToken: loginSocialResponse.refreshToken!,
      tokenExpiresTime: expiresTime,
    );

    await UserService.instance.saveUserData(
      UserData(
        id: loginSocialResponse.id ?? '',
        username: loginSocialResponse.email ?? loginSocialResponse.name ?? '',
        email: loginSocialResponse.email ?? '',
        role: loginSocialResponse.role ?? 'student',
        fullName: loginSocialResponse.name,
        avatarUrl: loginSocialResponse.image,
        phone: loginSocialResponse.phone,
      ),
    );
    await _initializeIap();

    return res.code == 200;
  }

  Future<void> _initializeIap() async {
    final platform = IapPlatform.apiValue;
    if (platform == null) return;
    try {
      final config = await IapRepository(
        apiClient: apiClient,
      ).getConfig(platform);
      await RevenueCatService.instance.configure(config);
    } catch (_) {
      // Checkout retries initialization and surfaces a user-facing error.
    }
  }

  Future<void> logout() async {
    try {
      authService.logoutOnServer();
      authService.invalid();
      await UserService.instance.clearUserData();
      await RevenueCatService.instance.clearLocalIdentity();
      AppEventService.didUserCompleteFirstExperience;
    } catch (e) {
      throw Exception('${'login.logout_error'.tr()}: $e');
    }
  }

  Future<String> deleteAccount() async {
    final res = await apiClient.fetch(
      ApiPath.deleteAccount,
      RequestMethod.post,
    );

    if (res.status != 200) {
      throw res.message;
    }

    final data = res.data;
    final message = data['message'] ?? res.message;

    await authService.invalid();
    await UserService.instance.clearUserData();
    await RevenueCatService.instance.clearLocalIdentity();
    await AppEventService.notifyUserSignOut();

    return message;
  }
}
