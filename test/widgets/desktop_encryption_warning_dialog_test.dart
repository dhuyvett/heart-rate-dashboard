// ignore_for_file: library_annotations
@Timeout(Duration(seconds: 10))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_rate_dashboard/widgets/desktop_encryption_warning_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DesktopEncryptionWarningDialog toggles dont show again', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const DesktopEncryptionWarningDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('database is stored unencrypted'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(find.text('I Understand'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
