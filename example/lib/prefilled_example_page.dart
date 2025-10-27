import 'package:fluent_data_grid/fluent_data_grid.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  late List<Person> _people;

  final departments = [
    'Engineering',
    'Marketing',
    'Sales',
    'HR',
    'Finance',
    'Operations',
  ];

  @override
  void initState() {
    super.initState();

    _people = List.generate(
      400,
      (i) => Person(
        'User $i really long name',
        'user$i@example.com',
        20 + (i % 30),
        departments[i % departments.length],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        header: const PageHeader(title: Text('fluent_data_grid example')),
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DataGrid<Person>(
                data: _people,
                columns: [
                  DataGridColumn<Person>(
                    title: 'Name',
                    // width: 180, // Auto-width based on content
                    valueBuilder: (p) => p.name,
                    sortBy: (a, b) => a.name.compareTo(b.name),
                    filterType: FilterType.text,
                  ),
                  DataGridColumn<Person>(
                    title: 'Email',
                    // width: 240, // Auto-width based on content
                    valueBuilder: (p) => p.email,
                    sortBy: (a, b) => a.email.compareTo(b.email),
                    filterType: FilterType.text,
                  ),
                  DataGridColumn<Person>(
                    title: 'Age',
                    width: 80, // Fixed width for numbers
                    valueBuilder: (p) => p.age.toString(),
                    sortBy: (a, b) => a.age.compareTo(b.age),
                    textAlign: TextAlign.center,
                    filterType: FilterType.text,
                  ),
                ],
                selectionMode: SelectionMode.multi,

                itemsPerPage: 50,
                onViewChanged: (items) {
                  print('Visible items: ${items.length}');
                },
                // To disable pagination, set itemsPerPage to null:
                // itemsPerPage: null,
                showRowNumbers: true,
                alternatingRowColors: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Person {
  final String name;
  final String email;
  final String department;
  final int age;
  Person(this.name, this.email, this.age, this.department);
}
