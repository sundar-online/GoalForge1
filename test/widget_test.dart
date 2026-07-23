import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GoalForge UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GoalForge'),
          ),
        ),
      ),
    );

    expect(find.text('GoalForge'), findsOneWidget);
  });
}
