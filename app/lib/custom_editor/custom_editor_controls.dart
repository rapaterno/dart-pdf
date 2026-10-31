import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dart_pdf_editor/dart_pdf_editor.dart';

class CustomEditorHeader extends StatefulWidget {
  const CustomEditorHeader({
    super.key,
    required this.editing,
    required this.viewer,
    this.onSave,
    required this.showPages,
    required this.showInspector,
    required this.onPagesPressed,
    required this.onInspectorPressed,
  });

  final PdfEditingController editing;
  final PdfViewerController viewer;
  final ValueChanged<Uint8List>? onSave;
  final bool showPages;
  final bool showInspector;
  final VoidCallback onPagesPressed;
  final VoidCallback onInspectorPressed;

  @override
  State<CustomEditorHeader> createState() => _CustomEditorHeaderState();
}

class _CustomEditorHeaderState extends State<CustomEditorHeader> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = widget.viewer;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.editing, viewer]),
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(
              tooltip: 'Pages',
              icon: const Icon(Icons.pages_outlined),
              isSelected: widget.showPages,
              onPressed: widget.onPagesPressed,
            ),
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.chevron_left),
              onPressed: viewer.currentPage == 0
                  ? null
                  : () =>
                      unawaited(viewer.animateToPage(viewer.currentPage - 1)),
            ),
            Text('${viewer.currentPage + 1} / ${viewer.pageCount}'),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.chevron_right),
              onPressed: viewer.currentPage >= viewer.pageCount - 1
                  ? null
                  : () =>
                      unawaited(viewer.animateToPage(viewer.currentPage + 1)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (query) => unawaited(viewer.search(query)),
              ),
            ),
            IconButton(
              tooltip: 'Previous match',
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: viewer.matchCount == 0 ? null : viewer.previousMatch,
            ),
            IconButton(
              tooltip: 'Next match',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: viewer.matchCount == 0 ? null : viewer.nextMatch,
            ),
            IconButton(
              tooltip: 'Inspector',
              icon: const Icon(Icons.tune),
              isSelected: widget.showInspector,
              onPressed: widget.onInspectorPressed,
            ),
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save_outlined),
              onPressed: widget.onSave == null
                  ? null
                  : () => widget.onSave!(widget.editing.bytes),
            ),
          ]),
        ),
      ),
    );
  }
}

class CustomEditorPageNavigator extends StatelessWidget {
  const CustomEditorPageNavigator({
    super.key,
    required this.editing,
    required this.viewer,
  });

  final PdfEditingController editing;
  final PdfViewerController viewer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListenableBuilder(
        listenable: viewer,
        builder: (context, _) => ListView.builder(
          itemCount: editing.document.pageCount,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('Page ${index + 1}'),
            selected: index == viewer.currentPage,
            onTap: () => unawaited(viewer.animateToPage(index)),
          ),
        ),
      ),
    );
  }
}

class CustomEditorInspector extends StatelessWidget {
  const CustomEditorInspector({super.key, required this.editing});

  final PdfEditingController editing;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListenableBuilder(
          listenable: editing,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(editing.tool == null
                ? 'Select an annotation to inspect it.'
                : 'Active tool: ${editing.tool!.name}'),
          ),
        ),
      );
}

/// Intentionally small tool UI. Replace it with [CustomPdfEditor.toolbarBuilder]
/// once the product toolbar is ready.
class CustomEditorToolPlaceholder extends StatelessWidget {
  const CustomEditorToolPlaceholder({super.key, required this.editing});

  final PdfEditingController editing;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: ListenableBuilder(
          listenable: editing,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              _tool(Icons.near_me_outlined, PdfEditTool.select, 'Select'),
              _tool(Icons.gesture, PdfEditTool.ink, 'Ink'),
              _tool(
                  Icons.rectangle_outlined, PdfEditTool.rectangle, 'Rectangle'),
              _tool(Icons.text_fields, PdfEditTool.freeText, 'Text'),
              _tool(Icons.sticky_note_2_outlined, PdfEditTool.note, 'Note'),
              const Spacer(),
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: editing.canUndo ? editing.undo : null,
              ),
              IconButton(
                tooltip: 'Redo',
                icon: const Icon(Icons.redo),
                onPressed: editing.canRedo ? editing.redo : null,
              ),
            ]),
          ),
        ),
      );

  Widget _tool(IconData icon, PdfEditTool tool, String label) => IconButton(
        tooltip: label,
        icon: Icon(icon),
        isSelected: editing.tool == tool,
        onPressed: () => editing.tool = editing.tool == tool ? null : tool,
      );
}
