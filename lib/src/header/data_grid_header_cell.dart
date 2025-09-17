import 'package:fluent_ui/fluent_ui.dart';

import '../data_grid_column.dart';

class DataGridHeaderCell<T> extends StatelessWidget {
  final DataGridColumn<T> column;
  final bool isSorted;
  final bool isAscending;
  final VoidCallback onSort;
  final double? width;

  const DataGridHeaderCell({
    super.key,
    required this.column,
    required this.isSorted,
    required this.isAscending,
    required this.onSort,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return MouseRegion(
      cursor:
          column.sortable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: column.sortable ? onSort : null,
        child: Container(
          width: width ?? column.width,
          height: 40,
          decoration: BoxDecoration(
            color: isSorted ? theme.accentColor.withValues(alpha: 0.1) : null,
            border: Border(
              right: BorderSide(
                color: theme.resources.cardStrokeColorDefault,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  column.title,
                  style: theme.typography.caption?.copyWith(
                    fontWeight: isSorted ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: column.textAlign,
                ),
              ),
              if (column.sortable) ...[
                const SizedBox(width: 4),
                Icon(
                  isSorted
                      ? (isAscending
                          ? FluentIcons.chevron_up
                          : FluentIcons.chevron_down)
                      : FluentIcons.chevron_up,
                  size: 14,
                  color: isSorted ? theme.accentColor : theme.inactiveColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
