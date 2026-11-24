import 'package:flutter_test/flutter_test.dart';
import 'package:dynamics/ui/widgets/pill_button.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Dynamics basic widget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PillButton(
            label: 'Dynamics',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('DYNAMICS'), findsOneWidget);
  });
}
