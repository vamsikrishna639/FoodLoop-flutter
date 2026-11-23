// The frame around every signed-in screen. One widget, three layouts:
//
//   Mobile  (< 600)     bottom bar with a raised centre action
//   Tablet  (600-1024)  navigation rail on the left
//   Desktop (> 1024)    menu-board sidebar | content | activity rail
import 'package:material_ui/material_ui.dart';

import '../core/responsive/breakpoints.dart';
import '../core/theme/tokens.dart';
import '../models/user.dart';
import 'brand_mark.dart';
import 'pressable.dart';

/// One destination in the navigation.
class ShellDestination {
  const ShellDestination({required this.label, required this.icon, required this.path, this.badge = 0});
  final String label;
  final IconData icon;
  final String path;
  final int badge; // unread count; 0 hides the badge
}

/// The role's main action ("Post food", "Browse").
class ShellAction {
  const ShellAction({required this.label, required this.icon, required this.onTap, this.path});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Set when the action IS a page (the recipient's Browse opens the
  /// counter). On phones the raised action then replaces that page's tab,
  /// so the bar does not offer the same place twice, and it shows as
  /// selected while that page is open.
  final String? path;
}

class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.destinations,
    required this.currentPath,
    required this.onNavigate,
    required this.user,
    required this.child,
    this.action,
    this.activityRail,
  });

  final List<ShellDestination> destinations;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final AppUser user;
  final Widget child;
  final ShellAction? action;
  final Widget? activityRail; // shown on desktop only

  static const double sidebarWidth = 248;
  static const double railWidth = 92;
  static const double activityWidth = 304;

  /// How far the raised centre action pokes above the 68px bottom bar.
  /// Scroll views on phones add this to their bottom padding, so the last
  /// item can always scroll clear of the button.
  static const double raisedOverhang = 28;

  bool _isCurrent(ShellDestination d) => currentPath == d.path || currentPath.startsWith('${d.path}/');

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;

    switch (context.screen) {
      case ScreenSize.mobile:
        return Scaffold(
          body: SafeArea(bottom: false, child: child),
          bottomNavigationBar: _BottomBar(
            destinations: [
              for (final d in destinations)
                if (action?.path == null || d.path != action!.path) d,
            ],
            isCurrent: _isCurrent,
            actionSelected: action?.path != null &&
                (currentPath == action!.path || currentPath.startsWith('${action!.path}/')),
            onNavigate: onNavigate,
            action: action,
          ),
        );

      case ScreenSize.tablet:
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                _SideNav(
                  compact: true,
                  destinations: destinations,
                  isCurrent: _isCurrent,
                  onNavigate: onNavigate,
                  action: action,
                  user: user,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        );

      case ScreenSize.desktop:
        return Scaffold(
          body: Row(
            children: [
              _SideNav(
                compact: false,
                destinations: destinations,
                isCurrent: _isCurrent,
                onNavigate: onNavigate,
                action: action,
                user: user,
              ),
              // Content grows up to the max width, then stays left-aligned
              // next to the sidebar instead of floating in the middle.
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent - sidebarWidth),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: child),
                        if (activityRail != null)
                          Container(
                            width: activityWidth,
                            decoration: BoxDecoration(border: Border(left: BorderSide(color: fl.line))),
                            child: activityRail,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Tablet rail and desktop sidebar. Both are styled as the canteen menu board,
// so they stay dark in light mode too.
// ---------------------------------------------------------------------------

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.compact,
    required this.destinations,
    required this.isCurrent,
    required this.onNavigate,
    required this.user,
    this.action,
  });

  final bool compact; // true = tablet rail (icons over labels)
  final List<ShellDestination> destinations;
  final bool Function(ShellDestination) isCurrent;
  final ValueChanged<String> onNavigate;
  final AppUser user;
  final ShellAction? action;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final pad = compact ? FlSpace.sm : FlSpace.lg;

    return Container(
      width: compact ? ResponsiveShell.railWidth : ResponsiveShell.sidebarWidth,
      color: fl.board,
      padding: EdgeInsets.fromLTRB(pad, FlSpace.xl, pad, FlSpace.lg),
      child: Column(
        crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: compact ? 0 : FlSpace.sm),
            child: BrandMark(onDark: true, showWordmark: !compact, size: compact ? 36 : 30),
          ),
          const SizedBox(height: FlSpace.xl),
          if (action != null) ...[
            _SideAction(action: action!, compact: compact),
            const SizedBox(height: FlSpace.lg),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final d in destinations)
                    _SideItem(
                      destination: d,
                      selected: isCurrent(d),
                      compact: compact,
                      onTap: () => onNavigate(d.path),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlSpace.sm),
          _UserChip(user: user, compact: compact, onTap: () => onNavigate('/profile')),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({required this.action, required this.compact});
  final ShellAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Pressable(
      onTap: action.onTap,
      semanticLabel: action.label,
      focusRadius: FlRadius.control,
      onBoard: true,
      // Same colours as the accent FlButton: chilliDeep fill, onChilli label
      // (5.37 on paper, 5.51 on the chalkboard; hover stays above 4.5).
      // On the narrow rail the label sits under the icon, the way every
      // other rail item is labelled.
      builder: (context, hovered) => Container(
        constraints: BoxConstraints(minHeight: compact ? 64 : 48),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: FlSpace.xs, vertical: compact ? FlSpace.sm : 0),
        decoration: BoxDecoration(
          color: hovered ? fl.chilliDeep.withValues(alpha: 0.9) : fl.chilliDeep,
          borderRadius: BorderRadius.circular(FlRadius.control),
        ),
        child: ExcludeSemantics(
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: fl.onChilli, size: 22),
                    const SizedBox(height: FlSpace.xs),
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(color: fl.onChilli, fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: fl.onChilli, size: 22),
                    const SizedBox(width: FlSpace.sm),
                    Text(action.label, style: context.text.labelLarge?.copyWith(color: fl.onChilli)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.destination, required this.selected, required this.compact, required this.onTap});
  final ShellDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    // The current page looks like a paper label stuck on the board.
    final fg = selected ? fl.board : fl.chalk;
    final label = Text(
      destination.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (compact ? context.text.labelSmall : context.text.titleMedium)
          ?.copyWith(color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
    );
    final icon = _BadgedIcon(icon: destination.icon, color: fg, badge: destination.badge);

    return Padding(
      padding: const EdgeInsets.only(bottom: FlSpace.xs),
      child: Pressable(
        onTap: onTap,
        selected: selected,
        semanticLabel: destination.badge > 0
            ? '${destination.label}, ${destination.badge} unread'
            : destination.label,
        focusRadius: FlRadius.control,
        onBoard: true,
        // Only the fill colour changes, so it is treated as a fade.
        builder: (context, hovered) => AnimatedContainer(
          duration: FlMotion.fade(context, FlMotion.fast),
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(horizontal: compact ? FlSpace.xs : FlSpace.md, vertical: FlSpace.sm),
          decoration: BoxDecoration(
            color: selected
                ? fl.chalk
                : hovered
                    ? fl.chalk.withValues(alpha: 0.08)
                    : fl.chalk.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(FlRadius.control),
          ),
          child: ExcludeSemantics(
            child: compact
                ? Column(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(height: FlSpace.xs), label])
                : Row(children: [icon, const SizedBox(width: FlSpace.md), Expanded(child: label)]),
          ),
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user, required this.compact, required this.onTap});
  final AppUser user;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final avatar = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: fl.chalkSoft, width: 1.5),
      ),
      child: Text(user.initials, style: fl.mono.copyWith(color: fl.chalk, fontWeight: FontWeight.w700)),
    );

    return Pressable(
      onTap: onTap,
      semanticLabel: 'Profile and settings for ${user.name}',
      focusRadius: FlRadius.control,
      onBoard: true,
      builder: (context, hovered) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.all(FlSpace.sm),
        decoration: BoxDecoration(
          color: fl.chalk.withValues(alpha: hovered ? 0.08 : 0),
          borderRadius: BorderRadius.circular(FlRadius.control),
        ),
        child: ExcludeSemantics(
          child: compact
              ? avatar
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: FlSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall?.copyWith(color: fl.chalk)),
                          Text(user.role.label.toUpperCase(),
                              style: fl.monoSmall.copyWith(color: fl.chalkSoft)),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile bottom bar.
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.isCurrent,
    required this.onNavigate,
    this.action,
    this.actionSelected = false,
  });

  final List<ShellDestination> destinations;
  final bool Function(ShellDestination) isCurrent;
  final ValueChanged<String> onNavigate;
  final ShellAction? action;
  final bool actionSelected;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    Widget item(ShellDestination d) => Expanded(
          child: _BottomItem(destination: d, selected: isCurrent(d), onTap: () => onNavigate(d.path)),
        );

    // With a centre action, half the destinations sit on each side of it.
    final half = (destinations.length / 2).ceil();
    final children = action == null
        ? [for (final d in destinations) item(d)]
        : [
            for (final d in destinations.take(half)) item(d),
            Expanded(child: _RaisedAction(action: action!, selected: actionSelected)),
            for (final d in destinations.skip(half)) item(d),
          ];

    return Container(
      decoration: BoxDecoration(color: fl.surface, border: Border(top: BorderSide(color: fl.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          // The raised action pokes out above the bar, so do not clip it.
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.destination, required this.selected, required this.onTap});
  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    final color = selected ? fl.ink : fl.inkSoft;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel:
          destination.badge > 0 ? '${destination.label}, ${destination.badge} unread' : destination.label,
      focusRadius: FlRadius.control,
      builder: (context, _) => ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BadgedIcon(icon: destination.icon, color: color, badge: destination.badge),
            const SizedBox(height: FlSpace.xs),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall
                  ?.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
            const SizedBox(height: 3),
            // A short ink dash marks the current tab (shape, not only colour).
            // It is not animated: tabs are tapped many times a day, and the
            // page's own cross-fade already confirms the change.
            Container(
              height: 3,
              width: selected ? 20 : 0,
              decoration: BoxDecoration(color: fl.ink, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaisedAction extends StatelessWidget {
  const _RaisedAction({required this.action, this.selected = false});
  final ShellAction action;
  final bool selected; // the action's own page is open

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Pressable(
      onTap: action.onTap,
      semanticLabel: action.label,
      selected: selected,
      focusRadius: FlRadius.control,
      builder: (context, _) => ExcludeSemantics(
        child: OverflowBox(
          maxHeight: 96,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: fl.chilliDeep,
                  borderRadius: BorderRadius.circular(FlRadius.slip),
                  border: Border.all(color: fl.surface, width: 3),
                  boxShadow: [
                    BoxShadow(color: fl.ink.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(action.icon, color: fl.onChilli, size: 26),
              ),
              const SizedBox(height: FlSpace.xs),
              Text(action.label,
                  maxLines: 1,
                  style: context.text.labelSmall?.copyWith(color: fl.ink, fontWeight: FontWeight.w700)),
              // The same ink dash as a selected tab, then the space that
              // lines this label up with the labels of the tabs beside it.
              const SizedBox(height: 3),
              Container(
                height: 3,
                width: selected ? 20 : 0,
                decoration: BoxDecoration(color: fl.ink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 9),
            ],
          ),
        ),
      ),
    );
  }
}

/// An icon with an optional unread count in the corner.
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.color, required this.badge});
  final IconData icon;
  final Color color;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final fl = context.fl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 24),
        if (badge > 0)
          Positioned(
            right: -8,
            top: -5,
            child: Container(
              // Minimums, so the count still fits when text is enlarged.
              // monoSmall (11.5) is the smallest size the app prints.
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fl.chilliDeep, borderRadius: BorderRadius.circular(10)),
              child: Text(
                badge > 9 ? '9+' : '$badge',
                style: fl.monoSmall.copyWith(
                    color: fl.onChilli, fontWeight: FontWeight.w700, letterSpacing: 0, height: 1),
              ),
            ),
          ),
      ],
    );
  }
}
