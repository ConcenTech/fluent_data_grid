import 'package:fluent_ui/fluent_ui.dart';

class FilterControls extends StatelessWidget {
  const FilterControls({
    super.key,
    required this.isActive,
    required this.activeCount,
    required this.onClearAll,
    required this.children,
  });

  final bool isActive;
  final int activeCount;
  final VoidCallback onClearAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.resources.cardStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Expander(
        initiallyExpanded: false,
        header: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Icon(
                FluentIcons.filter,
                size: 16,
                color: theme.resources.textFillColorSecondary,
              ),
              const SizedBox(width: 8),
              Text('Filters', style: theme.typography.bodyStrong),
              const Spacer(),
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.resources.cardStrokeColorDefault,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCount active',
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Button(onPressed: onClearAll, child: const Text('Clear All')),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 12, runSpacing: 8, children: children),
        ),
      ),
    );
  }
}
