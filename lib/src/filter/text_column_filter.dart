import 'package:fluent_ui/fluent_ui.dart';

import '../data_grid_column.dart';

class TextColumnFilter<T> extends StatelessWidget {
  const TextColumnFilter({
    super.key,
    required this.column,
    required this.controller,
    required this.onFilterChanged,
  });

  final DataGridColumn<T> column;
  final TextEditingController controller;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: column.width?.clamp(120, 200) ?? 200,
      child: TextBox(
        placeholder: 'Filter ${column.title}',
        controller: controller,
        onChanged: onFilterChanged,
        suffix:
            controller.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: () {
                    controller.clear();
                    onFilterChanged('');
                  },
                )
                : null,
      ),
    );
  }
}
