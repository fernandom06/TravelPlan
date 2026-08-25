import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ImportUrlDialog extends StatefulWidget {
  const ImportUrlDialog({super.key, required this.onResolve});

  final Future<LatLng> Function(String url) onResolve;

  @override
  State<ImportUrlDialog> createState() => _ImportUrlDialogState();
}

class _ImportUrlDialogState extends State<ImportUrlDialog> {
  final _urlController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Pega una URL');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final point = await widget.onResolve(text);
      if (!mounted) return;
      Navigator.pop(context, point);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar desde Google Maps'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Enlace de Google Maps',
              hintText: 'maps.app.goo.gl/...',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
