import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/core/widgets/template/button_widget.dart';
import 'package:ed_tech/modules/payment/bloc/payment_cubit.dart';
import 'package:ed_tech/modules/payment/bloc/payment_state.dart';
import 'package:ed_tech/modules/payment/model/my_payments_model.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class MyPaymentsScreen extends StatefulWidget {
  static const String routeName = '/myPaymentsScreen';

  const MyPaymentsScreen({super.key});

  @override
  State<MyPaymentsScreen> createState() => _MyPaymentsScreenState();
}

class _MyPaymentsScreenState extends State<MyPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentCubit>().getMyPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FunctionScreenTemplate(
      isShowBottomButton: false,
      isShowAppBar: true,
      isShowDrawer: false,
      backgroundColor: AppColors.background,
      title: 'payment.my_payments'.tr(),
      screen: BlocBuilder<PaymentCubit, PaymentState>(
        builder: (context, state) {
          if (state is MyPaymentsProgress) {
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

          if (state is MyPaymentsSuccess) {
            final payments = state.data.data?.data?.payments ?? [];

            if (payments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 80,
                      color: AppColors.coolGray.withAlpha(128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'payment.no_payments'.tr(),
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
                await context.read<PaymentCubit>().getMyPayments();
              },
              child: ListView.separated(
                padding: AppPad.h16v12,
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _PaymentCard(
                    payment: payments[index],
                    onTap: () {
                      if (payments[index].paymentId != null) {
                        Navigator.pushNamed(
                          context,
                          '/invoiceDetailScreen',
                          arguments: payments[index].paymentId,
                        );
                      }
                    },
                  );
                },
              ),
            );
          }

          if (state is MyPaymentsError) {
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
                      context.read<PaymentCubit>().getMyPayments();
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
}

class _PaymentCard extends StatelessWidget {
  final PaymentRecord payment;
  final VoidCallback? onTap;

  const _PaymentCard({required this.payment, this.onTap});

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
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
        return status ?? '';
    }
  }

  Color _getRefundStatusColor(String? status) {
    switch (status) {
      case 'PEND':
        return AppColors.orange;
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.coolGray;
    }
  }

  String _formatAmount() {
    if (payment.sourceType != 'IAP') return payment.amount.formatCurrency();
    final value = double.tryParse(payment.amount ?? '');
    final currency = payment.currency;
    if (value == null || currency == null || currency.isEmpty) {
      return payment.amount ?? '-';
    }
    return NumberFormat.simpleCurrency(name: currency).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.a12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppBorderRadius.a12,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlack15,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (payment.thumbnailUrl != null &&
                payment.thumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  payment.thumbnailUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
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
            Padding(
              padding: AppPad.a16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.courseTitle ?? 'payment.unknown_course'.tr(),
                    style: AppTextStyles.textHeader3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'payment.amount'.tr(),
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.coolGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAmount(),
                            style: AppTextStyles.textContent1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: AppPad.h12v8,
                        decoration: BoxDecoration(
                          color: _getRefundStatusColor(
                            payment.refundStatus,
                          ).withAlpha(30),
                          borderRadius: AppBorderRadius.a8,
                          border: Border.all(
                            color: _getRefundStatusColor(
                              payment.refundStatus,
                            ).withAlpha(100),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getRefundStatusText(payment.refundStatus),
                          style: AppTextStyles.textContent3.copyWith(
                            color: _getRefundStatusColor(payment.refundStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppColors.silverGray),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.coolGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'payment.paid_at'.tr(),
                        style: AppTextStyles.textContent3.copyWith(
                          color: AppColors.coolGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDate(payment.paidAt),
                          style: AppTextStyles.textContent3.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (payment.vnpRequestId != null &&
                      payment.vnpRequestId!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 16,
                          color: AppColors.coolGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${'payment.transaction_id'.tr()}: ${payment.vnpRequestId}',
                            style: AppTextStyles.textContent3.copyWith(
                              color: AppColors.coolGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
}
