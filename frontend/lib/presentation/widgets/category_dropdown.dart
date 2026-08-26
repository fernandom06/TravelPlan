import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/category_icon_catalog.dart';
import '../../data/models/category.dart';
import '../../data/models/place.dart';
import '../../data/place_api.dart';
import 'category_icon_picker.dart';

/// A custom Material 3 dropdown for selecting and managing categories.
///
/// Unlike [DropdownButtonFormField], this dropdown keeps its menu open while
/// editing/creating categories inline, and supports per-row edit/delete
/// affordances. It owns all of the category-management UI state (inline
/// editing/creation, errors, delete dialogs) and notifies its parent through
/// the provided callbacks.
class CategoryDropdown extends StatefulWidget {
  const CategoryDropdown({
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
  State<CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  bool _isOpen = false;
  final GlobalKey _triggerKey = GlobalKey();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final FocusNode _triggerFocus;

  int? _editingId;
  late final TextEditingController _editController;
  late final FocusNode _editFocus;
  late final FocusNode _editInputFocus;
  String? _editError;
  String? _editIcon;
  bool _isSubmittingEdit = false;

  bool _isCreating = false;
  late final TextEditingController _createController;
  late final FocusNode _createFocus;
  late final FocusNode _createInputFocus;
  String? _createError;
  String? _createIcon;
  bool _isSubmittingCreate = false;

  @override
  void initState() {
    super.initState();
    _triggerFocus = widget.focusNode ?? FocusNode();
    _triggerFocus.addListener(_handleTriggerFocusChange);
    _editController = TextEditingController();
    _editFocus = FocusNode();
    _editInputFocus = FocusNode();
    _createController = TextEditingController();
    _createFocus = FocusNode();
    _createInputFocus = FocusNode();
  }

  @override
  void dispose() {
    _triggerFocus.removeListener(_handleTriggerFocusChange);
    if (widget.focusNode == null) {
      _triggerFocus.dispose();
    }
    _editController.dispose();
    _editFocus.dispose();
    _editInputFocus.dispose();
    _createController.dispose();
    _createFocus.dispose();
    _createInputFocus.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) return;
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _overlayController.show();
      } else {
        _overlayController.hide();
      }
    });
  }

  void _open() {
    if (!widget.enabled || _isOpen) return;
    setState(() {
      _isOpen = true;
      _overlayController.show();
    });
  }

  void _handleTriggerFocusChange() {
    if (!mounted) return;
    if (_triggerFocus.hasFocus) {
      if (widget.enabled && !_isOpen) _open();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_createInputFocus.hasFocus && !_editInputFocus.hasFocus) {
          _close();
        }
      });
    }
  }

  void _close() {
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
      _editingId = null;
      _editError = null;
      _editIcon = null;
      _isCreating = false;
      _createError = null;
      _createIcon = null;
      _overlayController.hide();
    });
  }

  void _startEdit(Category c) {
    _editController.text = c.name;
    setState(() {
      _editingId = c.id;
      _editError = null;
      _editIcon = c.icon;
      _isSubmittingEdit = false;
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) _triggerFocus.requestFocus();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _triggerFocus.requestFocus();
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
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _confirmEdit();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelEdit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startCreate() {
    _createController.clear();
    setState(() {
      _isCreating = true;
      _createError = null;
      _createIcon = null;
      _isSubmittingCreate = false;
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) _triggerFocus.requestFocus();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _triggerFocus.requestFocus();
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
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _confirmCreate();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelCreate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

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
                  Text(
                    'La categoría tiene $count lugar(es). Elige el destino:',
                  ),
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

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final selectedName = value?.name ?? '';
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (context) => _buildOverlay(context),
      child: Focus(
        focusNode: _triggerFocus,
        canRequestFocus: widget.enabled,
        descendantsAreFocusable: false,
        child: GestureDetector(
          key: _triggerKey,
          onTap: _toggle,
          child: InputDecorator(
            isEmpty: selectedName.isEmpty,
            isFocused: _isOpen,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null) ...[
                  Icon(categoryIconFor(value.icon), size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    selectedName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    // Keep a small margin from the screen edges so the panel is always
    // reachable, even on narrow screens or when the trigger sits near an edge.
    const margin = 8.0;
    // A fixed, content-appropriate panel width (fits name + edit/delete icons
    // and the inline edit/create rows), capped so it never exceeds the screen.
    final panelWidth = math.min(
      300.0,
      math.max(200.0, screenWidth - 2 * margin),
    );

    Offset triggerPos = Offset.zero;
    Size triggerSize = Size.zero;
    final triggerBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (triggerBox != null && triggerBox.attached) {
      triggerPos = triggerBox.localToGlobal(Offset.zero);
      triggerSize = triggerBox.size;
    }

    // Place the panel below the field, then clamp it so it cannot overflow the
    // right or bottom edges of the screen.
    final left = (triggerPos.dx)
        .clamp(margin, math.max(margin, screenWidth - panelWidth - margin))
        .toDouble();
    final top = (triggerPos.dy + triggerSize.height + 4)
        .clamp(margin, math.max(margin, screenHeight - 4))
        .toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: _buildPanel(context, panelWidth),
        ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context, double width) {
    return Material(
      elevation: 8,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Stretch the rows so each ListTile fills the (bounded) panel width
          // instead of expanding to the full overlay width and overflowing.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in widget.categories) _buildRow(context, c),
            if (widget.enabled && widget.onCreate != null) ...[
              if (_isCreating)
                _buildCreateRow(context)
              else
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Nueva categoría'),
                  onTap: _startCreate,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRow(BuildContext context) {
    return FocusTraversalGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _createFocus,
                    onKeyEvent: _handleCreateKey,
                    child: TextField(
                      controller: _createController,
                      focusNode: _createInputFocus,
                      onSubmitted: (_) => _confirmCreate(),
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la categoría',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(categoryIconFor(_createIcon)),
                  tooltip: 'Elegir icono',
                  onPressed: () => _pickIcon(forCreate: true),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Confirmar',
                  onPressed: _isSubmittingCreate ? null : _confirmCreate,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar',
                  onPressed: _cancelCreate,
                ),
              ],
            ),
            if (_createError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _createError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Category c) {
    final showEdit = widget.enabled && widget.onRename != null;
    final showDelete = widget.enabled && widget.onDelete != null;
    if (_editingId == c.id) {
      return _buildEditRow(context, c);
    }
    return ListTile(
      leading: Icon(categoryIconFor(c.icon)),
      title: Text(c.name),
      onTap: () {
        widget.onChanged(c);
        _close();
      },
      trailing: (showEdit || showDelete)
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showEdit)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Renombrar categoría',
                    onPressed: () => _startEdit(c),
                  ),
                if (showDelete)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar categoría',
                    onPressed: () => _handleDelete(c),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildEditRow(BuildContext context, Category c) {
    return FocusTraversalGroup(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Focus(
                    focusNode: _editFocus,
                    onKeyEvent: _handleEditKey,
                    child: TextField(
                      controller: _editController,
                      focusNode: _editInputFocus,
                      onSubmitted: (_) => _confirmEdit(),
                      decoration: const InputDecoration(
                        labelText: 'Nuevo nombre',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(categoryIconFor(_editIcon)),
                  tooltip: 'Elegir icono',
                  onPressed: () => _pickIcon(forCreate: false),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Confirmar',
                  onPressed: _isSubmittingEdit ? null : _confirmEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar',
                  onPressed: _cancelEdit,
                ),
              ],
            ),
            if (_editError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _editError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
