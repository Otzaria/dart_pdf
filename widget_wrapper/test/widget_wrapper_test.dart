import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_widget_wrapper/pdf_widget_wrapper.dart';

void main() {
  testWidgets('fromKey copies the captured pixels before releasing image', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: const SizedBox(width: 20, height: 12, child: ColoredBox(color: Colors.red)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final result = await WidgetWrapper.fromKey(key: key);
    expect(result.width, 20);
    expect(result.height, 12);
    expect(result.bytes.length, 20 * 12 * 4);
    expect(result.bytes.any((byte) => byte != 0), isTrue);
  });

  testWidgets('fromWidget rejects unbounded width or height', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    final context = tester.element(find.byType(SizedBox).first);
    for (final constraints in [
      const BoxConstraints(maxWidth: double.infinity, maxHeight: 100),
      const BoxConstraints(maxWidth: 100, maxHeight: double.infinity),
    ]) {
      await expectLater(
        WidgetWrapper.fromWidget(
          context: context,
          widget: const SizedBox(width: 20, height: 20),
          constraints: constraints,
        ),
        throwsException,
      );
    }
  });
}
