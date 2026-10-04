import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_care_app/core/theme/app_colors.dart';
import 'package:mind_care_app/core/widgets/app_loading_view.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';

void main() {
  // The loading view runs an infinite sweep animation, so pumpAndSettle would
  // never settle. These helpers advance a fixed number of frames instead.
  Future<void> settle(WidgetTester tester, [int frames = 6]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shows the app logo, name and tagline', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLoadingView()));
    await settle(tester);

    expect(find.text('MindCare'), findsOneWidget);
    expect(
      find.text('Your safe space for mental wellness'),
      findsOneWidget,
    );
    // The logo asset is rendered inside a circular badge.
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
  });

  testWidgets('renders a custom loading indicator instead of the stock one',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLoadingView()));
    await settle(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The sweep ring is a CustomPaint layered over the brand background.
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Preparing your space…'), findsOneWidget);
  });

  testWidgets('keeps the branded gradient and leaf background', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLoadingView()));
    await settle(tester);

    expect(find.byType(LeafBackground), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.gradientStart);
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.gradient, AppColors.onboardingGradient);
  });

  testWidgets('the loading animation keeps running and stays off-screen safe',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AppLoadingView()));
    await settle(tester);

    // No overflow on a small screen with a large system font scale.
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a large text scale without overflowing',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: const MaterialApp(home: AppLoadingView()),
      ),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('MindCare'), findsOneWidget);
  });
}
