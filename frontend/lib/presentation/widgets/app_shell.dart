import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Breakpoint that splits the app into a desktop layout (>= 800 dp) and a
/// mobile layout (< 800 dp).
const double kDesktopBreakpoint = 800.0;

/// Whether [width] deserves the desktop layout. Width >= 800 only decides
/// LAYOUT, never the input modality (menus are decided by TargetPlatform).
bool isDesktopLayout(double width) => width >= kDesktopBreakpoint;

/// Responsive navigation shell hosting the Mapa/Viajes contents.
///
/// - < 800 dp: docked [NavigationBar] with terracotta indicator.
/// - >= 800 dp: fixed top bar (surface/80 + blur) with sections on the right.
///
/// Both layouts share a single [IndexedStack] so switching tabs never
/// recreates the children and crossing the breakpoint preserves state.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.children,
    this.onTabChanged,
  });

  /// The tab contents (Mapa first, Viajes second).
  final List<Widget> children;

  /// Called when the active tab changes.
  final ValueChanged<int>? onTabChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Keeps the tab contents alive when the layout switches between mobile and
  /// desktop: the [IndexedStack] moves to a different position in the element
  /// tree, and a [GlobalKey] makes Flutter reparent it instead of recreating
  /// it (preserving the State of TravelMap/TripsScreen and their controllers).
  final GlobalKey _stackKey = GlobalKey();

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    widget.onTabChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = isDesktopLayout(constraints.maxWidth);
        return Scaffold(
          body: desktop ? _buildDesktop(context) : _buildMobile(context),
          bottomNavigationBar: desktop ? null : _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Column(
      children: [
        _DesktopTopBar(
          index: _index,
          onSelect: _select,
        ),
        Expanded(child: _buildIndexedStack()),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return _buildIndexedStack();
  }

  Widget _buildIndexedStack() {
    return IndexedStack(
      key: _stackKey,
      index: _index,
      children: widget.children,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: NavigationBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        indicatorColor: AppColors.primary,
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: 'Viajes',
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('app-shell-desktop-top-bar'),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.muted.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'TravelPlan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _TopBarSection(
                  label: 'Mapa',
                  active: index == 0,
                  onTap: () => onSelect(0),
                ),
                const SizedBox(width: 8),
                _TopBarSection(
                  label: 'Viajes',
                  active: index == 1,
                  onTap: () => onSelect(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarSection extends StatelessWidget {
  const _TopBarSection({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pill,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.text,
          ),
        ),
      ),
    );
  }
}