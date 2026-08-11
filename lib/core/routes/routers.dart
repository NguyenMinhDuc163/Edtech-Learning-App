import 'package:disposable_provider/disposable_provider.dart';
import 'package:ed_tech/core/public/global_utils.dart';
import 'package:ed_tech/core/theme/app_text_styles.dart';
import 'package:ed_tech/core/widgets/template/function_screen_template.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/modules/assessment/bloc/quiz_detail_controller.dart';
import 'package:ed_tech/modules/assessment/bloc/quiz_taking_controller.dart';
import 'package:ed_tech/modules/assessment/bloc/quiz_taking_cubit.dart';
import 'package:ed_tech/modules/assessment/bloc/quiz_history_cubit.dart';
import 'package:ed_tech/modules/assessment/bloc/leaderboard_cubit.dart';
import 'package:ed_tech/modules/assessment/bloc/leaderboard_controller.dart';
import 'package:ed_tech/modules/assessment/repository/quiz_repo.dart';
import 'package:ed_tech/modules/assessment/screen/quiz_detail_screen.dart';
import 'package:ed_tech/modules/assessment/screen/quiz_result_screen.dart';
import 'package:ed_tech/modules/assessment/screen/quiz_result_detail_screen.dart';
import 'package:ed_tech/modules/assessment/screen/quiz_taking_screen.dart';
import 'package:ed_tech/modules/assessment/screen/leaderboard_screen.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/forgot_pass_controller.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/forgot_pass_cubit.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/reset_pass_controller.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/reset_pass_cubit.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/verify_otp_controller.dart';
import 'package:ed_tech/modules/auth/forgot_password/bloc/verify_otp_cubit.dart';
import 'package:ed_tech/modules/auth/forgot_password/repository/forgot_pass_repo.dart';
import 'package:ed_tech/modules/auth/forgot_password/screen/forgot_password_screen.dart';
import 'package:ed_tech/modules/auth/forgot_password/screen/reset_password_screen.dart';
import 'package:ed_tech/modules/auth/forgot_password/screen/verify_screen.dart';
import 'package:ed_tech/modules/auth/initial/screen/onboarding_screen.dart';
import 'package:ed_tech/modules/auth/initial/screen/splash_screen.dart';
import 'package:ed_tech/modules/auth/login/bloc/login_controller.dart';
import 'package:ed_tech/modules/auth/login/screen/login_screen.dart';
import 'package:ed_tech/modules/auth/sign_in/bloc/sign_in_controller.dart';
import 'package:ed_tech/modules/auth/sign_in/screen/sign_in_screen.dart';
import 'package:ed_tech/modules/profile/bloc/profile_controller.dart';
import 'package:ed_tech/modules/profile/bloc/edit_profile_controller.dart';
import 'package:ed_tech/modules/profile/repository/profile_repo.dart';
import 'package:ed_tech/modules/profile/screen/profile_screen.dart';
import 'package:ed_tech/modules/profile/screen/edit_profile_screen.dart';
import 'package:ed_tech/modules/auth/sign_up/bloc/sign_up_controller.dart';
import 'package:ed_tech/modules/auth/sign_up/bloc/sign_up_cubit.dart';
import 'package:ed_tech/modules/auth/sign_up/repository/sign_up_repo.dart';
import 'package:ed_tech/modules/auth/sign_up/screen/sign_up_screen.dart';
import 'package:ed_tech/modules/course/screen/course_screen.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:ed_tech/modules/course/screen/search_course_screen.dart';
import 'package:ed_tech/modules/course/bloc/course_controller.dart';
import 'package:ed_tech/modules/course/bloc/course_cubit.dart';
import 'package:ed_tech/modules/course/bloc/search_course_controller.dart';
import 'package:ed_tech/modules/course/bloc/search_course_cubit.dart';
import 'package:ed_tech/modules/course/bloc/filter_course_cubit.dart';
import 'package:ed_tech/modules/course/repository/course_repo.dart';
import 'package:ed_tech/modules/course/repository/search_course_repo.dart';
import 'package:ed_tech/modules/dashboard/screen/dashboard_screen.dart';
import 'package:ed_tech/modules/home/bloc/home_cubit.dart';
import 'package:ed_tech/modules/home/bloc/home_controller.dart';
import 'package:ed_tech/modules/home/repository/home_repo.dart';
import 'package:ed_tech/modules/home/screen/home_screen.dart';
import 'package:ed_tech/modules/home/screen/recommended_courses_screen.dart';
import 'package:ed_tech/modules/message/screen/chat_bot_screen.dart';
import 'package:ed_tech/modules/message/screen/chat_history_screen.dart';
import 'package:ed_tech/modules/message/bloc/chat_history_cubit.dart';
import 'package:ed_tech/modules/message/bloc/chatbot_cubit.dart';
import 'package:ed_tech/modules/message/bloc/chat_controller.dart';
import 'package:ed_tech/modules/message/repository/chat_bot_repo.dart';
import 'package:ed_tech/modules/message/repository/chat_sessions_repo.dart';
import 'package:ed_tech/modules/payment/screen/address_form_screen.dart';
import 'package:ed_tech/modules/payment/screen/confirm_screen.dart';
import 'package:ed_tech/modules/payment/screen/new_card_screen.dart';
import 'package:ed_tech/modules/payment/screen/payment_method_screen.dart';
import 'package:ed_tech/modules/payment/screen/order_confirmation_screen.dart';
import 'package:ed_tech/modules/payment/screen/payment_webview_screen.dart';
import 'package:ed_tech/modules/payment/screen/my_payments_screen.dart';
import 'package:ed_tech/modules/payment/screen/invoice_detail_screen.dart';
import 'package:ed_tech/modules/payment/bloc/payment_cubit.dart';
import 'package:ed_tech/modules/payment/repository/payment_repo.dart';
import 'package:ed_tech/modules/iap/bloc/iap_cubit.dart';
import 'package:ed_tech/modules/iap/repository/iap_repository.dart';
import 'package:ed_tech/modules/purchased_courses/screen/purchased_courses_screen.dart';
import 'package:ed_tech/modules/purchased_courses/bloc/purchased_course_cubit.dart';
import 'package:ed_tech/modules/purchased_courses/repository/purchased_course_repo.dart';
import 'package:ed_tech/modules/ranking/screen/ranking_screen.dart';
import 'package:ed_tech/modules/reviews/screen/add_review_screen.dart';
import 'package:ed_tech/modules/reviews/screen/review_screen.dart';
import 'package:ed_tech/modules/reviews/bloc/review_cubit.dart';
import 'package:ed_tech/modules/reviews/repository/review_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//part of in dart
class Routers {
  static Map<String, WidgetBuilder> routes = {
    OnboardingScreen.routeName: (context) => const OnboardingScreen(),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    GlobalUtils.ROUTES = settings.name;
    // TODO Task 1: hiển thị log khi chuyển màn

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case HomeScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => HomeRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) => HomeCubit(repo: context.read<HomeRepo>()),
                  child: DisposableProvider(
                    create: (_) => HomeController(),
                    child: HomeScreen(),
                  ),
                ),
              ),
        );
      case DashboardScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DashboardScreen(),
        );
      case LoginScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => DisposableProvider(
                create: (BuildContext context) {
                  return LoginController();
                },
                child: LoginScreen(),
              ),
        );
      case SignUpScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => SignUpRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          SignUpCubit(repo: context.read<SignUpRepo>()),
                  child: DisposableProvider(
                    create: (BuildContext context) {
                      return SignUpController();
                    },
                    child: SignUpScreen(),
                  ),
                ),
              ),
        );
      case SignInScreen.routeName:
        final Map<String, String>? prefillData =
            settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => DisposableProvider(
                create: (BuildContext context) {
                  return SignInController(prefillData: prefillData);
                },
                child: SignInScreen(),
              ),
        );
      case ProfileScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (_) => IapRepository(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          IapCubit(repository: context.read<IapRepository>()),
                  child: DisposableProvider(
                    create: (_) => ProfileController(),
                    child: const ProfileScreen(),
                  ),
                ),
              ),
        );
      case EditProfileScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ProfileRepo(apiClient: ApiClient()),
                child: DisposableProvider(
                  create: (BuildContext context) {
                    return EditProfileController(
                      profileRepo: context.read<ProfileRepo>(),
                    );
                  },
                  child: EditProfileScreen(),
                ),
              ),
        );
      case ForgotPasswordScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ForgotPassRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          ForgotPassCubit(repo: context.read<ForgotPassRepo>()),
                  child: DisposableProvider(
                    create: (BuildContext context) {
                      return ForgotPassController();
                    },
                    child: ForgotPasswordScreen(),
                  ),
                ),
              ),
        );

      case VerifyScreen.routeName:
        final Map<String, String>? data =
            settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ForgotPassRepo(apiClient: ApiClient()),

                child: BlocProvider(
                  create:
                      (context) =>
                          VerifyOtpCubit(repo: context.read<ForgotPassRepo>()),

                  child: DisposableProvider(
                    create: (BuildContext context) {
                      return VerifyOtpController(dataUser: data);
                    },
                    child: VerifyScreen(),
                  ),
                ),
              ),
        );

      case ResetPasswordScreen.routeName:
        final Map<String, String>? data =
            settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ForgotPassRepo(apiClient: ApiClient()),

                child: BlocProvider(
                  create:
                      (context) =>
                          ResetPassCubit(repo: context.read<ForgotPassRepo>()),

                  child: DisposableProvider(
                    create: (BuildContext context) {
                      return ResetPassController(dataUser: data);
                    },
                    child: ResetPasswordScreen(),
                  ),
                ),
              ),
        );

      case CourseScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider(
                    create: (context) => CourseRepo(apiClient: ApiClient()),
                  ),
                  RepositoryProvider(
                    create:
                        (context) => SearchCourseRepo(apiClient: ApiClient()),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create:
                          (context) =>
                              CourseCubit(repo: context.read<CourseRepo>()),
                    ),
                    BlocProvider(
                      create:
                          (context) => FilterCourseCubit(
                            repo: context.read<SearchCourseRepo>(),
                          ),
                    ),
                  ],
                  child: DisposableProvider(
                    create: (_) => CourseController(),
                    child: const CourseScreen(),
                  ),
                ),
              ),
        );
      case CourseDetailScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider(
                    create: (_) => CourseRepo(apiClient: ApiClient()),
                  ),
                  RepositoryProvider(
                    create: (_) => IapRepository(apiClient: ApiClient()),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create:
                          (context) =>
                              CourseCubit(repo: context.read<CourseRepo>()),
                    ),
                    BlocProvider(
                      create:
                          (context) => IapCubit(
                            repository: context.read<IapRepository>(),
                          ),
                    ),
                  ],
                  child: const CourseDetailScreen(),
                ),
              ),
        );
      case SearchCourseScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => SearchCourseRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) => SearchCourseCubit(
                        repo: context.read<SearchCourseRepo>(),
                      ),
                  child: DisposableProvider(
                    create: (_) => SearchCourseController(),
                    child: const SearchCourseScreen(),
                  ),
                ),
              ),
        );
      case ReviewScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ReviewRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          ReviewCubit(repo: context.read<ReviewRepo>()),
                  child: const ReviewScreen(),
                ),
              ),
        );
      case AddressFormScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddressFormScreen(),
        );
      case ConfirmScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ConfirmScreen(),
        );
      case NewCardScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => NewCardScreen(),
        );
      case PaymentMethodScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PaymentMethodScreen(),
        );
      case OrderConfirmationScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) =>
                  kIsWeb
                      ? RepositoryProvider(
                        create: (_) => PaymentRepo(apiClient: ApiClient()),
                        child: BlocProvider(
                          create:
                              (context) => PaymentCubit(
                                repo: context.read<PaymentRepo>(),
                              ),
                          child: const OrderConfirmationScreen(),
                        ),
                      )
                      : RepositoryProvider(
                        create: (_) => IapRepository(apiClient: ApiClient()),
                        child: BlocProvider(
                          create:
                              (context) => IapCubit(
                                repository: context.read<IapRepository>(),
                              ),
                          child: const OrderConfirmationScreen(),
                        ),
                      ),
        );
      case PaymentWebViewScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PaymentWebViewScreen(),
        );
      case MyPaymentsScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => PaymentRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          PaymentCubit(repo: context.read<PaymentRepo>()),
                  child: const MyPaymentsScreen(),
                ),
              ),
        );
      case InvoiceDetailScreen.routeName:
        final paymentId = settings.arguments as String?;
        if (paymentId == null) {
          return MaterialPageRoute(
            settings: settings,
            builder:
                (_) => const Scaffold(
                  body: Center(child: Text('Payment ID is required')),
                ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => PaymentRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          PaymentCubit(repo: context.read<PaymentRepo>()),
                  child: InvoiceDetailScreen(paymentId: paymentId),
                ),
              ),
        );
      case AddReviewScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => ReviewRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          ReviewCubit(repo: context.read<ReviewRepo>()),
                  child: const AddReviewScreen(),
                ),
              ),
        );
      case ChatBotScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider(
                    create: (context) => ChatBotRepo(apiClient: ApiClient()),
                  ),
                  RepositoryProvider(
                    create:
                        (context) => ChatSessionsRepo(apiClient: ApiClient()),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create:
                          (context) =>
                              ChatbotCubit(repo: context.read<ChatBotRepo>()),
                    ),
                    BlocProvider(
                      create:
                          (context) => ChatHistoryCubit(
                            repo: context.read<ChatSessionsRepo>(),
                          ),
                    ),
                  ],
                  child: DisposableProvider(
                    create: (_) => ChatController(),
                    child: const ChatBotScreen(),
                  ),
                ),
              ),
        );
      case ChatHistoryScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => MultiRepositoryProvider(
                providers: [
                  RepositoryProvider(
                    create: (context) => ChatBotRepo(apiClient: ApiClient()),
                  ),
                  RepositoryProvider(
                    create:
                        (context) => ChatSessionsRepo(apiClient: ApiClient()),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create:
                          (context) =>
                              ChatbotCubit(repo: context.read<ChatBotRepo>()),
                    ),
                    BlocProvider(
                      create:
                          (context) => ChatHistoryCubit(
                            repo: context.read<ChatSessionsRepo>(),
                          ),
                    ),
                  ],
                  child: DisposableProvider(
                    create: (_) => ChatController(),
                    child: const ChatHistoryScreen(),
                  ),
                ),
              ),
        );
      case QuizDetailScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => QuizRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          QuizHistoryCubit(repo: context.read<QuizRepo>()),
                  child: DisposableProvider(
                    create: (_) => QuizDetailController(),
                    child: QuizDetailScreen(),
                  ),
                ),
              ),
        );
      case QuizResultScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuizResultScreen(),
        );
      case QuizResultDetailScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuizResultDetailScreen(),
        );
      case QuizTakingScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => QuizRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          QuizTakingCubit(repo: context.read<QuizRepo>()),
                  child: DisposableProvider(
                    create: (_) => QuizTakingController(),
                    child: QuizTakingScreen(),
                  ),
                ),
              ),
        );
      case RankingScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RankingScreen(),
        );
      case PurchasedCoursesScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create:
                    (context) => PurchasedCourseRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) => PurchasedCourseCubit(
                        repo: context.read<PurchasedCourseRepo>(),
                      ),
                  child: const PurchasedCoursesScreen(),
                ),
              ),
        );
      case LeaderboardScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => QuizRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          LeaderboardCubit(repo: context.read<QuizRepo>()),
                  child: DisposableProvider(
                    create: (_) => LeaderboardController(),
                    child: const LeaderboardScreen(),
                  ),
                ),
              ),
        );
      case RecommendedCoursesScreen.routeName:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (context) => RepositoryProvider(
                create: (context) => HomeRepo(apiClient: ApiClient()),
                child: BlocProvider(
                  create:
                      (context) =>
                          HomeCubit(repo: context.read<HomeRepo>())
                            ..getProduct(),
                  child: const RecommendedCoursesScreen(),
                ),
              ),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder:
              (_) => FunctionScreenTemplate(
                title: "Chức năng đang trong quá trình phát triển",
                isShowBottomButton: false,
                screen: Center(
                  child: Text(
                    "Chức năng đang trong quá trình phát triển",
                    style: AppTextStyles.text,
                  ),
                ),
              ),
        );
    }
  }
}
