import 'package:fluent_ui/fluent_ui.dart';

import '../fluent_data_grid.dart';
import 'data_grid_cell.dart';

class DataGridRow<T> extends StatelessWidget {
  final T item;
  final int index;
  final List<DataGridColumn<T>> columns;
  final bool showRowNumbers;
  final bool isSelected;
  final bool isAlternating;
  final SelectionMode selectionMode;
  final double rowHeight;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, T item, int index)? rowBuilder;
  final double Function(DataGridColumn<T> column)? getColumnWidth;

  const DataGridRow({
    super.key,
    required this.item,
    required this.index,
    required this.columns,
    required this.showRowNumbers,
    required this.isSelected,
    required this.isAlternating,
    required this.selectionMode,
    required this.rowHeight,
    this.onTap,
    this.rowBuilder,
    this.getColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    if (rowBuilder != null) {
      return rowBuilder!(context, item, index);
    }

    return MouseRegion(
      cursor:
          onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: rowHeight,
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? theme.accentColor.withValues(alpha: 0.1)
                      : isAlternating
                      ? theme.menuColor
                      : null,
              border: Border(
                bottom: BorderSide(
                  color: theme.resources.cardStrokeColorDefault.withValues(
                    alpha: 0.5,
                  ),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                if (selectionMode == SelectionMode.multi)
                  Container(
                    width: 40,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.resources.cardStrokeColorDefault,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Checkbox(
                        checked: isSelected,
                        onChanged: onTap != null ? (_) => onTap!() : null,
                      ),
                    ),
                  ),
                if (showRowNumbers)
                  Container(
                    width: 60,
                    height: rowHeight,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: theme.resources.cardStrokeColorDefault,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.typography.caption,
                      ),
                    ),
                  ),
                for (final column in columns)
                  DataGridCell<T>(
                    item: item,
                    column: column,
                    rowHeight: rowHeight,
                    width: getColumnWidth?.call(column),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
