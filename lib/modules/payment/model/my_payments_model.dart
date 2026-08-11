class MyPaymentsResponse {
  final int? status;
  final String? message;
  final MyPaymentsData? data;

  MyPaymentsResponse({this.status, this.message, this.data});

  factory MyPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return MyPaymentsResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data:
          json['data'] != null
              ? MyPaymentsData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class MyPaymentsData {
  final bool? success;
  final MyPaymentsInnerData? data;

  MyPaymentsData({this.success, this.data});

  factory MyPaymentsData.fromJson(Map<String, dynamic> json) {
    return MyPaymentsData(
      success: json['success'] as bool?,
      data:
          json['data'] != null
              ? MyPaymentsInnerData.fromJson(
                json['data'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class MyPaymentsInnerData {
  final List<PaymentRecord>? payments;

  MyPaymentsInnerData({this.payments});

  factory MyPaymentsInnerData.fromJson(Map<String, dynamic> json) {
    return MyPaymentsInnerData(
      payments:
          json['payments'] != null
              ? (json['payments'] as List)
                  .map((x) => PaymentRecord.fromJson(x as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }
}

class PaymentRecord {
  final String? paymentId;
  final String? courseTitle;
  final String? coursePrice;
  final String? thumbnailUrl;
  final String? amount;
  final String? paidAt;
  final String? refundStatus;
  final String? vnpRequestId;
  final String? currency;
  final String? paymentMethod;
  final String? sourceType;

  PaymentRecord({
    this.paymentId,
    this.courseTitle,
    this.coursePrice,
    this.thumbnailUrl,
    this.amount,
    this.paidAt,
    this.refundStatus,
    this.vnpRequestId,
    this.currency,
    this.paymentMethod,
    this.sourceType,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      paymentId: json['payment_id'] as String?,
      courseTitle: json['course_title'] as String?,
      coursePrice: json['course_price'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      amount: json['amount'] as String?,
      paidAt: json['paid_at'] as String?,
      refundStatus: json['refund_status'] as String?,
      vnpRequestId: json['vnp_request_id'] as String?,
      currency: json['currency'] as String?,
      paymentMethod: json['payment_method'] as String?,
      sourceType: json['source_type'] as String?,
    );
  }
}
