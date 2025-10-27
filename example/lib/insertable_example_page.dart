import 'dart:math';

import 'package:fluent_data_grid/fluent_data_grid.dart';
import 'package:fluent_ui/fluent_ui.dart';

class InsertablExamplePage extends StatefulWidget {
  const InsertablExamplePage({super.key});

  @override
  State<InsertablExamplePage> createState() => _InsertablExamplePageState();
}

class _InsertablExamplePageState extends State<InsertablExamplePage> {
  List<(String, String)> items = [];

  void _add() {
    final random = Random();
    final item = _availableItems[random.nextInt(_availableItems.length)];
    setState(() {
      items.add(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: PageHeader(
          title: Text('Insertable Example'),
          commandBar: IconButton(
            icon: Icon(FluentIcons.add),
            onPressed: () => _add(),
          ),
        ),
        content: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DataGrid<(String, String)>(
              data: items,
              columns: [
                DataGridColumn(title: 'Item', valueBuilder: (item) => item.$1),
                DataGridColumn(
                  title: 'Description',
                  valueBuilder: (item) => item.$2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _availableItems = [
  ('Item 1', 'Item 1 description'),
  ('Item 2', 'Item 2 description'),
  ('Item 3', 'Item 3 description'),
  ('Item 4', 'Item 4 description'),
  ('Item 5', 'Item 5 description'),
];
