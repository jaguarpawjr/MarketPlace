import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace/Auth/phone_signin.dart';



void main() {
  testWidgets('Phone sign-in screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(313, 691);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: const PhoneSignInPage()));

    expect(find.text('Buy, sell and discover locally'), findsOneWidget);
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
