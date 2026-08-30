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

  String get _skipMessage {
    final count = _controller.value.points.length;
    if (count >= 3) return 'Se descartarán los $count puntos dibujados.';
    return 'Se descartará el polígono dibujado.';
  }

  Future<void> _handleSkip() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('¿Omitir la zona?'),
          content: const Text('El viaje se creará sin zona.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Omitir la zona'),
          content: Text(_skipMessage),
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
    if (second != true || !mounted) return;
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
                Positioned.fill(
                  child: ZoneMap(controller: _controller),
                ),
                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(child: _ZonePill()),
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