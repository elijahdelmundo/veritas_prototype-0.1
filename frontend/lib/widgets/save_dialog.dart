import 'package:flutter/material.dart';

/// Keeps forms open on server errors and prevents duplicate submissions.
class SaveDialog extends StatefulWidget {
  const SaveDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onSave,
    required this.saveLabel,
  });
  final Widget title;
  final Widget content;
  final Future<bool> Function() onSave;
  final String saveLabel;

  @override
  State<SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<SaveDialog> {
  bool saving = false;
  String? error;

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final saved = await widget.onSave();
      if (saved && mounted) Navigator.of(context).pop();
    } catch (exception) {
      if (mounted) setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: widget.title,
      content: AbsorbPointer(absorbing: saving, child: widget.content),
      actions: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving...' : widget.saveLabel),
        ),
      ],
    ),
  );
}
