import 'package:easy_localization/easy_localization.dart';
import 'package:ed_tech/data/services/user_service.dart';
import 'package:ed_tech/init.dart';
import 'package:ed_tech/modules/iap/bloc/iap_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:ed_tech/modules/payment/bloc/payment_cubit.dart';
import 'package:ed_tech/modules/payment/bloc/payment_state.dart';
import 'package:ed_tech/modules/payment/screen/payment_webview_screen.dart';
import 'package:ed_tech/utils/helpers/currency_extension.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  static const String routeName = '/orderConfirmationScreen';

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _requestedProduct = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedProduct) return;
    _requestedProduct = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final productId = args?['productId'] as String?;
    if (productId != null && productId.isNotEmpty) {
      context.read<IapCubit>().loadProduct(productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return Scaffold(body: Center(child: Text('payment.invalid_order'.tr())));
    }

    if (kIsWeb) return _WebCheckout(args: args);

    final courseId = args['courseId'] as String? ?? '';
    final productId = args['productId'] as String? ?? '';
    final courseTitle = args['title'] as String? ?? 'course.untitled'.tr();
    final instructor =
        args['instructor'] as String? ?? 'course.unknown_teacher'.tr();
    final duration = args['duration'] as String? ?? '';
    final thumbnailUrl = args['thumbnailUrl'] as String?;
    final user = UserService.instance.userData;

    return BlocConsumer<IapCubit, IapState>(
      listener: (context, state) {
        if (state is IapSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('payment.payment_success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state is IapPending) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('payment.iap_pending'.tr())));
        } else if (state is IapFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final product = _productFromState(state);
        final isBusy = state is IapLoading || state is IapPurchasing;
        return FunctionScreenTemplate(
          title: 'payment.order_confirmation'.tr(),
          isShowBottomButton: false,
          backgroundColor: AppColors.background,
          screen: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CourseSummary(
                  title: courseTitle,
                  instructor: instructor,
                  duration: duration,
                  thumbnailUrl: thumbnailUrl,
                ),
                const SizedBox(height: 28),
                Text(
                  'payment.buyer_information'.tr(),
                  style: AppTextStyles.textHeader3,
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user?.fullName ?? user?.username ?? ''),
                  subtitle: Text(user?.email ?? ''),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'payment.total_amount'.tr(),
                      style: AppTextStyles.textContent1,
                    ),
                    if (state is IapLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        product?.priceString ??
                            args['storePrice'] as String? ??
                            'payment.store_price'.tr(),
                        style: AppTextStyles.textHeader2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'payment.store_managed_notice'.tr(),
                  style: AppTextStyles.textContent3.copyWith(
                    color: AppColors.color8F959E,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        isBusy || product == null
                            ? null
                            : () => context.read<IapCubit>().purchase(
                              courseId: courseId,
                              productId: productId,
                              product: product,
                            ),
                    icon:
                        isBusy
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.lock_outline),
                    label: Text(
                      state is IapPurchasing
                          ? 'payment.processing_order'.tr()
                          : 'payment.pay_with_store'.tr(),
                    ),
                  ),
                ),
                if (state is IapFailure) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed:
                          () => context.read<IapCubit>().loadProduct(productId),
                      icon: const Icon(Icons.refresh),
                      label: Text('payment.retry'.tr()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  StoreProduct? _productFromState(IapState state) {
    if (state is IapReady) return state.product;
    if (state is IapPurchasing) return state.product;
    if (state is IapFailure) return state.product;
    return null;
  }
}

class _WebCheckout extends StatelessWidget {
  const _WebCheckout({required this.args});

  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    final courseId = args['courseId'] as String? ?? '';
    final title = args['title'] as String? ?? 'course.untitled'.tr();
    final price = args['price'] as String? ?? '0';
    final amount = double.tryParse(price)?.round() ?? 0;

    return BlocConsumer<PaymentCubit, PaymentState>(
      listener: (context, state) async {
        if (state is PaymentSuccess) {
          final result = await Navigator.of(context).pushNamed(
            PaymentWebViewScreen.routeName,
            arguments: state.paymentUrl,
          );
          if (!context.mounted) return;
          if (result is Map<String, dynamic> && result['success'] == true) {
            Navigator.of(context).pop(true);
          } else {
            context.read<PaymentCubit>().reset();
          }
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder:
          (context, state) => FunctionScreenTemplate(
            title: 'payment.order_confirmation'.tr(),
            isShowBottomButton: false,
            screen: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.textHeader2),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('payment.total_amount'.tr()),
                      Text(
                        price.formatCurrency(),
                        style: AppTextStyles.textHeader3,
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed:
                          state is PaymentProgress || amount <= 0
                              ? null
                              : () =>
                                  context.read<PaymentCubit>().createPayment(
                                    courseId: courseId,
                                    amount: amount,
                                  ),
                      icon:
                          state is PaymentProgress
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.open_in_new),
                      label: Text('payment.proceed_to_payment'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({
    required this.title,
    required this.instructor,
    required this.duration,
    required this.thumbnailUrl,
  });

  final String title;
  final String instructor;
  final String duration;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                  ? Image.network(
                    thumbnailUrl!,
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                  : _placeholder(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.textHeader3,
              ),
              const SizedBox(height: 8),
              Text(instructor, style: AppTextStyles.textContent3),
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(duration, style: AppTextStyles.textContent3),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    width: 104,
    height: 104,
    color: AppColors.colorF4F3FD,
    child: const Icon(Icons.school_outlined, color: AppColors.primary),
  );
}
