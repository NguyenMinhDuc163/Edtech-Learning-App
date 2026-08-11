import 'package:ed_tech/core/error_handling/app_error_state.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/course/model/detail_course.dart';
import 'package:ed_tech/modules/course/repository/course_repo.dart';
import 'package:ed_tech/modules/home/model/course_response.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'course_state.dart';

class CourseCubit extends Cubit<CourseState> {
  final CourseRepo repo;

  CourseCubit({required this.repo}) : super(CourseInitial());

  Future<void> getCourses() async {
    emit(CourseProgress());
    try {
      final courses = await repo.getCourse(id: 0);
      emit(CourseSuccess(courses: courses));
    } catch (e) {
      emit(CourseError(message: AppErrorState.getFriendlyErrorString(e)));
    }
  }

  Future<void> getCourseDetail(String courseId) async {
    emit(CourseDetailProgress());
    try {
      final courseDetail = await repo.getCourseDetail(courseId: courseId);
      emit(CourseDetailSuccess(courseDetail: courseDetail));
    } catch (e) {
      emit(CourseDetailError(message: AppErrorState.getFriendlyErrorString(e)));
    }
  }

  Future<void> createRefundRequest(String courseId, String reason) async {
    emit(RefundRequestProgress());
    try {
      final response = await repo.createRefund(
        courseId: courseId,
        reason: reason,
      );
      final message =
          response.data?.message ?? 'Tạo yêu cầu hoàn tiền thành công';
      emit(RefundRequestSuccess(message: message));
    } catch (e) {
      emit(
        RefundRequestError(message: AppErrorState.getFriendlyErrorString(e)),
      );
    }
  }

  Future<void> enrollFree(String courseId) async {
    emit(CourseDetailProgress());
    try {
      await repo.enrollFree(courseId: courseId);
      final courseDetail = await repo.getCourseDetail(courseId: courseId);
      emit(CourseDetailSuccess(courseDetail: courseDetail));
    } catch (e) {
      emit(CourseDetailError(message: AppErrorState.getFriendlyErrorString(e)));
    }
  }

  void reset() {
    emit(CourseInitial());
  }

  Future<void> loadCoursesByType(String type, {int limit = 50}) async {
    emit(CourseListProgress());
    try {
      final courses = await repo.getCoursesByType(type: type, limit: limit);
      emit(CourseListSuccess(courses: courses, type: type));
    } catch (e) {
      emit(CourseListError(message: AppErrorState.getFriendlyErrorString(e)));
    }
  }
}
