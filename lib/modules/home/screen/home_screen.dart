import 'package:disposable_provider/disposable_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/core/ads/widgets/adaptive_banner_ad_widget.dart';
import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:ed_tech/core/widgets/app_gap.dart';
import 'package:ed_tech/modules/home/bloc/home_controller.dart';
import 'package:ed_tech/modules/home/bloc/home_cubit.dart';
import 'package:ed_tech/modules/home/widgets/home_header.dart';
import 'package:ed_tech/modules/home/widgets/home_promo_carousel.dart';
import 'package:ed_tech/modules/home/widgets/learning_plan_widget.dart';
import 'package:ed_tech/modules/home/widgets/course_suggestions_widget.dart';
import 'package:ed_tech/modules/purchased_courses/screen/purchased_courses_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToQuizTab;
  final VoidCallback? onNavigateToCourseTab;

  const HomeScreen({this.onNavigateToQuizTab, this.onNavigateToCourseTab});
  static const String routeName = '/HomeScreen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _learningProgressKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeCubit>().getProduct();
    });
  }

  Future<void> _scrollToLearningProgress() async {
    final learningProgressContext = _learningProgressKey.currentContext;
    if (learningProgressContext == null) {
      return;
    }

    Scrollable.ensureVisible(
      learningProgressContext,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = DisposableProvider.of<HomeController>(
      context,
    );

    return FunctionScreenTemplate(
      isShowBottomButton: false,
      isShowAppBar: true,
      isShowDrawer: true,
      appbarColor: AppColors.primary,
      actionsWidget: [
        ValueListenableBuilder<bool>(
          valueListenable: controller.isSearchVisible,
          builder: (context, isSearchVisible, child) {
            return ClipRect(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSearchVisible) ...[
                    Container(
                      width: 110,
                      child: TextField(
                        onChanged: controller.updateSearchQuery,
                        style: AppTextStyles.text.copyWith(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'home_screen.search_hint'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                  ],

                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        PurchasedCoursesScreen.routeName,
                      );
                    },
                    child: SvgPicture.asset(
                      IconPath.iconBag,
                      color: AppColors.black50,
                      width: 18,
                      height: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      screen: SingleChildScrollView(
        child: Column(
          children: [
            const HomeHeaderWidget(),
            const AdaptiveBannerAdWidget(),
            AppGap.h12,
            Padding(
              padding: AppPad.h20,
              child: HomePromoCarousel(
                onNavigateToCourseTab: widget.onNavigateToCourseTab,
                onNavigateToQuizTab: widget.onNavigateToQuizTab,
                onNavigateToLearningProgress: _scrollToLearningProgress,
              ),
            ),
            AppGap.h32,
            KeyedSubtree(
              key: _learningProgressKey,
              child: LearningPlanWidget(
                onNavigateToQuizTab: widget.onNavigateToQuizTab,
              ),
            ),
            AppGap.h28,
            const NativeAdWidget(height: 120),
            AppGap.h28,
            const CourseSuggestionsWidget(),
            AppGap.h24,
            const AdaptiveBannerAdWidget(),
            AppGap.h24,
          ],
        ),
      ),
    );
  }
}
