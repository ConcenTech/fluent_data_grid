import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';

import 'data_grid_column.dart';
import 'data_grid_row.dart';
import 'selection_mode.dart';

class DataGridContent<T> extends StatefulWidget {
  const DataGridContent({
    super.key,
    required this.data,
    required this.columns,
    required this.showRowNumbers,
    required this.selectionMode,
    required this.alternatingRowColors,
    required this.rowHeight,
    required this.currentPage,
    required this.itemsPerPage,
    required this.enablePagination,
    required this.selectedItems,
    required this.onItemTap,
    this.rowBuilder,
    this.getColumnWidth,
    this.scrollController,
  });

  final List<T> data;
  final List<DataGridColumn<T>> columns;
  final bool showRowNumbers;
  final SelectionMode selectionMode;
  final bool alternatingRowColors;
  final double rowHeight;
  final int currentPage;
  final int? itemsPerPage;
  final bool enablePagination;
  final Set<T> selectedItems;
  final ValueChanged<T>? onItemTap;
  final Widget Function(BuildContext context, T item, int index)? rowBuilder;
  final double Function(DataGridColumn<T> column)? getColumnWidth;
  final ScrollController? scrollController;

  @override
  State<DataGridContent<T>> createState() => _DataGridContentState<T>();
}

class _DataGridContentState<T> extends State<DataGridContent<T>> {
  late ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _verticalController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(DataGridContent<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only scroll to top when page changes or data length changes (filtering)
    // Don't scroll when just selection changes (data object reference changes but length stays same)
    final shouldScrollToTop =
        widget.currentPage != oldWidget.currentPage ||
        widget.data.length != oldWidget.data.length;

    if (shouldScrollToTop && _verticalController.hasClients) {
      _verticalController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      // Only dispose if we created the controller
      _verticalController.dispose();
    }
    super.dispose();
  }

  List<T> get _paginatedData {
    if (!widget.enablePagination) {
      return widget.data;
    }

    // Safety check: ensure currentPage is within bounds
    final totalPages = (widget.data.length / widget.itemsPerPage!).ceil();
    final safeCurrentPage = widget.currentPage.clamp(0, max(0, totalPages - 1));

    final startIndex = (safeCurrentPage * widget.itemsPerPage!).toInt();
    final endIndex =
        (startIndex + widget.itemsPerPage!)
            .clamp(0, widget.data.length)
            .toInt();

    // Additional safety check for empty data
    if (widget.data.isEmpty || startIndex >= widget.data.length) {
      return <T>[];
    }

    return widget.data.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _verticalController,
      itemCount: _paginatedData.length,
      itemBuilder: (context, index) {
        final item = _paginatedData[index];
        final globalIndex =
            widget.enablePagination
                ? (widget.currentPage * widget.itemsPerPage!) + index
                : index;

        return DataGridRow<T>(
          item: item,
          index: globalIndex,
          columns: widget.columns,
          showRowNumbers: widget.showRowNumbers,
          isSelected: widget.selectedItems.contains(item),
          isAlternating: widget.alternatingRowColors && index % 2 == 1,
          selectionMode: widget.selectionMode,
          rowHeight: widget.rowHeight,
          onTap:
              widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
          rowBuilder: widget.rowBuilder,
          getColumnWidth: widget.getColumnWidth,
        );
      },
    );
  }
}
