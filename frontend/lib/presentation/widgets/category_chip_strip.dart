import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/place_api.dart';
import 'category_icon_picker.dart';
import 'entity_actions.dart';

/// Horizontal scrollable strip of category pills.
///
/// - Selected pill: mint fill, white icon+text, slightly scaled up.
/// - Unselected pill: white with a 2px sand border, navy text.
/// - A trailing "+" pill opens the inline creation flow (name + icon picker,
///   duplicate 409 shown inline).
/// - Each pill offers rename/delete through [EntityActions] (long-press on
///   touch, hover ⋮ on desktop with a mouse), reusing the rename logic and the
///   delete-with-reassignment dialog (conflict → destination picker; only
///   category → warning).
class CategoryChipStrip extends StatefulWidget {
  const CategoryChipStrip({
    super.key,
    required this.categories,
    this.value,
    this.enabled = true,
    required this.onChanged,
    this.onCreate,
    this.onRename,
    this.onDelete,
    this.places = const [],
    this.onCategoryAdded,
    this.onCategoryRenamed,
    this.onCategoryDeleted,
    this.focusNode,
  });

  final List<Category> categories;
  final Category? value;
  final bool enabled;
  final ValueChanged<Category?> onChanged;
  final Future<Category> Function(String name, String? icon)? onCreate;
  final Future<Category> Function(int id, String name, String? icon)? onRename;
  final Future<void> Function(int id, int? reassignTo)? onDelete;
  final List<Place> places;
  final ValueChanged<Category>? onCategoryAdded;
  final ValueChanged<Category>? onCategoryRenamed;
  final ValueChanged<int>? onCategoryDeleted;
  final FocusNode? focusNode;

  @override
  State<CategoryChipStrip> createState() => _CategoryChipStripState();
}

