import 'package:ed_tech/core/constants/api_path.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/data/models/request_method.dart';
import 'package:ed_tech/modules/home/model/course_response.dart';
import 'package:ed_tech/modules/course/model/detail_course.dart';
import 'package:ed_tech/modules/course/model/refund_response.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/modules/iap/service/iap_platform.dart';

class CourseRepo {
  final ApiClient apiClient;

  CourseRepo({required this.apiClient});

  Future<List<DataCourse>> getCourse({required int id}) async {
    final userId = UserService.instance.userData?.id ?? '1';
    final res = await apiClient.fetch(
      '${ApiPath.hybridRecommendations}/$userId',
      RequestMethod.get,
    );

    if (res.code != 200) {
      throw Exception('Failed to fetch courses: ${res.message}');
    }

    final List<dynamic> dataList = res.dataArray;
    return dataList.map((json) => DataCourse.fromJson(json)).toList();
  }

  Future<DataData> getCourseDetail({required String courseId}) async {
    final platform = IapPlatform.apiValue;
    final res = await apiClient.fetch(
      '${ApiPath.publicCourse}/$courseId',
      RequestMethod.get,
      searchParams: platform == null ? null : {'platform': platform},
    );

    if (res.code != 200) {
      throw Exception('Failed to fetch course detail: ${res.message}');
    }

    return DataData.fromJson(res.data);
  }

  Future<void> enrollFree({required String courseId}) async {
    final res = await apiClient.fetch(
      '${ApiPath.publicCourse}/$courseId/enroll-free',
      RequestMethod.post,
    );
    if (res.code != 200 && res.code != 201) {
      throw Exception(res.message);
    }
  }

  Future<RefundResponse> createRefund({
    required String courseId,
    required String reason,
  }) async {
    final res = await apiClient.fetch(
      ApiPath.createRefund,
      RequestMethod.post,
      rawData: {'courseId': courseId, 'reason': reason},
    );

    if (res.code != 200 && res.code != 201) {
      throw Exception('Failed to create refund: ${res.message}');
    }

    return RefundResponse.fromJson(res.json);
  }

  Future<List<DataCourse>> getCoursesByType({
    required String type,
    int limit = 50,
  }) async {
    final res = await apiClient.fetch(
      ApiPath.coursesList,
      RequestMethod.post,
      rawData: {'type': type, 'limit': limit},
    );

    if (res.code != 200) {
      throw Exception('Failed to fetch courses: ${res.message}');
    }

    final List<dynamic> dataList = res.dataArray;
    return dataList.map((json) => DataCourse.fromJson(json)).toList();
  }
}
