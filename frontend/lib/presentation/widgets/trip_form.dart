import 'package:flutter/material.dart';

import '../../data/models/trip.dart';
import '../../data/models/trip_draft.dart';

class TripForm extends StatefulWidget {
  const TripForm({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.onDelete,
    this.onPickImage,
    this.initialTrip,
    this.initialDraft,
  });

  final void Function(TripDraft draft) onSave;
  final VoidCallback onCancel;
  final VoidCallback? onDelete;
  final Future<String?> Function()? onPickImage;
  final Trip? initialTrip;
  final TripDraft? initialDraft;

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final trip = widget.initialTrip;
    final draft = widget.initialDraft;
    final now = DateTime.now();
    _nameController = TextEditingController(text: trip?.name ?? draft?.name);
    _descriptionController = TextEditingController(
      text: trip?.description ?? draft?.description ?? '',
    );
    _urlController = TextEditingController(
      text: trip?.imageUrl ?? draft?.imageUrl ?? '',
    );
    _startDate =
        trip?.startDate ??
        draft?.startDate ??
        DateTime(now.year, now.month, now.day);
    _endDate =
        trip?.endDate ??
        draft?.endDate ??
        _startDate.add(const Duration(days: 1));
    _imageUrl = trip?.imageUrl ?? draft?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && !_endDate.isBefore(_startDate);

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _handlePickImage() async {
    final onPickImage = widget.onPickImage;
    if (onPickImage == null) return;
    final url = await onPickImage();
    if (url == null || !mounted) return;
    setState(() {
      _imageUrl = url;
      _urlController.text = url;
    });
  }

  void _handleRemoveImage() {
    setState(() {
      _imageUrl = null;
      _urlController.clear();
    });
  }

  void _handleUrlChanged(String value) {
    setState(() => _imageUrl = value.trim().isEmpty ? null : value.trim());
  }

  void _handleSave() {
    final description = _descriptionController.text.trim();
    widget.onSave(
      TripDraft(
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        description: description.isEmpty ? null : description,
        imageUrl: _imageUrl,
      ),
    );
  }

  Future<void> _handleDeleteTap() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar viaje'),
          content: const Text('¿Eliminar este viaje?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    onDelete();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _pickDate(isStart: true),
                    icon: const Icon(Icons.event),
                    label: Text('Fecha inicio: ${_formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _pickDate(isStart: false),
                    icon: const Icon(Icons.event),
                    label: Text('Fecha fin: ${_formatDate(_endDate)}'),
                  ),
                ),
              ],
            ),
            if (_endDate.isBefore(_startDate))
              Text(
                'La fecha de fin debe ser posterior a la de inicio',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 8),
            if (_imageUrl != null) ...[
              Image.network(
                _imageUrl!,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                if (widget.onPickImage != null)
                  OutlinedButton.icon(
                    onPressed: _handlePickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Subir imagen'),
                  ),
                const SizedBox(width: 8),
                if (_imageUrl != null)
                  OutlinedButton.icon(
                    onPressed: _handleRemoveImage,
                    icon: const Icon(Icons.close),
                    label: const Text('Quitar imagen'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              onChanged: _handleUrlChanged,
              decoration: const InputDecoration(labelText: 'URL de imagen'),
            ),
            const SizedBox(height: 16),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: _handleDeleteTap,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Eliminar'),
                  ),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: _canSave ? _handleSave : null,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
