import 'package:fluent_ui/fluent_ui.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.itemsPerPage,
    this.onPageChanged,
  });

  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int itemsPerPage;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Hide pagination when there's no data
    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    final theme = FluentTheme.of(context);

    final startItem = (currentPage * itemsPerPage) + 1;
    final endItem = ((currentPage + 1) * itemsPerPage).clamp(0, totalItems);

    const iconSize = 12.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.resources.cardStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        spacing: 8,
        children: [
          Text(
            'Showing $startItem-$endItem of $totalItems items',
            style: theme.typography.caption,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed:
                    currentPage > 0 ? () => onPageChanged?.call(0) : null,
                icon: const Icon(
                  FluentIcons.double_chevron_left,
                  size: iconSize,
                ),
              ),
              IconButton(
                onPressed:
                    currentPage > 0
                        ? () => onPageChanged?.call(currentPage - 1)
                        : null,
                icon: const Icon(FluentIcons.chevron_left, size: iconSize),
              ),
              const SizedBox(width: 8),
              Text(
                'Page ${currentPage + 1} of $totalPages',
                style: theme.typography.caption,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    currentPage < totalPages - 1
                        ? () => onPageChanged?.call(currentPage + 1)
                        : null,
                icon: const Icon(FluentIcons.chevron_right, size: iconSize),
              ),
              IconButton(
                onPressed:
                    currentPage < totalPages - 1
                        ? () => onPageChanged?.call(totalPages - 1)
                        : null,
                icon: const Icon(
                  FluentIcons.double_chevron_right,
                  size: iconSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
