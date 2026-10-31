# Custom Editor Shell

`CustomPdfEditor` is an app-owned composition of `PdfViewer` and
`PdfEditingController`. The caller creates and disposes the editing session;
the shell owns a viewer controller only when none is supplied.

```dart
final editing = PdfEditingController(pdfBytes);

CustomPdfEditor(
  editing: editing,
  onSave: writePdf,
  onDocumentChanged: saveDraft,
  pageNavigatorBuilder: buildThumbnails,
  inspectorBuilder: buildInspector,
  toolbarBuilder: buildToolbar,
)
```

The defaults are deliberately small working placeholders. Replace the three
builders with product UI without copying `PdfEditorView` or its shell chrome.