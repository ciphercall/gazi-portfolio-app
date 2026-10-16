import 'package:flutter/material.dart';

import '../theme/aurora.dart';

/// Buttons.
///
/// Every one of these takes an icon AND a label, and the label is required. The
/// owner's standing rule is that a control is never a bare glyph: a glyph-only
/// button is only acceptable when the icon is unambiguous on its own, and here
/// nothing qualifies once you leave the app bar.
class AuroraButton extends StatelessWidget {
  const AuroraButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = AuroraButtonVariant.primary,
    this.expand = false,
    this.busy = false,
    this.semanticHint,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final AuroraButtonVariant variant;
  final bool expand;
  final bool busy;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2, color: Aurora.onAccent),
          )
        else
          Icon(
            icon,
            size: 17,
            color: variant == AuroraButtonVariant.primary
                ? Aurora.onAccent
                : Aurora.teal,
          ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Aurora.body(
              14,
              weight: 600,
              color: variant == AuroraButtonVariant.primary ? Aurora.onAccent : Aurora.ink,
            ),
          ),
        ),
      ],
    );

    final decoration = switch (variant) {
      AuroraButtonVariant.primary => BoxDecoration(
        gradient: Aurora.gradient(),
        borderRadius: BorderRadius.circular(Aurora.radiusPill),
      ),
      AuroraButtonVariant.secondary => BoxDecoration(
        color: Aurora.panelStrong,
        borderRadius: BorderRadius.circular(Aurora.radiusPill),
        border: Border.all(color: Aurora.lineStrong),
      ),
      AuroraButtonVariant.ghost => BoxDecoration(
        borderRadius: BorderRadius.circular(Aurora.radiusPill),
      ),
    };

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Semantics(
        button: true,
        label: semanticHint == null ? label : '$label, $semanticHint',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(Aurora.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: decoration,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

enum AuroraButtonVariant { primary, secondary, ghost }

/// A row of quick actions that wraps rather than overflowing. Two labelled
/// buttons side by side overflow on a narrow phone, so they fall to a second
/// line instead of being shrunk.
class AuroraActionRow extends StatelessWidget {
  const AuroraActionRow({super.key, required this.children, this.spacing = 10});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: spacing, runSpacing: spacing, children: children);
  }
}
