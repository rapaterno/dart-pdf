import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_test_fixtures/pdf_test_fixtures.dart';

import 'package:dart_pdf_editor_app/custom_editor/custom_pdf_editor.dart';

void main() {
  testWidgets('uses single-page navigation from the custom page panel',
      (tester) async {
    final editing = PdfEditingController(buildMultiPagePdf(3));
    final viewer = PdfViewerController();
    addTearDown(editing.dispose);
    addTearDown(viewer.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomPdfEditor(editing: editing, viewerController: viewer),
      ),
    ));
    await tester.pump();

    expect(tester.widget<PdfViewer>(find.byType(PdfViewer)).singlePage, isTrue);
    await tester.tap(find.text('Page 2'));
    await tester.pumpAndSettle();
    expect(viewer.currentPage, 1);
  });
}
