import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Linux raster keeps the Dart event loop responsive', (tester) async {
    final document = pw.Document();
    for (var page = 0; page < 60; page++) {
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Text('Raster worker page $page'),
          ),
        ),
      );
    }
    final bytes = await document.save();

    var timerTicks = 0;
    final timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => timerTicks++,
    );

    var rasterized = 0;
    final stopwatch = Stopwatch()..start();
    await for (final _ in Printing.raster(bytes, dpi: 144)) {
      rasterized++;
    }
    stopwatch.stop();
    timer.cancel();

    expect(rasterized, 60);
    // Rastering dozens of A4 pages is deliberately long enough that a
    // synchronous native method handler starves this timer completely.
    expect(
      timerTicks,
      greaterThan(2),
      reason:
          'Dart timer did not run while native rastering took '
          '${stopwatch.elapsedMilliseconds} ms',
    );
  });
}
