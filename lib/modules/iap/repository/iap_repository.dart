import 'package:ed_tech/core/constants/api_path.dart';
import 'package:ed_tech/data/api_client.dart';
import 'package:ed_tech/data/models/request_method.dart';
import 'package:ed_tech/modules/iap/model/iap_models.dart';

class IapRepository {
  IapRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<IapConfig> getConfig(String platform) async {
    final response = await apiClient.fetch(
      ApiPath.mobileIapConfig,
      RequestMethod.get,
      searchParams: {'platform': platform},
    );
    if (response.code != 200) throw Exception(response.message);
    return IapConfig.fromJson(response.data);
  }

  Future<IapSyncResponse> syncPurchase({
    required String reason,
    String? courseId,
    String? productId,
  }) async {
    final body = <String, dynamic>{'reason': reason};
    if (courseId != null) body['courseId'] = courseId;
    if (productId != null) body['productId'] = productId;
    final response = await apiClient.fetch(
      ApiPath.mobileIapSync,
      RequestMethod.post,
      rawData: body,
    );
    if (response.code != 200) throw Exception(response.message);
    return IapSyncResponse.fromJson(response.data);
  }

  Future<IapStatusResponse> getStatus(String courseId) async {
    final response = await apiClient.fetch(
      '${ApiPath.mobileIapStatus}/$courseId',
      RequestMethod.get,
    );
    if (response.code != 200) throw Exception(response.message);
    return IapStatusResponse.fromJson(response.data);
  }
}
