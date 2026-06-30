import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jowar_disease_detection/core/widgets/error_retry_view.dart';

void main() {
  group('ErrorRetryView Widget Tests', () {
    testWidgets('Renders error message and retry button', (WidgetTester tester) async {
      bool isClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryView(
              errorMessage: "Failed to upload image due to connection loss.",
              onRetry: () {
                isClicked = true;
              },
            ),
          ),
        ),
      );

      // Verify header text
      expect(find.text("An Error Occurred"), findsOneWidget);
      // Verify detailed error message
      expect(find.text("Failed to upload image due to connection loss."), findsOneWidget);
      // Verify retry button exists by text
      expect(find.text("Retry Action"), findsOneWidget);

      // Tap retry and check action trigger
      await tester.tap(find.text("Retry Action"));
      await tester.pump();
      expect(isClicked, isTrue);
    });
  });
}
