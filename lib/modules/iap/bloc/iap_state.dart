part of 'iap_cubit.dart';

sealed class IapState {
  const IapState();
}

class IapInitial extends IapState {
  const IapInitial();
}

class IapLoading extends IapState {
  const IapLoading();
}

class IapReady extends IapState {
  const IapReady(this.product);
  final StoreProduct product;
}

class IapPurchasing extends IapState {
  const IapPurchasing(this.product);
  final StoreProduct product;
}

class IapPending extends IapState {
  const IapPending();
}

class IapSuccess extends IapState {
  const IapSuccess(this.activatedCourseIds);
  final List<String> activatedCourseIds;
}

class IapRestoring extends IapState {
  const IapRestoring();
}

class IapRestoreSuccess extends IapState {
  const IapRestoreSuccess(this.activatedCourseIds);
  final List<String> activatedCourseIds;
}

class IapFailure extends IapState {
  const IapFailure(this.message, {this.product});
  final String message;
  final StoreProduct? product;
}
