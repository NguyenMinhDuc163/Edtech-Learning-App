import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/core/widgets/template/button_widget.dart';
import 'package:ed_tech/modules/payment/bloc/payment_cubit.dart';
import 'package:ed_tech/modules/payment/bloc/payment_state.dart';
import 'package:ed_tech/modules/payment/model/invoice_detail_model.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class InvoiceDetailScreen extends StatefulWidget {
  static const String routeName = '/invoiceDetailScreen';

  final String paymentId;

  const InvoiceDetailScreen({super.key, required this.paymentId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCubit>().getPaymentDetail(
        paymentId: widget.paymentId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'payment.invoice'.tr(),
          style: AppTextStyles.appbarTitle.copyWith(color: AppColors.text),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state is InvoiceDetailProgress) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'payment.loading'.tr(),
                    style: AppTextStyles.textContent2.copyWith(
                      color: AppColors.coolGray,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is InvoiceDetailSuccess) {
            final invoice = state.data.data?.data?.invoice;
            if (invoice == null) {
              return Center(
                child: Text(
                  'payment.invoice_not_found'.tr(),
                  style: AppTextStyles.textContent1,
                ),
              );
            }

            return SingleChildScrollView(
              child: Container(
                color: AppColors.white,
                padding: AppPad.a24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildInvoiceInfo(invoice),
                    const SizedBox(height: 32),
                    _buildBuyerInfo(invoice.buyer),
                    const SizedBox(height: 32),
                    _buildCourseInfo(invoice.course, invoice),
                    const SizedBox(height: 32),
                    _buildPaymentInfo(invoice),
                    if (invoice.refunds != null &&
                        invoice.refunds!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildRefundsInfo(invoice.refunds!),
                    ],
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            );
          }

          if (state is InvoiceDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error.withAlpha(200),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.textContent1.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ButtonWidget(
                    title: 'common.retry'.tr(),
                    onPressed: () {
                      context.read<PaymentCubit>().getPaymentDetail(
                        paymentId: widget.paymentId,
                      );
                    },
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

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'payment.invoice'.tr().toUpperCase(),
          style: AppTextStyles.textHeader1.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 2, width: 60, color: AppColors.text),
      ],
    );
  }

  Widget _buildInvoiceInfo(InvoiceData invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('payment.invoice_number'.tr(), invoice.paymentId ?? '-'),
        const SizedBox(height: 12),
        _buildInfoRow('payment.transaction_ref'.tr(), invoice.txnRef ?? '-'),
        const SizedBox(height: 12),
        _buildInfoRow(
          'payment.transaction_no'.tr(),
          invoice.transactionNo ?? '-',
        ),
        const SizedBox(height: 12),
        _buildInfoRow('payment.status'.tr(), _getStatusText(invoice.status)),
        const SizedBox(height: 12),
        _buildInfoRow('payment.date'.tr(), _formatDate(invoice.createdAt)),
        const SizedBox(height: 12),
        _buildInfoRow('payment.paid_date'.tr(), _formatDate(invoice.paidAt)),
      ],
    );
  }

  Widget _buildBuyerInfo(BuyerInfo? buyer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment.buyer_information'.tr().toUpperCase(),
          style: AppTextStyles.textHeader3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: AppPad.a16,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.silverGray),
            borderRadius: AppBorderRadius.a8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('payment.full_name'.tr(), buyer?.fullName ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow('payment.email'.tr(), buyer?.email ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow('payment.phone'.tr(), buyer?.phone ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseInfo(CourseInfo? course, InvoiceData invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment.course_information'.tr().toUpperCase(),
          style: AppTextStyles.textHeader3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: AppPad.a16,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.silverGray),
            borderRadius: AppBorderRadius.a8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course?.thumbnailUrl != null &&
                  course!.thumbnailUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppBorderRadius.a8,
                  child: Image.network(
                    course.thumbnailUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.coolGray,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              if (course?.thumbnailUrl != null &&
                  course!.thumbnailUrl!.isNotEmpty)
                const SizedBox(height: 16),
              _buildInfoRow('payment.course_title'.tr(), course?.title ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow('payment.teacher'.tr(), course?.teacher ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'payment.course_price'.tr(),
                invoice.isIap
                    ? _formatAmount(invoice.amount, invoice.currency)
                    : course?.price.formatCurrency() ?? '0 ₫',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(InvoiceData invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment.payment_information'.tr().toUpperCase(),
          style: AppTextStyles.textHeader3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: AppPad.a16,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.silverGray),
            borderRadius: AppBorderRadius.a8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'payment.payment_method'.tr(),
                invoice.paymentMethod ?? '-',
              ),
              const SizedBox(height: 12),
              if (invoice.bankCode != null)
                _buildInfoRow(
                  'payment.bank_code'.tr(),
                  invoice.bankCode ?? '-',
                ),
              if (invoice.bankCode != null) const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'payment.total_amount'.tr(),
                    style: AppTextStyles.textHeader3.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatAmount(invoice.amount, invoice.currency),
                    style: AppTextStyles.textHeader2.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefundsInfo(List<RefundInfo> refunds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment.refund_information'.tr().toUpperCase(),
          style: AppTextStyles.textHeader3.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...refunds.map(
          (refund) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: AppPad.a16,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.silverGray),
              borderRadius: AppBorderRadius.a8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('payment.refund_id'.tr(), refund.refundId ?? '-'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'payment.refund_amount'.tr(),
                  refund.amount.formatCurrency(),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'payment.refund_status'.tr(),
                  _getRefundStatusText(refund.status),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'payment.refund_reason'.tr(),
                  refund.reason ?? '-',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'payment.refund_date'.tr(),
                  _formatDate(refund.createdAt),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: AppColors.silverGray, thickness: 1),
        const SizedBox(height: 16),
        Text(
          'payment.thank_you'.tr(),
          style: AppTextStyles.textContent2.copyWith(color: AppColors.coolGray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.textContent2.copyWith(
              color: AppColors.coolGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.textContent2.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(String? amount, String? currency) {
    if (currency == null || currency.isEmpty || currency == 'VND') {
      return amount.formatCurrency();
    }
    final value = double.tryParse(amount ?? '');
    if (value == null) return amount ?? '-';
    return NumberFormat.simpleCurrency(name: currency).format(value);
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'SUCCESS':
        return 'payment.status_success'.tr();
      case 'PENDING':
        return 'payment.status_pending'.tr();
      case 'FAILED':
        return 'payment.status_failed'.tr();
      default:
        return status ?? '-';
    }
  }

  String _getRefundStatusText(String? status) {
    switch (status) {
      case 'PEND':
        return 'payment.refund_pending'.tr();
      case 'APPROVED':
        return 'payment.refund_approved'.tr();
      case 'REJECTED':
        return 'payment.refund_rejected'.tr();
      default:
        return status ?? '-';
    }
  }
}
