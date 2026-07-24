import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/core/ads/admob_config.dart';
import 'package:ed_tech/core/ads/widgets/native_ad_widget.dart';
import 'package:ed_tech/core/theme/app_colors.dart';
import 'package:ed_tech/core/theme/app_text_styles.dart';
import 'package:ed_tech/core/theme/app_pad.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:ed_tech/modules/course/bloc/course_cubit.dart';
import 'package:ed_tech/modules/home/model/course_response.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class CourseListItem extends StatelessWidget {
  const CourseListItem({
    super.key,
    required this.title,
    required this.instructor,
    required this.price,
    required this.duration,
    this.imageUrl,
    this.onTap,
    this.rating,
    this.discountAmount,
    this.showPrice = true,
  });

  final String title;
  final String instructor;
  final String price;
  final String duration;
  final String? imageUrl;
  final VoidCallback? onTap;
  final double? rating;
  final String? discountAmount;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        showPrice &&
        discountAmount != null &&
        double.tryParse(discountAmount!) != null &&
        double.parse(discountAmount!) > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 12,
              color: Color.fromRGBO(0, 0, 0, 0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.colorF4F3FD,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child:
                        imageUrl != null
                            ? Image.network(
                              imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.colorB8B8D2,
                                    size: 48,
                                  ),
                                );
                              },
                            )
                            : Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: AppColors.colorB8B8D2,
                                size: 48,
                              ),
                            ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.colorFF6905,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${double.parse(discountAmount!).formatCurrency()}',
                        style: AppTextStyles.textContent4.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.textMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.colorB8B8D2,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          instructor,
                          style: AppTextStyles.text.copyWith(
                            color: AppColors.colorB8B8D2,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (rating != null && rating! > 0) ...[
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFFFA927),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: AppTextStyles.textMedium.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.colorFFEBF0,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: AppColors.colorFF6905,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration,
                                  style: AppTextStyles.textContent4.copyWith(
                                    color: AppColors.colorFF6905,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (showPrice)
                        Text(
                          price,
                          style: AppTextStyles.textMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourseListWidget extends StatelessWidget {
  const CourseListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserData?>(
      valueListenable: UserService.instance.userDataNotifier,
      builder: (context, userData, _) {
        final isPayment =
            userData?.isPayment?.trim().toUpperCase() ??
            UserService.instance.isPayment?.trim().toUpperCase();
        final showPrice = isPayment == 'Y';

        return BlocBuilder<CourseCubit, CourseState>(
          builder: (context, state) {
            if (state is CourseListProgress) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is CourseListError) {
              return Padding(
                padding: AppPad.h24,
                child: Center(
                  child: Text(
                    state.message,
                    style: AppTextStyles.text.copyWith(
                      color: AppColors.coolGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (state is CourseListSuccess) {
              final courses = state.courses;

              if (courses.isEmpty) {
                return Padding(
                  padding: AppPad.h24,
                  child: Center(
                    child: Text(
                      'course.no_courses'.tr(),
                      style: AppTextStyles.text.copyWith(
                        color: AppColors.coolGray,
                      ),
                    ),
                  ),
                );
              }

              return Padding(
                padding: AppPad.h24,
                child: Column(
                  children: _buildCourseListWithAds(courses, showPrice, context),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  void _navigateToCourseDetail(BuildContext context, DataCourse course) {
    Navigator.pushNamed(
      context,
      CourseDetailScreen.routeName,
      arguments: {
        'courseId': course.courseId ?? '',
        'title': course.title ?? 'Untitled Course',
        'instructor': course.teacher?.toString() ?? 'Unknown',
        'price': course.price ?? '0',
        'duration':
            course.courseDuration != null ? '${course.courseDuration}h' : '0h',
        'imageUrl': course.thumbnailUrl?.toString(),
        'description':
            course.courseDescription?.toString() ?? course.description,
      },
    );
  }

  List<Widget> _buildCourseListWithAds(
    List<DataCourse> courses,
    bool showPrice,
    BuildContext context,
  ) {
    final widgets = <Widget>[];
    final interval = AdMobConfig.courseListNativeInterval;
    final maxAds = AdMobConfig.courseListMaximumNativeAds;
    int adCount = 0;

    for (int i = 0; i < courses.length; i++) {
      final course = courses[i];
      widgets.add(
        CourseListItem(
          title: course.title ?? 'Untitled Course',
          instructor: course.teacher?.toString() ?? 'Unknown',
          price:
              course.price != null
                  ? course.price.formatCurrency()
                  : 'Free',
          duration:
              course.courseDuration != null
                  ? '${course.courseDuration} hours'
                  : '0 hours',
          imageUrl: course.thumbnailUrl?.toString(),
          rating: course.rating,
          discountAmount: course.discountAmount,
          showPrice: showPrice,
          onTap: () => _navigateToCourseDetail(context, course),
        ),
      );

      // Insert native ad after every `interval` items
      if (adCount < maxAds && (i + 1) % interval == 0 && i < courses.length - 1) {
        widgets.add(
          NativeAdWidget(
            key: ValueKey('native_ad_course_$i'),
            height: 120,
          ),
        );
        adCount++;
      }
    }

    return widgets;
  }
}
