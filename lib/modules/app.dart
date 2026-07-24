import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/core/ads/app_open_ad_manager.dart';
import 'package:ed_tech/core/app_authentication.dart';
import 'package:ed_tech/modules/auth/initial/screen/onboarding_screen.dart';
import 'package:ed_tech/modules/auth/login/screen/login_screen.dart';
import 'package:ed_tech/modules/dashboard/screen/dashboard_screen.dart';
import 'package:ed_tech/modules/home/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:ed_tech/core/public/navigation_service.dart';
import 'package:ed_tech/core/routes/routers.dart';
import 'package:ed_tech/core/theme/app_theme.dart';
import 'package:ed_tech/core/theme/theme_cubit.dart';
import 'package:ed_tech/core/theme/locale_cubit.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/data/services/auth_service.dart';
import 'package:ed_tech/modules/auth/sign_in/bloc/sign_in_cubit.dart';
import 'package:ed_tech/modules/auth/sign_in/bloc/sign_in_state.dart';
import 'package:ed_tech/modules/auth/sign_in/screen/sign_in_screen.dart';
import 'package:ed_tech/modules/auth/sign_in/use_case/social_login.dart';

import 'auth/sign_in/repository/sign_in_repo.dart';

class App extends StatefulWidget {
  const App({super.key, required this.authService});
  final AuthService authService;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App>
    with WidgetsBindingObserver
    implements AppAuthenticationBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register observer để listen auth events
    AppAuthenticationBinding.instance?.addObserver(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Unregister observer khi widget dispose
    AppAuthenticationBinding.instance?.removeObserver(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        AppOpenAdManager.instance.onPaused();
        break;
      case AppLifecycleState.resumed:
        AppOpenAdManager.instance.onResumed();
        break;
      default:
        break;
    }
  }

  // Callback khi refresh token hết hạn hoặc authentication failed
  @override
  void didRefershTokenExpired() {
    _navigateToLogin();
  }

  @override
  void didAuthenticationFailed() {
    _navigateToLogin();
  }

  @override
  void didLock() {
    _navigateToLogin();
  }

  @override
  void didAuthenticated() {
    // Không cần xử lý
  }

  @override
  void didUnauthenticated() {
    _navigateToLogin();
  }

  @override
  void didChangeAccessToken() {
    // Không cần xử lý
  }

  void _navigateToLogin() {
    // Clear token
    widget.authService.clearToken();

    // Navigate về login screen
    NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false, // Remove tất cả routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create:
          (context) => SignInRepo(
            apiClient: ApiClient(),
            authService: widget.authService,
          ),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) => SignInCubit(
                  repo: context.read<SignInRepo>(),
                  socialLogin: SocialLogin(repo: context.read<SignInRepo>()),
                ),
          ),
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(create: (context) => LocaleCubit()),
        ],
        child: BlocListener<SignInCubit, SignInState>(
          listener: (context, state) {
            if (state is SignInAuthenticated) {
              NavigationService.navigatorKey.currentState?.pushReplacementNamed(
                DashboardScreen.routeName,
              );
            } else if (state is SignInInitial) {
              NavigationService.navigatorKey.currentState?.pushReplacementNamed(
                SignInScreen.routeName,
              );
            }
          },
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return MaterialApp(
                    builder: (context, child) {
                      return ResponsiveBreakpoints.builder(
                        child: child!,
                        breakpoints: [
                          const Breakpoint(start: 0, end: 450, name: MOBILE),
                          const Breakpoint(start: 451, end: 800, name: TABLET),
                          const Breakpoint(
                            start: 801,
                            end: 1920,
                            name: DESKTOP,
                          ),
                          const Breakpoint(
                            start: 1921,
                            end: double.infinity,
                            name: '4K',
                          ),
                        ],
                      );
                    },
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light(),
                    darkTheme: AppTheme.dark(),
                    themeMode: themeMode,
                    localizationsDelegates: context.localizationDelegates,
                    supportedLocales: context.supportedLocales,
                    locale: locale,
                    routes: Routers.routes,
                    // initialRoute: OnboardingScreen.routeName,
                    onGenerateRoute: Routers.generateRoute,
                    navigatorKey: NavigationService.navigatorKey,
                    navigatorObservers: [NavigationService.routeObserver],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
