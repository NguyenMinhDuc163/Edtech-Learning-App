import 'dart:async';

import 'package:ed_tech/modules/iap/repository/iap_repository.dart';
import 'package:ed_tech/modules/iap/service/iap_platform.dart';
import 'package:ed_tech/modules/iap/service/revenuecat_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

part 'iap_state.dart';

class IapCubit extends Cubit<IapState> {
  IapCubit({required this.repository, RevenueCatService? revenueCatService})
    : revenueCatService = revenueCatService ?? RevenueCatService.instance,
      super(const IapInitial());

  final IapRepository repository;
  final RevenueCatService revenueCatService;

  Future<void> loadProduct(String productId) async {
    final platform = IapPlatform.apiValue;
    if (platform == null) {
      emit(const IapFailure('unsupported_platform'));
      return;
    }
    emit(const IapLoading());
    try {
      final config = await repository.getConfig(platform);
      if (!config.enabled) {
        throw const IapException(
          'iap_disabled',
          'In-app purchases are currently unavailable.',
        );
      }
      await revenueCatService.configure(config);
      final product = await revenueCatService.getProduct(productId);
      emit(IapReady(product));
    } catch (error) {
      emit(IapFailure(error.toString()));
    }
  }

  Future<void> purchase({
    required String courseId,
    required String productId,
    required StoreProduct product,
  }) async {
    emit(IapPurchasing(product));
    try {
      await revenueCatService.purchase(product);
      final sync = await repository.syncPurchase(
        reason: 'PURCHASE',
        courseId: courseId,
        productId: productId,
      );
      if (sync.isActive) {
        emit(IapSuccess(sync.activatedCourseIds));
        return;
      }

      for (final delay in const [1, 2, 4]) {
        await Future<void>.delayed(Duration(seconds: delay));
        final status = await repository.getStatus(courseId);
        if (status.accessLevel == 'FULL') {
          emit(const IapSuccess([]));
          return;
        }
      }
      emit(const IapPending());
    } on IapException catch (error) {
      if (error.cancelled) {
        emit(IapReady(product));
      } else if (error.code == 'already_purchased') {
        await _restoreKnownPurchase(courseId, productId, product);
      } else if (error.code == 'payment_pending') {
        emit(const IapPending());
      } else {
        emit(IapFailure(error.message, product: product));
      }
    } catch (error) {
      emit(IapFailure(error.toString(), product: product));
    }
  }

  Future<void> restore() async {
    final platform = IapPlatform.apiValue;
    if (platform == null) {
      emit(const IapFailure('unsupported_platform'));
      return;
    }
    emit(const IapRestoring());
    try {
      final config = await repository.getConfig(platform);
      await revenueCatService.configure(config);
      await revenueCatService.restorePurchases();
      final sync = await repository.syncPurchase(reason: 'RESTORE');
      emit(
        IapRestoreSuccess([
          ...sync.activatedCourseIds,
          ...sync.unchangedCourseIds,
        ]),
      );
    } catch (error) {
      emit(IapFailure(error.toString()));
    }
  }

  Future<void> _restoreKnownPurchase(
    String courseId,
    String productId,
    StoreProduct product,
  ) async {
    try {
      await revenueCatService.restorePurchases();
      final sync = await repository.syncPurchase(
        reason: 'RESTORE',
        courseId: courseId,
        productId: productId,
      );
      if (sync.isActive) {
        emit(const IapSuccess([]));
      } else {
        emit(const IapPending());
      }
    } catch (error) {
      emit(IapFailure(error.toString(), product: product));
    }
  }
}
