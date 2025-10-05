// ignore_for_file: library_private_types_in_public_api
import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart';

import 'data_grid_column.dart';
import 'data_grid_content.dart';
import 'filter/dropdown_column_filter.dart';
import 'filter/filter_controls.dart';
import 'filter/filter_type.dart';
import 'filter/text_column_filter.dart';
import 'header/data_grid_header.dart';
import 'header/loading_data_grid.dart';
import 'pagination_controls.dart';
import 'selection_mode.dart';

/// A Fluent UI-style DataGrid widget for displaying tabular data.
///
/// ## Selection Behavior
///
/// When data is updated (items added/removed/modified), the grid automatically
/// manages selection state:
///
/// - **Removed items**: Automatically removed from selection
/// - **Updated items**: Selection preserved when `itemIdentifier` is provided
/// - **Select All**: Correctly updates when data changes
///
/// ### Selection Preservation
///
/// For generated classes (e.g., Drift) or when object references change:
///
/// ```dart
/// DataGrid<Person>(
///   data: people,
///   itemIdentifier: (person) => person.id, // Preserve selection by ID
///   // ...
/// )
/// ```
///
/// Without `itemIdentifier`, only reference equality is used - selection
/// will be lost when objects are replaced with new instances.
class DataGrid<T> extends StatefulWidget {
  /// The data to display in the grid
  final List<T> data;

  /// Column definitions for the grid
  final List<DataGridColumn<T>> columns;

  /// Whether rows can be selected
  /// Selection mode for the DataGrid
  final SelectionMode selectionMode;

  /// Currently selected items
  final List<T> selectedItems;

  /// Callback when selection changes
  final ValueChanged<List<T>>? onSelectionChanged;

  /// Whether to show row numbers
  final bool showRowNumbers;

  /// Height of each row
  final double rowHeight;

  /// Maximum height of the grid
  final double? maxHeight;

  /// Whether to show alternating row colors
  final bool alternatingRowColors;

  /// Custom row builder
  final Widget Function(BuildContext context, T item, int index)? rowBuilder;

  /// Whether to enable pagination
  /// Number of items per page. If null, pagination is disabled.
  final int? itemsPerPage;

  /// Callback when the visible items change (due to pagination, filtering, or sorting)
  final ValueChanged<List<T>>? onViewChanged;

  /// Initial column filter values. These are only applied once when the widget is first created.
  ///
  /// The map uses column titles as keys and filter values as values. For example:
  /// ```dart
  /// initialColumnFilters: {
  ///   'Name': 'John',        // Text filter for Name column
  ///   'Department': 'Sales', // Dropdown filter for Department column
  ///   'Age': '25',           // Text filter for Age column
  /// }
  /// ```
  ///
  /// **Validation**: Invalid entries are handled as follows:
  /// - Column titles that don't exist: Assertion error in debug mode, ignored in release
  /// - Values for columns with `FilterType.none`: Assertion error in debug mode, ignored in release
  /// - Dropdown values not in the column's `filterOptions`: Assertion error in debug mode, ignored in release
  ///
  /// To programmatically control filters after initialization, use the filter UI or callbacks.
  /// Changes to this parameter after the widget is created will have no effect.
  final Map<String, String> initialColumnFilters;

  /// Callback when column filters change. Called whenever the user modifies any filter.
  ///
  /// The map contains the current filter values with column titles as keys. For example:
  /// ```dart
  /// onColumnFiltersChanged: (filters) {
  ///   print('Current filters: $filters');
  ///   // Example output: {'Name': 'John', 'Department': 'Sales'}
  /// },
  /// ```
  ///
  /// This is useful for persisting filter state or reacting to filter changes.
  final ValueChanged<Map<String, String>>? onColumnFiltersChanged;

  /// An optional ScrollController to control the grid's behavior in the
  /// vertical axis.
  final ScrollController? scrollController;

  /// Optional function to extract unique identifier for selection preservation.
  /// When provided, selection will be preserved across data updates even when
  /// object references change. Essential for generated classes (e.g., Drift)
  /// that implement equality based on all fields.
  ///
  /// Example: `(person) => person.id`
  ///
  /// Performance: Uses O(1) Map lookups when provided, O(n) reference
  /// equality when null. Only provide if you need selection preservation
  /// across object updates.
  final Object Function(T item)? itemIdentifier;