class _CategoryChipStripState extends State<CategoryChipStrip> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chipKeys = {};
  final GlobalKey _createEditorKey = GlobalKey();
  final GlobalKey _addChipKey = GlobalKey();

  int? _editingId;
  late final TextEditingController _editController;
  late final FocusNode _editInputFocus;
  String? _editError;
  String? _editIcon;
  bool _isSubmittingEdit = false;

  bool _isCreating = false;
  late final TextEditingController _createController;
  late final FocusNode _createInputFocus;
  String? _createError;
  String? _createIcon;
  bool _isSubmittingCreate = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _createController = TextEditingController();
    _editInputFocus = FocusNode();
    _createInputFocus = FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    _createController.dispose();
    _editInputFocus.dispose();
    _createInputFocus.dispose();
    super.dispose();
  }

  GlobalKey _chipKey(int id) => _chipKeys.putIfAbsent(id, () => GlobalKey());

  bool get _canManage => widget.enabled;

  // ---- selection -----------------------------------------------------------

  void _select(Category c) {
    widget.onChanged(c);
  }

  // ---- inline rename --------------------------------------------------------

  void _startEdit(Category c) {
    if (!_canManage || widget.onRename == null) return;
    _editController.text = c.name;
    setState(() {
      _editingId = c.id;
      _editError = null;
      _editIcon = c.icon;
      _isSubmittingEdit = false;
    });
    _ensureVisible(_chipKey(c.id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editInputFocus.requestFocus();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _editError = null;
      _editIcon = null;
      _isSubmittingEdit = false;
    });
  }

  Future<void> _confirmEdit() async {
    final id = _editingId;
    final onRename = widget.onRename;
    if (id == null || onRename == null || _isSubmittingEdit) return;
    final name = _editController.text.trim();
    if (name.isEmpty) {
      setState(() => _editError = 'El nombre no puede estar vacío');
      return;
    }
    setState(() {
      _editError = null;
      _isSubmittingEdit = true;
    });
    try {
      final renamed = await onRename(id, name, _editIcon);
      if (!mounted) return;
      widget.onCategoryRenamed?.call(renamed);
      if (widget.value?.id == id) {
        widget.onChanged(renamed);
      }
      setState(() {
        _editingId = null;
        _editError = null;
        _editIcon = null;
        _isSubmittingEdit = false;
      });
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _editError = 'Ya existe una categoría con ese nombre';
        _isSubmittingEdit = false;
      });
    } on PlaceApiException {
      if (!mounted) return;
      setState(() {
        _editError = 'No se pudo renombrar la categoría';
        _isSubmittingEdit = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _editError = 'No se pudo renombrar la categoría';
        _isSubmittingEdit = false;
      });
    }
  }

  KeyEventResult _handleEditKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirmEdit();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelEdit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- inline create --------------------------------------------------------

  void _startCreate() {
    if (!_canManage || widget.onCreate == null) return;
    _createController.clear();
    setState(() {
      _isCreating = true;
      _createError = null;
      _createIcon = null;
      _isSubmittingCreate = false;
    });
    _ensureVisible(_createEditorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _createInputFocus.requestFocus();
    });
  }

  void _cancelCreate() {
    setState(() {
      _isCreating = false;
      _createError = null;
      _createIcon = null;
      _isSubmittingCreate = false;
    });
  }

  Future<void> _confirmCreate() async {
    final onCreate = widget.onCreate;
    if (onCreate == null || _isSubmittingCreate) return;
    final name = _createController.text.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'El nombre no puede estar vacío');
      return;
    }
    setState(() {
      _createError = null;
      _isSubmittingCreate = true;
    });
    try {
      final category = await onCreate(name, _createIcon);
      if (!mounted) return;
      widget.onCategoryAdded?.call(category);
      // Autoselect the newly created category.
      widget.onChanged(category);
      setState(() {
        _isCreating = false;
        _createError = null;
        _createIcon = null;
        _isSubmittingCreate = false;
      });
    } on DuplicateCategoryException {
      if (!mounted) return;
      setState(() {
        _createError = 'Ya existe una categoría con ese nombre';
        _isSubmittingCreate = false;
      });
    } on PlaceApiException {
      if (!mounted) return;
      setState(() {
        _createError = 'No se pudo crear la categoría';
        _isSubmittingCreate = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _createError = 'No se pudo crear la categoría';
        _isSubmittingCreate = false;
      });
    }
  }

  KeyEventResult _handleCreateKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirmCreate();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelCreate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- icon picker ----------------------------------------------------------

  Future<void> _pickIcon({required bool forCreate}) async {
    final result = await pickCategoryIcon(
      context,
      current: forCreate ? _createIcon : _editIcon,
    );
    if (!mounted) return;
    setState(() {
      switch (result) {
        case IconPickerPicked(:final id):
          if (forCreate) {
            _createIcon = id;
          } else {
            _editIcon = id;
          }
        case IconPickerCleared():
          if (forCreate) {
            _createIcon = null;
          } else {
            _editIcon = null;
          }
        case IconPickerCancelled():
          break;
      }
    });
  }

  // ---- delete with reassignment ---------------------------------------------

  Future<void> _handleDelete(Category c) async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final count = widget.places.where((p) => p.category.id == c.id).length;
    final candidates = widget.categories.where((x) => x.id != c.id).toList();
    Category? destination;
    if (count > 0 && candidates.isNotEmpty) {
      destination = candidates.first;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        if (count == 0) {
          return AlertDialog(
            title: const Text('Eliminar categoría'),
            content: Text('Se eliminará "${c.name}"'),
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
        }
        if (candidates.isEmpty) {
          return AlertDialog(
            title: const Text('No se puede eliminar'),
            content: const Text(
              'Es la única categoría, crea otra antes de eliminar',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
            ],
          );
        }
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Eliminar categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('La categoría tiene $count lugar(es). Elige el destino:'),
                  DropdownButtonFormField<Category>(
                    initialValue: destination,
                    items: [
                      for (final cand in candidates)
                        DropdownMenuItem(value: cand, child: Text(cand.name)),
                    ],
                    onChanged: (x) => setDialogState(() => destination = x),
                    decoration: const InputDecoration(labelText: 'Mover a'),
                  ),
                ],
              ),
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
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await onDelete(c.id, destination?.id);
      if (!mounted) return;
      widget.onCategoryDeleted?.call(c.id);
      if (widget.value?.id == c.id) {
        widget.onChanged(null);
      }
    } on CategoryNotEmptyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar: la categoría tiene lugares sin destino',
          ),
        ),
      );
    } on InvalidReassignTargetException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El destino no es válido')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la categoría')),
      );
    }
  }

  // ---- helpers ---------------------------------------------------------------

  void _ensureVisible(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = key.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 200),
        alignment: 0.5,
      );
    });
  }

  // ---- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: const NumericFocusOrder(1),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 4),
            for (final c in widget.categories)
              if (_editingId == c.id)
                _buildEditEditor(c)
              else
                _buildChip(c),
            if (_isCreating) _buildCreateEditor(),
            if (widget.enabled && widget.onCreate != null) _buildAddChip(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(Category c) {
    final selected = widget.value?.id == c.id;
    final chip = _CategoryChip(
      category: c,
      selected: selected,
      enabled: widget.enabled,
      onTap: widget.enabled ? () => _select(c) : null,
    );
    if (_canManage && (widget.onRename != null || widget.onDelete != null)) {
      return EntityActions(
        key: _chipKey(c.id),
        onEdit: widget.onRename == null ? null : () => _startEdit(c),
        onDelete: widget.onDelete == null ? null : () => _handleDelete(c),
        child: chip,
      );
    }
    return KeyedSubtree(key: _chipKey(c.id), child: chip);
  }

  Widget _buildEditEditor(Category c) {
    return Padding(
      key: _chipKey(c.id),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _EditorChip(
        controller: _editController,
        focusNode: _editInputFocus,
        icon: _editIcon,
        hint: 'Nuevo nombre',
        error: _editError,
        submitting: _isSubmittingEdit,
        onKey: _handleEditKey,
        onPickIcon: () => _pickIcon(forCreate: false),
        onConfirm: _confirmEdit,
        onCancel: _cancelEdit,
        onSubmitted: (_) => _confirmEdit(),
      ),
    );
  }

  Widget _buildCreateEditor() {
    return Padding(
      key: _createEditorKey,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: _EditorChip(
        controller: _createController,
        focusNode: _createInputFocus,
        icon: _createIcon,
        hint: 'Nombre de la categoría',
        error: _createError,
        submitting: _isSubmittingCreate,
        onKey: _handleCreateKey,
        onPickIcon: () => _pickIcon(forCreate: true),
        onConfirm: _confirmCreate,
        onCancel: _cancelCreate,
        onSubmitted: (_) => _confirmCreate(),
      ),
    );
  }

  Widget _buildAddChip() {
    return Padding(
      key: _addChipKey,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppColors.background,
        shape: StadiumBorder(
          side: const BorderSide(color: AppColors.muted, width: 2),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _canManage ? _startCreate : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Icon(Icons.add, size: 20, color: AppColors.text),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.text;
    final bg = selected ? AppColors.accent : AppColors.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : const BorderSide(color: AppColors.muted, width: 2),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(categoryIconFor(category.icon), size: 16, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: fg,
                      fontFamily: 'Lora',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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

class _EditorChip extends StatelessWidget {
  const _EditorChip({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.hint,
    required this.error,
    required this.submitting,
    required this.onKey,
    required this.onPickIcon,
    required this.onConfirm,
    required this.onCancel,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? icon;
  final String hint;
  final String? error;
  final bool submitting;
  final KeyEventResult Function(FocusNode node, KeyEvent event) onKey;
  final VoidCallback onPickIcon;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                child: Focus(
                  onKeyEvent: onKey,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onSubmitted: onSubmitted,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(categoryIconFor(icon), size: 18),
                tooltip: 'Elegir icono',
                onPressed: onPickIcon,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Confirmar',
                onPressed: submitting ? null : onConfirm,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
                onPressed: onCancel,
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                error!,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}