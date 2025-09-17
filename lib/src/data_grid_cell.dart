import 'package:fluent_ui/fluent_ui.dart';

import 'data_grid_column.dart';

class DataGridCell<T> extends StatelessWidget {
  final T item;
  final DataGridColumn<T> column;
  final double rowHeight;
  final double? width;

  const DataGridCell({
    super.key,
    required this.item,
    required this.column,
    required this.rowHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final value = column.valueBuilder(item);

    return Container(
      width: width ?? column.width,
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: theme.resources.cardStrokeColorDefault,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child:
          column.cellBuilder != null
              ? column.cellBuilder!(context, item, value)
              : Align(
                alignment: _getAlignment(column.textAlign),
                child: Text(
                  value,
                  style: theme.typography.body,
                  textAlign: column.textAlign,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
    );
  }

  Alignment _getAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.left:
      default:
        return Alignment.centerLeft;
    }
  }
}
