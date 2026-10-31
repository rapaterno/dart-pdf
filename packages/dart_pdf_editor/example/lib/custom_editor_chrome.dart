import 'dart:typed_data';

import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';

/// A compact, mobile-oriented editor shell built entirely from the package's
/// public controller and viewer APIs.
///
/// Use this as a starting point when an app needs its own toolbars and a
/// Bluebeam-style tool chest rather than [PdfEditorView]'s stock chrome.
class CustomEditorChromeScreen extends StatefulWidget {
  const CustomEditorChromeScreen({
    super.key,
    required this.bytes,
    required this.onSave,
  });

  final Uint8List bytes;
  final ValueChanged<Uint8List> onSave;

  @override
  State<CustomEditorChromeScreen> createState() =>
      _CustomEditorChromeScreenState();
}

class _CustomEditorChromeScreenState extends State<CustomEditorChromeScreen> {
  late final PdfEditingController _editing = PdfEditingController(widget.bytes);
  final PdfViewerController _viewer = PdfViewerController();

  @override
  void dispose() {
    _editing.dispose();
    _viewer.dispose();
    super.dispose();
  }

  void _selectTool(PdfEditTool? tool) {
    _editing.tool = tool;
    Navigator.maybePop(context);
  }

  Future<void> _configureScale() async {
    final scale = await showPdfScaleDialog(
      context,
      initial: _editing.measurementScale,
      onCalibrate: () => _selectTool(PdfEditTool.calibrate),
    );
    if (scale != null) _editing.measurementScale = scale;
  }

  Future<void> _saveSelectedMarkup() async {
    final name = await showPdfTextPrompt(
      context,
      title: 'Save to tool chest',
      multiline: false,
    );
    if (name != null) _editing.saveSelectedAnnotation(name);
  }

  void _showToolChest() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ToolChest(
        editing: _editing,
        onSelectTool: _selectTool,
        onConfigureScale: _configureScale,
        onSaveSelectedMarkup: _saveSelectedMarkup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan review'),
        actions: [
          ListenableBuilder(
            listenable: _editing,
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: _editing.canUndo ? _editing.undo : null,
            ),
          ),
          ListenableBuilder(
            listenable: _editing,
            builder: (context, _) => IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: _editing.canRedo ? _editing.redo : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: () => widget.onSave(_editing.bytes),
          ),
        ],
      ),
      body: PdfViewer(
        controller: _viewer,
        editing: _editing,
        initialFit: PdfViewerFit.width,
        singlePagePaging: true,
        pageSpacing: 8,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          elevation: 8,
          child: ListenableBuilder(
            listenable: _editing,
            builder: (context, _) => SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ToolbarTool(
                    icon: Icons.near_me_outlined,
                    label: 'Select',
                    selected: _editing.tool == PdfEditTool.select,
                    onPressed: () => _selectTool(PdfEditTool.select),
                  ),
                  _ToolbarTool(
                    icon: Icons.draw_outlined,
                    label: 'Pen',
                    selected: _editing.tool == PdfEditTool.ink,
                    onPressed: () => _selectTool(PdfEditTool.ink),
                  ),
                  _ToolbarTool(
                    icon: Icons.highlight_outlined,
                    label: 'Markup',
                    selected: _editing.tool == PdfEditTool.highlight,
                    onPressed: () => _selectTool(PdfEditTool.highlight),
                  ),
                  _ToolbarTool(
                    icon: Icons.architecture_outlined,
                    label: 'Measure',
                    selected: _editing.tool == PdfEditTool.measureDistance ||
                        _editing.tool == PdfEditTool.measureArea,
                    onPressed: _showToolChest,
                  ),
                  _ToolbarTool(
                    icon: Icons.dashboard_customize_outlined,
                    label: 'Tools',
                    selected: false,
                    onPressed: _showToolChest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarTool extends StatelessWidget {
  const _ToolbarTool({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return IconButton(
      tooltip: label,
      color: color,
      onPressed: onPressed,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ToolChest extends StatelessWidget {
  const _ToolChest({
    required this.editing,
    required this.onSelectTool,
    required this.onConfigureScale,
    required this.onSaveSelectedMarkup,
  });

  final PdfEditingController editing;
  final ValueChanged<PdfEditTool?> onSelectTool;
  final VoidCallback onConfigureScale;
  final VoidCallback onSaveSelectedMarkup;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editing,
      builder: (context, _) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('Tool chest', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ToolSection(
                title: 'Draw',
                tools: const [
                  (PdfEditTool.rectangle, Icons.crop_square, 'Rectangle'),
                  (PdfEditTool.ellipse, Icons.circle_outlined, 'Ellipse'),
                  (PdfEditTool.arrow, Icons.arrow_right_alt, 'Arrow'),
                  (PdfEditTool.callout, Icons.call_made_outlined, 'Callout'),
                  (PdfEditTool.freeText, Icons.text_fields, 'Text box'),
                  (PdfEditTool.note, Icons.sticky_note_2_outlined, 'Note'),
                ],
                onSelect: onSelectTool,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Measurements',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: onConfigureScale,
                    icon: const Icon(Icons.straighten),
                    label: Text(editing.measurementScale == null
                        ? 'Set scale'
                        : editing.measurementScale!.ratioLabel),
                  ),
                ],
              ),
              _ToolSection(
                title: '',
                tools: const [
                  (PdfEditTool.measureDistance, Icons.straighten, 'Length'),
                  (PdfEditTool.measurePerimeter, Icons.polyline, 'Perimeter'),
                  (PdfEditTool.measureArea, Icons.area_chart_outlined, 'Area'),
                  (PdfEditTool.count, Icons.looks_one_outlined, 'Count'),
                ],
                onSelect: onSelectTool,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Saved markups',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: editing.hasAnnotationSelection
                        ? onSaveSelectedMarkup
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Save selected'),
                  ),
                ],
              ),
              if (editing.savedAnnotations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Select a markup, then save it here for reuse.'),
                )
              else
                for (final markup in editing.savedAnnotations)
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(markup.name),
                    subtitle: Text(markup.group ?? 'Ungrouped'),
                    onTap: () {
                      editing.beginSavedAnnotationPlacement(markup);
                      Navigator.pop(context);
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.tools,
    required this.onSelect,
  });

  final String title;
  final List<(PdfEditTool, IconData, String)> tools;
  final ValueChanged<PdfEditTool?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tool in tools)
              ActionChip(
                avatar: Icon(tool.$2, size: 18),
                label: Text(tool.$3),
                onPressed: () => onSelect(tool.$1),
              ),
          ],
        ),
      ],
    );
  }
}