  const DataGrid({
    super.key,
    required this.data,
    required this.columns,
    this.selectionMode = SelectionMode.none,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.showRowNumbers = false,
    this.rowHeight = 40.0,
    this.maxHeight,
    this.alternatingRowColors = true,
    this.rowBuilder,
    this.itemsPerPage = 50,
    this.onViewChanged,
    this.initialColumnFilters = const {},
    this.onColumnFiltersChanged,
    this.scrollController,
    this.itemIdentifier,
  });

  /// Builds a DataGrid with a shimmering loading state.
  static Widget loading({
    required List<String> columns,
    int rowCount = 10,
    Key? key,
  }) {
    return LoadingDataGrid(columns: columns, rowCount: rowCount, key: key);
  }

  @override
  State<DataGrid<T>> createState() => _DataGridState<T>();
}

class _DataGridState<T> extends State<DataGrid<T>> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  Set<T> _selectedItems = <T>{};
  int? _sortColumnIndex;
  bool _sortAscending = true;

  // Internal pagination state
  int _currentPage = 0;

  // Helper getters for selection mode
  bool get _isSelectable => widget.selectionMode != SelectionMode.none;
  bool get _isMultiSelect => widget.selectionMode == SelectionMode.multi;
  bool get _isSingleSelect => widget.selectionMode == SelectionMode.single;

  // Helper getter for pagination
  bool get _isPaginationEnabled => widget.itemsPerPage != null;

  // Helper getter for filters
  bool get _hasFilters =>
      widget.columns.any((column) => column.filterType != FilterType.none);

  // Cache for calculated column widths
  final Map<String, double> _calculatedWidths = {};

  // Memoization for sorting
  List<T>? _cachedSortedData;
  int? _lastSortColumn;
  bool? _lastSortAscending;
  List<T>? _lastData;

  // Filtering state
  Map<String, String> _columnFilters = {};
  List<T>? _cachedFilteredData;
  Map<String, String>? _lastColumnFilters;
  List<T>? _lastDataForFiltering;

  // Debouncing
  Timer? _searchDebounceTimer;
  Timer? _filterDebounceTimer;

  // Memoized controllers
  final Map<String, TextEditingController> _columnFilterControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedItems = Set.from(widget.selectedItems);
    _columnFilters = _validateInitialFilters(widget.initialColumnFilters);
    // Notify initial view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyViewChanged();
    });
  }

  /// Validates initial column filters and removes invalid entries
  /// Uses assertions in debug mode to help developers catch issues
  Map<String, String> _validateInitialFilters(
    Map<String, String> initialFilters,
  ) {
    final validatedFilters = <String, String>{};

    for (final entry in initialFilters.entries) {
      final columnTitle = entry.key;
      final filterValue = entry.value;

      // Find the column by title
      final column = widget.columns.cast<DataGridColumn<T>?>().firstWhere(
        (col) => col!.title == columnTitle,
        orElse: () => null,
      );

      // Column doesn't exist - assertion in debug, skip in release
      assert(
        column != null,
        'DataGrid: Column "$columnTitle" not found in columns. '
        'Available columns: ${widget.columns.map((c) => c.title).join(", ")}',
      );
      if (column == null) continue;

      // Column is not filterable - assertion in debug, skip in release
      assert(
        column.filterType != FilterType.none,
        'DataGrid: Column "$columnTitle" is not filterable. '
        'Set filterType to a value other than FilterType.none to enable filtering.',
      );
      if (column.filterType == FilterType.none) continue;

      // For dropdown filters, validate the value is in the options
      assert(
        column.filterType != FilterType.dropdown ||
            column.filterOptions == null ||
            column.filterOptions!.contains(filterValue),
        'DataGrid: Filter value "$filterValue" for column "$columnTitle" '
        'is not in the available options: ${column.filterOptions?.join(", ") ?? "none"}',
      );

      // If the filter value is not in the options, skip it
      if (column.filterType == FilterType.dropdown &&
          column.filterOptions != null &&
          !column.filterOptions!.contains(filterValue)) {
        continue;
      }

      // Valid filter - add it
      validatedFilters[columnTitle] = filterValue;
    }

    return validatedFilters;
  }

  @override
  void didUpdateWidget(DataGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItems != oldWidget.selectedItems) {
      _selectedItems = Set.from(widget.selectedItems);
    }

    // Clear calculated widths if data changes
    if (widget.data != oldWidget.data) {
      _calculatedWidths.clear();

      // Clean up and preserve selected items when data changes
      _updateSelectionForDataChange(widget.data);
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _filterDebounceTimer?.cancel();
    _horizontalController.dispose();
    _verticalController.dispose();
    for (final controller in _columnFilterControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSelection(T item) {
    if (!_isSelectable) return;

    setState(() {
      if (_isMultiSelect) {
        if (_selectedItems.contains(item)) {
          _selectedItems.remove(item);
        } else {
          _selectedItems.add(item);
        }
      } else if (_isSingleSelect) {
        // Single selection: select only this item
        _selectedItems = {item};
      }
    });

    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  void _sortByColumn(int columnIndex) {
    final column = widget.columns[columnIndex];
    if (column.sortBy == null) return;

    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }

      // Don't clear cached data - let memoization work!
      // The _sortedData getter will handle cache invalidation based on actual changes

      // Reset to first page when sorting changes data
      _resetToFirstPageIfNeeded();
    });
    _notifyViewChanged();
  }

  List<T> get _sortedData {
    final filteredData = _filteredData;

    // Check if we can use cached result
    if (_cachedSortedData != null &&
        _lastSortColumn == _sortColumnIndex &&
        _lastSortAscending == _sortAscending &&
        _lastData == filteredData) {
      return _cachedSortedData!;
    }

    // If no sorting, return filtered data
    if (_sortColumnIndex == null) {
      _cachedSortedData = filteredData;
      _lastSortColumn = null;
      _lastSortAscending = null;
      _lastData = filteredData;
      return filteredData;
    }

    final column = widget.columns[_sortColumnIndex!];
    if (column.sortBy == null) {
      _cachedSortedData = filteredData;
      _lastSortColumn = _sortColumnIndex;
      _lastSortAscending = _sortAscending;
      _lastData = filteredData;
      return filteredData;
    }

    // Perform sorting and cache result
    final sorted = List<T>.from(filteredData);
    sorted.sort((a, b) {
      final result = column.sortBy!(a, b);
      return _sortAscending ? result : -result;
    });

    _cachedSortedData = sorted;
    _lastSortColumn = _sortColumnIndex;
    _lastSortAscending = _sortAscending;
    _lastData = filteredData;

    return sorted;
  }

  List<T> get _filteredData {
    // Check if we can use cached result
    if (_cachedFilteredData != null &&
        _lastColumnFilters == _columnFilters &&
        _lastDataForFiltering == widget.data) {
      return _cachedFilteredData!;
    }

    List<T> filtered = List<T>.from(widget.data);

    // Apply column-specific filters
    for (int i = 0; i < widget.columns.length; i++) {
      final column = widget.columns[i];
      final filterKey = column.title;
      final filterValue = _columnFilters[filterKey];

      if (column.filterType != FilterType.none &&
          filterValue != null &&
          filterValue.isNotEmpty) {
        filtered =
            filtered.where((item) {
              if (column.filterPredicate != null) {
                return column.filterPredicate!(item, filterValue);
              }

              // Default filtering logic (valueBuilder returns String)
              final value = column.valueBuilder(item);
              return value.toLowerCase().contains(filterValue.toLowerCase());
            }).toList();
      }
    }

    _cachedFilteredData = filtered;
    _lastColumnFilters = Map.from(_columnFilters);
    _lastDataForFiltering = widget.data;

    return filtered;
  }

  int get _totalPages {
    if (!_isPaginationEnabled) return 1;
    return (_sortedData.length / widget.itemsPerPage!).ceil();
  }

  bool get _allSelected {
    if (!_isMultiSelect || _sortedData.isEmpty) return false;
    return _selectedItems.length == _sortedData.length;
  }

  bool get _someSelected {
    if (!_isMultiSelect) return false;
    return _selectedItems.isNotEmpty && !_allSelected;
  }

  void _toggleSelectAll() {
    if (!_isMultiSelect) return;

    setState(() {
      if (_allSelected) {
        _selectedItems.clear();
      } else {
        _selectedItems = Set.from(_sortedData);
      }
    });

    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  void _onColumnFilterChanged(String columnTitle, String value) {
    setState(() {
      if (value.isEmpty) {
        _columnFilters.remove(columnTitle);
      } else {
        _columnFilters[columnTitle] = value;
      }
    });

    // Update controller text if it's different
    final controller = _getColumnFilterController(columnTitle);
    if (controller.text != value) {
      controller.text = value;
    }

    // Debounce the actual filtering
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        // Clear cached data when filters change
        _cachedFilteredData = null;
        _cachedSortedData = null;

        // Reset to first page when filtering changes data
        _resetToFirstPageIfNeeded();
      });
      widget.onColumnFiltersChanged?.call(Map.from(_columnFilters));
      _notifyViewChanged();
    });
  }

  TextEditingController _getColumnFilterController(String columnTitle) {
    if (!_columnFilterControllers.containsKey(columnTitle)) {
      _columnFilterControllers[columnTitle] = TextEditingController(
        text: _columnFilters[columnTitle] ?? '',
      );
    }
    return _columnFilterControllers[columnTitle]!;
  }

  void _clearAllFilters() {
    setState(() {
      _columnFilters.clear();
      for (final controller in _columnFilterControllers.values) {
        controller.clear();
      }
      _cachedFilteredData = null;
      _cachedSortedData = null;

      // Reset to first page when clearing filters
      _resetToFirstPageIfNeeded();
    });
    widget.onColumnFiltersChanged?.call({});
    _notifyViewChanged();
  }

  void _resetToFirstPageIfNeeded() {
    if (_isPaginationEnabled) {
      final totalPages = _totalPages;
      // Reset to first page if current page is beyond available pages
      if (totalPages == 0 || _currentPage >= totalPages) {
        setState(() {
          _currentPage = 0;
        });
        _notifyViewChanged();
      }
    }
  }

  void _notifyViewChanged() {
    widget.onViewChanged?.call(_getVisibleItems());
  }

  /// Updates selection when data changes, handling both item removal and updates.
  ///
  /// Uses itemIdentifier for O(1) lookups when provided, falls back to reference
  /// equality when null. Optimized for performance with early exits and efficient
  /// Map-based lookups.
  void _updateSelectionForDataChange(List<T> newData) {
    final previousSelectedItems = Set.from(_selectedItems);

    if (widget.itemIdentifier != null) {
      // Optimized ID-based selection preservation
      _updateSelectionWithIdentifier(newData);
    } else {
      // Fallback to reference equality (fast path)
      final newDataSet = Set.from(newData);
      _selectedItems.removeWhere((item) => !newDataSet.contains(item));
    }

    // Notify parent if selection changed due to data cleanup/updates
    if (previousSelectedItems.length != _selectedItems.length ||
        !previousSelectedItems.containsAll(_selectedItems)) {
      // Use post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectionChanged?.call(_selectedItems.toList());
      });
    }
  }

  /// Optimized ID-based selection update using O(1) Map lookups.
  void _updateSelectionWithIdentifier(List<T> newData) {
    final identifier = widget.itemIdentifier!;

    // Build ID -> item map for new data (single pass, O(n))
    final newDataById = <Object, T>{};
    for (final item in newData) {
      final id = identifier(item);
      newDataById[id] = item;
    }

    // Update selection using ID lookups (O(1) per selected item)
    final newSelection = <T>{};
    for (final selectedItem in _selectedItems) {
      final id = identifier(selectedItem);
      final matchingNewItem = newDataById[id];
      if (matchingNewItem != null) {
        // Item still exists (possibly updated), use the new reference
        newSelection.add(matchingNewItem);
      }
      // Items not in newDataById are automatically removed (cleanup)
    }

    _selectedItems = newSelection;
  }

  List<T> _getVisibleItems() {
    if (!_isPaginationEnabled) {
      return _sortedData;
    }

    final startIndex = _currentPage * widget.itemsPerPage!;
    final endIndex = (startIndex + widget.itemsPerPage!).clamp(
      0,
      _sortedData.length,
    );
    return _sortedData.sublist(startIndex, endIndex);
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _notifyViewChanged();
  }

  Widget _buildFilterControl(DataGridColumn<T> column) {
    final filterValue = _columnFilters[column.title] ?? '';
    if (column.filterBuilder != null) {
      return column.filterBuilder!(
        context,
        filterValue,
        (value) => _onColumnFilterChanged(column.title, value),
      );
    }
    switch (column.filterType) {
      case FilterType.dropdown:
        return DropdownColumnFilter<T>(
          column: column,
          filterValue: filterValue,
          onFilterChanged:
              (value) => _onColumnFilterChanged(column.title, value),
        );
      case FilterType.text:
      default:
        return TextColumnFilter<T>(
          column: column,
          controller: _getColumnFilterController(column.title),
          onFilterChanged:
              (value) => _onColumnFilterChanged(column.title, value),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border.all(
          color: theme.resources.cardStrokeColorDefault,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasFilters)
            FilterControls(
              isActive: _columnFilters.isNotEmpty,
              activeCount: _columnFilters.length,
              onClearAll: _clearAllFilters,
              children:
                  widget.columns
                      .where((column) => column.filterType != FilterType.none)
                      .map(_buildFilterControl)
                      .toList(),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(
                      constraints.maxWidth,
                      _calculateTotalWidth(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DataGridHeader<T>(
                          columns: widget.columns,
                          showRowNumbers: widget.showRowNumbers,
                          selectionMode: widget.selectionMode,
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          onSort: _sortByColumn,
                          horizontalController: _horizontalController,
                          allSelected: _allSelected,
                          someSelected: _someSelected,
                          onSelectAll: _isMultiSelect ? _toggleSelectAll : null,
                          getColumnWidth: getColumnWidth,
                        ),
                        Expanded(
                          child: DataGridContent<T>(
                            data: _sortedData,
                            columns: widget.columns,
                            showRowNumbers: widget.showRowNumbers,
                            selectionMode: widget.selectionMode,
                            alternatingRowColors: widget.alternatingRowColors,
                            rowHeight: widget.rowHeight,
                            currentPage: _currentPage,
                            itemsPerPage: widget.itemsPerPage,
                            enablePagination: _isPaginationEnabled,
                            selectedItems: _selectedItems,
                            onItemTap: _isSelectable ? _toggleSelection : null,
                            rowBuilder: widget.rowBuilder,
                            getColumnWidth: getColumnWidth,
                            scrollController: widget.scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isPaginationEnabled)
            PaginationControls(
              totalItems: _sortedData.length,
              totalPages: _totalPages,
              currentPage: _currentPage,
              itemsPerPage: widget.itemsPerPage!,
              onPageChanged: _onPageChanged,
            ),
        ],
      ),
    );
  }

  /// Calculates the auto-width for a column based on its content
  double _calculateColumnWidth(DataGridColumn<T> column) {
    if (column.width != null) {
      return column.width!;
    }

    // Check cache first
    if (_calculatedWidths.containsKey(column.title)) {
      return _calculatedWidths[column.title]!;
    }

    // Calculate width based on content
    double maxWidth = 0;
    final theme = FluentTheme.of(context);

    // Measure column title
    final titleText = TextPainter(
      text: TextSpan(text: column.title, style: theme.typography.caption),
      textDirection: TextDirection.ltr,
    );
    titleText.layout();
    maxWidth = titleText.width;

    if (column.sortBy != null) {
      // Also include header sort icon + spacing if sortable
      // (~14px icon + 4px gap)
      maxWidth += 18.0;
    }

    // Measure data values - optimize by only measuring the longest string
    if (widget.data.isNotEmpty) {
      // Get all values and sort by string length (descending)
      final values =
          widget.data.map((item) => column.valueBuilder(item)).toList()
            ..sort((a, b) => b.length.compareTo(a.length));

      // Only measure the longest string
      final longestValue = values.first;
      final valueText = TextPainter(
        text: TextSpan(text: longestValue, style: theme.typography.body),
        textDirection: TextDirection.ltr,
      );
      valueText.layout();
      maxWidth = math.max(maxWidth, valueText.width);
    }

    // Add padding (16px on each side)
    final calculatedWidth = maxWidth + 32;

    // Cache the result
    _calculatedWidths[column.title] = calculatedWidth;

    return calculatedWidth;
  }

  /// Gets the effective width for a column (either fixed or calculated)
  double getColumnWidth(DataGridColumn<T> column) {
    return _calculateColumnWidth(column);
  }

  double _calculateTotalWidth() {
    double totalWidth = 0;

    if (_isMultiSelect) {
      totalWidth += 40; // Checkbox column
    }

    if (widget.showRowNumbers) {
      totalWidth += 60; // Row numbers column
    }

    for (final column in widget.columns) {
      totalWidth += _calculateColumnWidth(column);
    }

    return totalWidth;
  }
}
