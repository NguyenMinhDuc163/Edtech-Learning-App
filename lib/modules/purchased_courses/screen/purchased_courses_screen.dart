import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/purchased_courses/bloc/purchased_course_cubit.dart';
import 'package:ed_tech/modules/purchased_courses/bloc/purchased_course_state.dart';
import 'package:ed_tech/modules/purchased_courses/model/purchased_course_response.dart';
import 'package:ed_tech/modules/course/screen/course_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchasedCoursesScreen extends StatefulWidget {
  static const String routeName = '/PurchasedCoursesScreen';

  const PurchasedCoursesScreen({super.key});

  @override
  State<PurchasedCoursesScreen> createState() => _PurchasedCoursesScreenState();
}

class _PurchasedCoursesScreenState extends State<PurchasedCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchasedCourseCubit>().getPurchasedCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FunctionScreenTemplate(
      isShowBottomButton: false,
      isShowAppBar: true,
      isShowDrawer: false,
      backgroundColor: AppColors.background,
      title: 'purchased_courses.title'.tr(),
      screen: BlocBuilder<PurchasedCourseCubit, PurchasedCourseState>(
        builder: (context, state) {
          if (state is PurchasedCourseProgress) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'purchased_courses.loading'.tr(),
                    style: AppTextStyles.textContent2.copyWith(
                      color: AppColors.coolGray,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is PurchasedCourseSuccess) {
            final courses = state.courses;

            if (courses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 80,
                      color: AppColors.coolGray.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'purchased_courses.no_courses'.tr(),
                      style: AppTextStyles.textContent1.copyWith(
                        color: AppColors.coolGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context
                    .read<PurchasedCourseCubit>()
                    .getPurchasedCourses();
              },
              child: ListView.separated(
                padding: AppPad.h16v12,
                itemCount: courses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _PurchasedCourseCard(
                    course: courses[index],
                    showPurchaseDate: true,
                    onTap:
                        () => _navigateToCourseDetail(context, courses[index]),
                  );
                },
              ),
            );
          }

          if (state is PurchasedCourseError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.textContent1.copyWith(
                      color: AppColors.coolGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<PurchasedCourseCubit>()
                          .getPurchasedCourses();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'payment.retry'.tr(),
                      style: AppTextStyles.textContent2.copyWith(
                        color: AppColors.white,
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
    );
  }

  void _navigateToCourseDetail(BuildContext context, PurchasedCourse course) {
    Navigator.pushNamed(
      context,
      CourseDetailScreen.routeName,
      arguments: {
        'courseId': course.courseId ?? '',
        'title': course.title ?? 'course.untitled'.tr(),
        'instructor': course.teacher ?? 'course.unknown_teacher'.tr(),
        'price': course.price ?? '0',
        'duration': course.courseDuration ?? '0h 0m',
        'imageUrl': course.thumbnailUrl,
        'description': course.courseDescription,
      },
    );
  }
}

class _PurchasedCourseCard extends StatelessWidget {
  final PurchasedCourse course;
  final bool showPurchaseDate;
  final VoidCallback onTap;

  const _PurchasedCourseCard({
    required this.course,
    required this.showPurchaseDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = course.progressPercentage;
    final isCompleted = progress >= 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
              color: AppColors.primary.withAlpha(15),
            ),
            const BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 0,
              color: Color(0x0A000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getColorForCategory(course.category),
                        _getColorForCategory(course.category).withAlpha(200),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: _buildThumbnail(),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          color: (isCompleted
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withAlpha(100),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.play_circle_outline,
                          size: 14,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted
                              ? 'purchased_courses.completed'.tr()
                              : 'purchased_courses.in_progress'.tr(),
                          style: AppTextStyles.textContent4.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                    course.title ?? 'course.untitled'.tr(),
                    style: AppTextStyles.textHeader3.copyWith(
                      fontSize: 17,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          course.teacher ?? 'course.unknown_teacher'.tr(),
                          style: AppTextStyles.textContent2.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.colorFF7043.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.colorFF7043,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.courseDuration ?? '0h',
                              style: AppTextStyles.textContent3.copyWith(
                                color: AppColors.colorFF7043,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'purchased_courses.progress'.tr(),
                              style: AppTextStyles.textContent3.copyWith(
                                color: AppColors.coolGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isCompleted
                                        ? AppColors.success
                                        : AppColors.primary)
                                    .withAlpha(26),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${progress.toStringAsFixed(0)}%',
                                style: AppTextStyles.textContent3.copyWith(
                                  color:
                                      isCompleted
                                          ? AppColors.success
                                          : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.silverGray,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showPurchaseDate || course.category != null) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppColors.silverGray, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (showPurchaseDate)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(26),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'purchased_courses.purchased_on'.tr(),
                                    style: AppTextStyles.textContent4.copyWith(
                                      color: AppColors.coolGray,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(course.purchaseDate),
                                    style: AppTextStyles.textContent2.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const Spacer(),
                        if (course.category != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorForCategory(course.category),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(50),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      course.category!,
                                      style: AppTextStyles.textContent3
                                          .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = course.thumbnailUrl ?? '';
    if (url.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              color: AppColors.primary.withAlpha(100),
              size: 60,
            ),
            const SizedBox(height: 8),
            Text(
              course.category ?? 'home_screen.course'.tr(),
              style: AppTextStyles.textContent2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: _getColorForCategory(course.category),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.coolGray.withAlpha(150),
                    size: 50,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'course.image_unavailable'.tr(),
                    style: AppTextStyles.textContent3.copyWith(
                      color: AppColors.coolGray,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withAlpha(20)],
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForCategory(String? category) {
    if (category == null) return const Color(0xFFEFF4FF);

    switch (category.toLowerCase()) {
      case 'lập trình':
      case 'programming':
        return const Color(0xFFEFF4FF);
      case 'thiết kế':
      case 'design':
        return const Color(0xFFF6F9FF);
      case 'kinh doanh':
      case 'business':
        return const Color(0xFFF4FBFF);
      default:
        return const Color(0xFFEFF4FF);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
