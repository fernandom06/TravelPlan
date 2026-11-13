import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/trip_draft.dart';
import '../controllers/zone_controller.dart';
import '../widgets/dashed_border_container.dart';
import '../widgets/zone_map.dart';

class ZoneMapScreen extends StatefulWidget {
  const ZoneMapScreen({super.key, required this.draft});

  final TripDraft draft;

  @override
  State<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends State<ZoneMapScreen> {
  final ZoneController _controller = ZoneController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCreate() {
    Navigator.pop(
      context,
      widget.draft.copyWith(zone: _controller.value.points),
    );
  }

  /// One confirmation for skipping, not two: it names the cost (the drawn
  /// points) and the outcome (a trip without a zone) in a single dialog.
  Future<void> _handleSkip() async {
    final count = _controller.value.points.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Omitir la zona?'),
          content: Text(
            count > 0
                ? 'Se descartarán los puntos dibujados. '
                      'El viaje se creará sin zona.'
                : 'El viaje se creará sin zona.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Omitir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    Navigator.pop(context, widget.draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zona del viaje (opcional)')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: ZoneMap(controller: _controller)),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: ValueListenableBuilder<ZoneState>(
                        valueListenable: _controller,
                        builder: (context, state, _) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _ZonePill(),
                            const SizedBox(height: AppSpacing.sm),
                            _ZoneHint(count: state.points.length),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ValueListenableBuilder<ZoneState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                final hasPoints = state.points.isNotEmpty;
                return OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: hasPoints ? _controller.undoLast : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('Deshacer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasPoints ? _controller.clear : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Limpiar'),
                    ),
                    TextButton(
                      onPressed: _handleSkip,
                      child: const Text('Omitir'),
                    ),
                    FilledButton(
                      onPressed: _controller.canCreate ? _handleCreate : null,
                      child: const Text('Crear viaje'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed "Área de Viaje" label pill centered over the drawing map.
class _ZonePill extends StatelessWidget {
  const _ZonePill();

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      color: AppColors.muted,
      radius: 999,
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: const Text(
        'Área de Viaje',
        style: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Contextual instruction under the pill: how to draw (a first-time user
/// must not have to guess the tap gesture or the 3-point minimum) and, once
/// drawing, a running counter that explains why "Crear viaje" is disabled.
class _ZoneHint extends StatelessWidget {
  const _ZoneHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = switch (count) {
      0 => 'Toca el mapa para delimitar la zona · mínimo 3 puntos',
      < 3 => '$count/3 · Toca el mapa para añadir más puntos',
      _ => '$count puntos · Zona lista para crear el viaje',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
