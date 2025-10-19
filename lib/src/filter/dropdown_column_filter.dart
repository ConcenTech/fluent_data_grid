import 'package:fluent_ui/fluent_ui.dart';

import '../data_grid_column.dart';

class DropdownColumnFilter<T> extends StatelessWidget {
  const DropdownColumnFilter({
    super.key,
    required this.column,
    required this.filterValue,
    required this.onFilterChanged,
  });

  final DataGridColumn<T> column;
  final String filterValue;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ComboBox<String>(
          placeholder: Text(column.title),
          value: filterValue.isEmpty ? null : filterValue,
          items: [
            // Add clear option at the top
            if (filterValue.isNotEmpty)
              ComboBoxItem(
                value: '',
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color:
                        FluentTheme.of(
                          context,
                        ).resources.textFillColorSecondary,
                    // fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Add separator

            // Add actual filter options
            ...column.filterOptions
                    ?.map(
                      (option) =>
                          ComboBoxItem(value: option, child: Text(option)),
                    )
                    .toList() ??
                [],
          ],
          onChanged: (value) {
            onFilterChanged(value ?? '');
          },
        ),
      ],
    );
  }
}
