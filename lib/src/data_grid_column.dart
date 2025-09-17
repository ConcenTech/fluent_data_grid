import 'package:fluent_ui/fluent_ui.dart';

import 'filter/filter_type.dart';

/// Definition for a DataGrid column
class DataGridColumn<T> {
  /// The column title
  final String title;

  /// Width of the column. If null, width will be calculated automatically based on content.
  /// Note: Auto-width is less performant than fixed width, so prefer fixed widths when possible.
  final double? width;

  /// Function to extract the display string for this column
  /// Must return a String. If you need custom UI, use `cellBuilder`.
  final String Function(T item) valueBuilder;

  /// Function to sort data by this column
  final int Function(T a, T b)? sortBy;

  /// Custom cell builder. Receives the `value` returned by `valueBuilder`.
  final Widget Function(BuildContext context, T item, String value)?
  cellBuilder;

  /// Text alignment for the column
  final TextAlign textAlign;

  /// Function to filter data by this column
  final bool Function(T item, String filterValue)? filterPredicate;

  /// Custom filter widget builder
  final Widget Function(
    BuildContext context,
    String filterValue,
    ValueChanged<String> onFilterChanged,
  )?
  filterBuilder;

  /// Filter type for this column
  final FilterType filterType;

  /// Available options for dropdown filters
  final List<String>? filterOptions;

  const DataGridColumn({
    required this.title,
    this.width,
    required this.valueBuilder,
    this.sortBy,
    this.cellBuilder,
    this.textAlign = TextAlign.left,
    this.filterPredicate,
    this.filterBuilder,
    this.filterType = FilterType.none,
    this.filterOptions,
  });
}
