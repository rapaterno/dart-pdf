import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dart_pdf_editor/dart_pdf_editor.dart';

import 'custom_editor_controls.dart';

/// Builds a replaceable region of [CustomPdfEditor].
typedef CustomPdfEditorBuilder = Widget Function(
  BuildContext context,
  PdfEditingController editing,
  PdfViewerController viewer,
);

/// A small, app-owned alternative to [PdfEditorView].
///
/// The caller owns [editing]. This widget owns a [PdfViewerController] only
/// when one is not supplied. Replace the default page navigator, inspector,
/// and tools through the builders as the product UI takes shape.
class CustomPdfEditor extends StatefulWidget {
  const CustomPdfEditor({
    super.key,
    required this.editing,
    this.viewerController,
    this.pageNavigatorBuilder,
    this.inspectorBuilder,
    this.toolbarBuilder,
    this.onSave,
    this.onDocumentChanged,
    this.onAction,
    this.singlePage = true,
  });

  final PdfEditingController editing;
  final PdfViewerController? viewerController;
  final CustomPdfEditorBuilder? pageNavigatorBuilder;
  final CustomPdfEditorBuilder? inspectorBuilder;
  final CustomPdfEditorBuilder? toolbarBuilder;
  final ValueChanged<Uint8List>? onSave;
  final ValueChanged<Uint8List>? onDocumentChanged;
  final PdfActionHandler? onAction;
  final bool singlePage;

  @override
  State<CustomPdfEditor> createState() => _CustomPdfEditorState();
}

class _CustomPdfEditorState extends State<CustomPdfEditor> {
  late PdfViewerController _viewer;
  var _ownsViewer = false;
  late PdfDocument _lastDocument;
  var _showPages = true;
  var _showInspector = false;

  @override
  void initState() {
    super.initState();
    _replaceViewer();
    _lastDocument = widget.editing.document;
    widget.editing.addListener(_onEditingChanged);
  }

  @override
  void didUpdateWidget(CustomPdfEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.editing, widget.editing)) {
      oldWidget.editing.removeListener(_onEditingChanged);
      _lastDocument = widget.editing.document;
      widget.editing.addListener(_onEditingChanged);
    }
    if (!identical(oldWidget.viewerController, widget.viewerController)) {
      _replaceViewer();
    }
  }

  void _replaceViewer() {
    if (_ownsViewer) _viewer.dispose();
    _viewer = widget.viewerController ?? PdfViewerController();
    _ownsViewer = widget.viewerController == null;
  }

  void _onEditingChanged() {
    final document = widget.editing.document;
    if (identical(document, _lastDocument)) return;
    _lastDocument = document;
    widget.onDocumentChanged?.call(widget.editing.bytes);
  }

  @override
  void dispose() {
    widget.editing.removeListener(_onEditingChanged);
    if (_ownsViewer) _viewer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing;
    final pages =
        widget.pageNavigatorBuilder?.call(context, editing, _viewer) ??
            CustomEditorPageNavigator(editing: editing, viewer: _viewer);
    final inspector =
        widget.inspectorBuilder?.call(context, editing, _viewer) ??
            CustomEditorInspector(editing: editing);
    final toolbar = widget.toolbarBuilder?.call(context, editing, _viewer) ??
        CustomEditorToolPlaceholder(editing: editing);

    return Column(children: [
      CustomEditorHeader(
        editing: editing,
        viewer: _viewer,
        onSave: widget.onSave,
        showPages: _showPages,
        showInspector: _showInspector,
        onPagesPressed: () => setState(() => _showPages = !_showPages),
        onInspectorPressed: () =>
            setState(() => _showInspector = !_showInspector),
      ),
      Expanded(
        child: Row(children: [
          if (_showPages) SizedBox(width: 160, child: pages),
          Expanded(
            child: ListenableBuilder(
              listenable: editing,
              builder: (context, _) => PdfViewer(
                document: editing.document,
                controller: _viewer,
                editing: editing,
                onAction: widget.onAction,
                singlePage: widget.singlePage,
              ),
            ),
          ),
          if (_showInspector) SizedBox(width: 240, child: inspector),
        ]),
      ),
      toolbar,
    ]);
  }
}
