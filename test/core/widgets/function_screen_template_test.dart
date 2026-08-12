import 'package:ed_tech/core/ads/ad_frequency_manager.dart';
import 'package:ed_tech/core/theme/locale_cubit.dart';
import 'package:ed_tech/core/widgets/template/function_screen_template.dart';
import 'package:ed_tech/core/widgets/template/opacity_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final frequencyManager = AdFrequencyManager.instance;

  setUp(frequencyManager.resetForTest);

  tearDown(() {
    frequencyManager.resetForTest();
    TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
  });

  Widget buildSubject() {
    return BlocProvider(
      create: (_) => LocaleCubit(),
      child: MaterialApp(
        home: FunctionScreenTemplate(
          isShowAppBar: false,
          isShowBottomButton: false,
          screen: const Text('Order confirmation'),
        ),
      ),
    );
  }

  testWidgets('keeps payment confirmation visible under the store sheet', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    frequencyManager.isPaymentFlowActive = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byType(OpacityWidget), findsNothing);
    expect(find.text('Order confirmation'), findsOneWidget);
  });

  testWidgets('still obscures private content when the app is backgrounded', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    frequencyManager.isPaymentFlowActive = true;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(find.byType(OpacityWidget), findsOneWidget);
  });
}
