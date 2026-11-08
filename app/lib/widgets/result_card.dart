import 'package:flutter/material.dart';

import 'surface_card.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.title,
    required this.value,
    required this.onCopy,
    this.monospace = false,
    this.footnote,
    this.actions = const [],
    this.maxHeight = 240,
  });

  final String title;
  final String value;
  final VoidCallback onCopy;
  final bool monospace;
  final String? footnote;
  final List<Widget> actions;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      accent: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                value.isEmpty ? '(empty message)' : value,
                style: text.bodyMedium?.copyWith(
                  fontFamily: monospace ? 'monospace' : null,
                  height: 1.5,
                  letterSpacing: monospace ? 0.2 : null,
                  color: value.isEmpty ? scheme.onSurfaceVariant : null,
                  fontStyle: value.isEmpty ? FontStyle.italic : null,
                ),
              ),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 10),
            Text(
              footnote!,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}
