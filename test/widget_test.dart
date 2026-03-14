import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_seefood/main.dart';

void main() {
  testWidgets('SeeFood app renders without cameras', (WidgetTester tester) async {
    await tester.pumpWidget(const SeeFood(cameras: []));

    // App should render and show loading/error state with no cameras
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
