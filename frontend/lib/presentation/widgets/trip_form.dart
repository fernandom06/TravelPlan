import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/day_label.dart';
import '../../data/models/trip.dart';
import '../../data/models/trip_draft.dart';
import 'sketchbook_name_field.dart';

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

  bool get _datesValid => !_endDate.isBefore(_startDate);

  bool get _canSave => _nameController.text.trim().isNotEmpty && _datesValid;

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

  /// Start/end as two pill chips in a [Wrap]: they reflow on narrow screens
  /// instead of squeezing into one row, and speak the itinerary's "05 Jun"
  /// day vocabulary.
  Widget _dateChip({required bool isStart}) {
    final date = isStart ? _startDate : _endDate;
    final sameYear = _startDate.year == _endDate.year;
    final label = isStart
        ? 'Del ${dayLabel(date)}${sameYear ? '' : ' ${date.year}'}'
        : 'Al ${dayLabel(date)} ${date.year}';
    return OutlinedButton.icon(
      key: Key(isStart ? 'trip-start-date' : 'trip-end-date'),
      onPressed: () => _pickDate(isStart: isStart),
      icon: const Icon(Icons.event, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.pill),
        textStyle: const TextStyle(fontFamily: 'Lora', fontSize: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SketchbookNameField(
            key: const Key('trip-name-field'),
            controller: _nameController,
            autofocus: true,
            hint: 'Nombra el viaje...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [_dateChip(isStart: true), _dateChip(isStart: false)],
          ),
          if (!_datesValid)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'La fecha de fin debe ser posterior a la de inicio',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              labelStyle: TextStyle(fontFamily: 'Lora', color: AppColors.text),
              filled: true,
              fillColor: Color(0x80F4F1DE), // paper tone
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_imageUrl != null) ...[
            ClipRRect(
              borderRadius: AppRadii.organic,
              child: Image.network(
                _imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OverflowBar(
            alignment: MainAxisAlignment.start,
            spacing: AppSpacing.sm,
            overflowSpacing: AppSpacing.sm,
            children: [
              if (widget.onPickImage != null)
                OutlinedButton.icon(
                  onPressed: _handlePickImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Subir imagen'),
                ),
              if (_imageUrl != null)
                OutlinedButton.icon(
                  onPressed: _handleRemoveImage,
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar imagen'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _urlController,
            onChanged: _handleUrlChanged,
            decoration: const InputDecoration(
              labelText: 'URL de imagen',
              labelStyle: TextStyle(fontFamily: 'Lora', color: AppColors.text),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                // Deep terracotta: white on [primary] only reaches ~2.9:1 —
                // same AA fix as the day pills, FAB and place footer.
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(96, 48),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
