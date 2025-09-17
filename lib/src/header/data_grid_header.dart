import 'package:fluent_ui/fluent_ui.dart';

import '../data_grid_column.dart';
import '../selection_mode.dart';
import 'data_grid_header_cell.dart';

class DataGridHeader<T> extends StatelessWidget {
  final List<DataGridColumn<T>> columns;
  final bool showRowNumbers;
  final SelectionMode selectionMode;
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final ScrollController horizontalController;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback? onSelectAll;
  final double Function(DataGridColumn<T> column)? getColumnWidth;

  const DataGridHeader({
    super.key,
    required this.columns,
    required this.showRowNumbers,
    required this.selectionMode,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.horizontalController,
    required this.allSelected,
    required this.someSelected,
    this.onSelectAll,
    this.getColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.menuColor,
        border: Border(
          bottom: BorderSide(
            color: theme.resources.cardStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (selectionMode == SelectionMode.multi)
            Container(
              width: 40,
              height: 40,
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
                  checked: allSelected ? true : (someSelected ? null : false),
                  onChanged: onSelectAll != null ? (_) => onSelectAll!() : null,
                ),
              ),
            ),
          if (showRowNumbers)
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.resources.cardStrokeColorDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Center(child: Text('#', style: theme.typography.caption)),
            ),
          for (int i = 0; i < columns.length; i++)
            DataGridHeaderCell<T>(
              column: columns[i],
              isSorted: sortColumnIndex == i,
              isAscending: sortAscending,
              onSort: () => onSort(i),
              width: getColumnWidth?.call(columns[i]),
            ),
        ],
      ),
    );
  }
}
