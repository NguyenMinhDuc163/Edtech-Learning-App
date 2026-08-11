import 'package:disposable_provider/disposable_provider.dart';
import 'package:ed_tech/init.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/modules/course/widgets/course_card_widget.dart';
import 'package:ed_tech/modules/course/widgets/course_category_tabs_widget.dart';
import 'package:ed_tech/modules/course/widgets/course_list_widget.dart';
import 'package:ed_tech/modules/course/bloc/course_controller.dart';
import 'package:ed_tech/modules/course/bloc/filter_course_cubit.dart';
import 'package:ed_tech/modules/course/model/search_course_result.dart';
import 'package:ed_tech/modules/course/screen/search_course_screen.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:ed_tech/core/widgets/search_filter_bottom_sheet.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});
  static const String routeName = '/CourseScreen';

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  static const List<String> _categories = [
    'python',
    'reactjs',
    'nestjs',
    'flutter',
    'java',
    'javascript',
  ];
  static const List<String> _durations = [
    '3-8 Hours',
    '8-14 Hours',
    '14-20 Hours',
    '20-24 Hours',
    '24-30 Hours',
  ];
  static const double _minPrice = 0;
  static const double _maxPrice = 500000;

  void _showFilterBottomSheet(BuildContext context) {
    final CourseController controller = DisposableProvider.of<CourseController>(
      context,
    );

    context.showSearchFilterBottomSheet(
      categories: _categories,
      durations: _durations,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      selectedCategories: controller.selectedCategories.value,
      selectedDurations: controller.selectedDurations.value,
      selectedMinPrice: controller.selectedMinPrice.value,
      selectedMaxPrice: controller.selectedMaxPrice.value,
      onApplyFilter: (categories, durations, minPrice, maxPrice) {
        controller.updateFilter(
          categories: categories,
          durations: durations,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );

        Navigator.pop(context);

        controller.setFilteringMode(true);

        context.read<FilterCourseCubit>().filterCourses(
          categories: categories,
          durations: durations,
          minPrice: minPrice,
          maxPrice: maxPrice,
        );
      },
      onClearFilter: () {
        controller.clearFilter();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final CourseController controller = DisposableProvider.of<CourseController>(
      context,
    );

    return FunctionScreenTemplate(
      isShowAppBar: false,
      isShowBottomButton: false,
      screen: ValueListenableBuilder<bool>(
        valueListenable: controller.isFiltering,
        builder: (context, isFiltering, _) {
          if (isFiltering) {
            return Column(
              children: [
                Padding(
                  padding: AppPad.h24.add(AppPad.t24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "home_screen.course".tr(),
                        style: AppTextStyles.textHeader2,
                      ),
                      ValueListenableBuilder<UserData?>(
                        valueListenable: UserService.instance.userDataNotifier,
                        builder: (context, userData, _) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  userData?.avatarUrl != null &&
                                          userData!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(userData.avatarUrl!)
                                      : null,
                              child:
                                  userData?.avatarUrl == null ||
                                          userData!.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: AppPad.h24.add(AppPad.v12),
                  child: _SearchBar(
                    controller: controller,
                    onFilterTap: () => _showFilterBottomSheet(context),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<FilterCourseCubit, FilterCourseState>(
                    builder: (context, state) {
                      if (state is FilterCourseProgress) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is FilterCourseSuccess) {
                        final results = state.results;

                        if (results.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: AppColors.colorB8B8D2.withAlpha(128),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "filter.no_courses_found".tr(),
                                  style: AppTextStyles.text.copyWith(
                                    color: AppColors.colorB8B8D2,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextButton(
                                  onPressed: () {
                                    controller.clearFilter();
                                  },
                                  child: Text(
                                    "filter.clear_filter".tr(),
                                    style: AppTextStyles.textButton.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: AppPad.h24v12,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${results.length} ${"filter.courses_found".tr()}',
                                    style: AppTextStyles.textMedium.copyWith(
                                      color: AppColors.colorB8B8D2,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      controller.clearFilter();
                                    },
                                    child: Text(
                                      "filter.clear".tr(),
                                      style: AppTextStyles.textButton.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  bottom: 16,
                                ),
                                itemCount: results.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final result = results[index];
                                  return _FilterResultCard(
                                    result: result,
                                    onTap:
                                        () => _navigateToCourseDetail(
                                          context,
                                          result,
                                        ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      if (state is FilterCourseError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: AppColors.colorB8B8D2.withAlpha(128),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.message,
                                style: AppTextStyles.text.copyWith(
                                  color: AppColors.colorB8B8D2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () {
                                  controller.clearFilter();
                                },
                                child: Text(
                                  "filter.back_to_courses".tr(),
                                  style: AppTextStyles.textButton.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: AppPad.h24.add(AppPad.t24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "home_screen.course".tr(),
                        style: AppTextStyles.textHeader2,
                      ),
                      ValueListenableBuilder<UserData?>(
                        valueListenable: UserService.instance.userDataNotifier,
                        builder: (context, userData, _) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  userData?.avatarUrl != null &&
                                          userData!.avatarUrl!.isNotEmpty
                                      ? NetworkImage(userData.avatarUrl!)
                                      : null,
                              child:
                                  userData?.avatarUrl == null ||
                                          userData!.avatarUrl!.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: AppPad.h24.add(AppPad.v12),
                  child: _SearchBar(
                    controller: controller,
                    onFilterTap: () => _showFilterBottomSheet(context),
                  ),
                ),
                const SizedBox(height: 20),
                const CourseCardsCarousel(),
                const CourseCategoryTabsWidget(),
                const SizedBox(height: 20),
                const CourseListWidget(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToCourseDetail(
    BuildContext context,
    SearchCourseResult result,
  ) {
    Navigator.pushNamed(
      context,
      CourseDetailScreen.routeName,
      arguments: {
        'courseId': result.courseId ?? '',
        'title': result.title ?? 'course.untitled'.tr(),
        'instructor': 'course.unknown_teacher'.tr(),
        'price': result.price ?? '0',
        'duration': '0h 0m',
        'imageUrl': result.thumbnailUrl,
        'description': result.description,
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onFilterTap});
  final CourseController controller;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorF4F3FD,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.colorB8B8D2),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, SearchCourseScreen.routeName);
              },
              child: AbsorbPointer(
                child: TextField(
                  style: AppTextStyles.text,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'course.search_hint_course'.tr(),
                    hintStyle: AppTextStyles.inputHintText,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: SvgPicture.asset(IconPath.iconFilter, width: 8, height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResultCard extends StatelessWidget {
  final SearchCourseResult result;
  final VoidCallback onTap;

  const _FilterResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const showPrice = false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Color.fromRGBO(0, 0, 0, 0.06),
            ),
            BoxShadow(
              offset: Offset(0, 10),
              blurRadius: 20,
              color: AppColors.shadowBlack15,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.colorF4F3FD,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child:
                    result.thumbnailUrl != null
                        ? Image.network(
                          result.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              color: AppColors.colorB8B8D2,
                              size: 40,
                            );
                          },
                        )
                        : const Icon(
                          Icons.image_not_supported,
                          color: AppColors.colorB8B8D2,
                          size: 40,
                        ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: AppPad.a16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title ?? 'Untitled Course',
                      style: AppTextStyles.textMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (result.description != null) ...[
                      Text(
                        result.description!,
                        style: AppTextStyles.text.copyWith(
                          color: AppColors.coolGray,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        if (showPrice)
                          Text(
                            result.price != null
                                ? result.price.formatCurrency()
                                : 'course.free'.tr(),
                            style: AppTextStyles.textMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        else ...[
                          Text(
                            'course.view_details'.tr(),
                            style: AppTextStyles.textMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
