class InvoiceDetailResponse {
  final int? status;
  final String? message;
  final InvoiceDetailData? data;

  InvoiceDetailResponse({this.status, this.message, this.data});

  factory InvoiceDetailResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailResponse(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data:
          json['data'] != null
              ? InvoiceDetailData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class InvoiceDetailData {
  final bool? success;
  final InvoiceInnerData? data;

  InvoiceDetailData({this.success, this.data});

  factory InvoiceDetailData.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailData(
      success: json['success'] as bool?,
      data:
          json['data'] != null
              ? InvoiceInnerData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
}

class InvoiceInnerData {
  final InvoiceData? invoice;

  InvoiceInnerData({this.invoice});

  factory InvoiceInnerData.fromJson(Map<String, dynamic> json) {
    return InvoiceInnerData(
      invoice:
          json['invoice'] != null
              ? InvoiceData.fromJson(json['invoice'] as Map<String, dynamic>)
              : null,
    );
  }
}

class InvoiceData {
  final String? paymentId;
  final String? txnRef;
  final String? transactionNo;
  final String? amount;
  final String? paymentMethod;
  final String? status;
  final String? bankCode;
  final String? paidAt;
  final String? createdAt;
  final BuyerInfo? buyer;
  final CourseInfo? course;
  final List<RefundInfo>? refunds;
  final String? currency;
  final bool isIap;

  InvoiceData({
    this.paymentId,
    this.txnRef,
    this.transactionNo,
    this.amount,
    this.paymentMethod,
    this.status,
    this.bankCode,
    this.paidAt,
    this.createdAt,
    this.buyer,
    this.course,
    this.refunds,
    this.currency,
    this.isIap = false,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json) {
    return InvoiceData(
      paymentId: json['payment_id'] as String?,
      txnRef: json['txn_ref'] as String?,
      transactionNo: json['transaction_no'] as String?,
      amount: json['amount'] as String?,
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String?,
      bankCode: json['bank_code'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      buyer:
          json['buyer'] != null
              ? BuyerInfo.fromJson(json['buyer'] as Map<String, dynamic>)
              : null,
      course:
          json['course'] != null
              ? CourseInfo.fromJson(json['course'] as Map<String, dynamic>)
              : null,
      refunds:
          json['refunds'] != null
              ? (json['refunds'] as List)
                  .map((x) => RefundInfo.fromJson(x as Map<String, dynamic>))
                  .toList()
              : null,
      currency: json['currency'] as String?,
      isIap: json['is_iap'] == true,
    );
  }
}

class BuyerInfo {
  final String? fullName;
  final String? email;
  final String? phone;

  BuyerInfo({this.fullName, this.email, this.phone});

  factory BuyerInfo.fromJson(Map<String, dynamic> json) {
    return BuyerInfo(
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class CourseInfo {
  final String? courseId;
  final String? title;
  final String? price;
  final String? thumbnailUrl;
  final String? teacher;

  CourseInfo({
    this.courseId,
    this.title,
    this.price,
    this.thumbnailUrl,
    this.teacher,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      courseId: json['course_id'] as String?,
      title: json['title'] as String?,
      price: json['price'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      teacher: json['teacher'] as String?,
    );
  }
}

class RefundInfo {
  final String? refundId;
  final String? amount;
  final String? status;
  final String? reason;
  final String? createdAt;

  RefundInfo({
    this.refundId,
    this.amount,
    this.status,
    this.reason,
    this.createdAt,
  });

  factory RefundInfo.fromJson(Map<String, dynamic> json) {
    return RefundInfo(
      refundId: json['refund_id'] as String?,
      amount: json['amount'] as String?,
      status: json['status'] as String?,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
