import 'package:fluent_data_grid/fluent_data_grid.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataGrid Selection State Management', () {
    testWidgets('select all updates correctly when items are removed', (
      tester,
    ) async {
      // Create test data
      var people = [Person('Alice', 1), Person('Bob', 2), Person('Charlie', 3)];

      // Track selection changes
      List<Person> selectedItems = [];

      // Create a StatefulWidget to manage the data
      await tester.pumpWidget(
        FluentApp(
          home: StatefulBuilder(
            builder:
                (context, setState) => FluentTheme(
                  data: FluentThemeData.light(),
                  child: Column(
                    children: [
                      // Button to remove selected items (simulate real app behavior)
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            people =
                                people
                                    .where((p) => !selectedItems.contains(p))
                                    .toList();
                          });
                        },
                        child: const Text('Remove Selected'),
                      ),
                      Expanded(
                        child: DataGrid<Person>(
                          data: people,
                          columns: [
                            DataGridColumn<Person>(
                              title: 'Name',
                              valueBuilder: (p) => p.name,
                              width: 150,
                            ),
                            DataGridColumn<Person>(
                              title: 'ID',
                              valueBuilder: (p) => p.id.toString(),
                              width: 100,
                            ),
                          ],
                          selectionMode: SelectionMode.multi,
                          onSelectionChanged: (items) {
                            selectedItems = items;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select all items
      final selectAllCheckbox = find.byType(Checkbox).first;
      await tester.tap(selectAllCheckbox);
      await tester.pumpAndSettle();

      // Verify all items are selected
      expect(selectedItems.length, 3);

      // Verify select all checkbox is checked
      final Checkbox selectAllWidget = tester.widget(selectAllCheckbox);
      expect(selectAllWidget.checked, true);

      // Remove selected items
      final removeButton = find.text('Remove Selected');
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Verify no items remain
      expect(people.length, 0);

      // Verify selection was cleared
      expect(selectedItems.length, 0);

      // Verify select all checkbox is now unchecked
      final Checkbox updatedSelectAllWidget = tester.widget(selectAllCheckbox);
      expect(updatedSelectAllWidget.checked, false);
    });

    testWidgets('selection preserves across item updates with itemIdentifier', (
      tester,
    ) async {
      // Create test data
      var people = [Person('Alice', 1), Person('Bob', 2), Person('Charlie', 3)];

      // Track selection changes
      List<Person> selectedItems = [];

      // Create a StatefulWidget to manage the data
      await tester.pumpWidget(
        FluentApp(
          home: StatefulBuilder(
            builder:
                (context, setState) => FluentTheme(
                  data: FluentThemeData.light(),
                  child: Column(
                    children: [
                      // Button to update Alice's name (new object reference)
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            final index = people.indexWhere((p) => p.id == 1);
                            if (index != -1) {
                              // Create new Person object with same ID but different name
                              people[index] = Person('Alice Updated', 1);
                            }
                          });
                        },
                        child: const Text('Update Alice'),
                      ),
                      Expanded(
                        child: DataGrid<Person>(
                          data: people,
                          columns: [
                            DataGridColumn<Person>(
                              title: 'Name',
                              valueBuilder: (p) => p.name,
                              width: 150,
                            ),
                            DataGridColumn<Person>(
                              title: 'ID',
                              valueBuilder: (p) => p.id.toString(),
                              width: 100,
                            ),
                          ],
                          selectionMode: SelectionMode.multi,
                          itemIdentifier:
                              (p) => p.id, // Preserve selection by ID
                          onSelectionChanged: (items) {
                            selectedItems = items;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Alice (first row checkbox)
      final rowCheckboxes = find.byType(Checkbox);
      expect(rowCheckboxes, findsAtLeastNWidgets(2)); // Header + rows

      await tester.tap(rowCheckboxes.at(1)); // First row checkbox
      await tester.pumpAndSettle();

      // Verify Alice is selected
      expect(selectedItems.length, 1);
      expect(selectedItems.first.name, 'Alice');
      expect(selectedItems.first.id, 1);

      // Update Alice's name (creates new object reference)
      final updateButton = find.text('Update Alice');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify Alice is still selected despite object reference change
      expect(selectedItems.length, 1);
      expect(selectedItems.first.name, 'Alice Updated'); // New name
      expect(selectedItems.first.id, 1); // Same ID

      // Verify the checkbox is still checked
      final firstRowCheckbox = rowCheckboxes.at(1);
      final Checkbox checkboxWidget = tester.widget(firstRowCheckbox);
      expect(checkboxWidget.checked, true);
    });

    testWidgets('selection breaks across updates without itemIdentifier', (
      tester,
    ) async {
      // Create test data using PersonWithoutEquality (no custom == or hashCode)
      var people = [
        PersonWithoutEquality('Alice', 1),
        PersonWithoutEquality('Bob', 2),
      ];

      // Track selection changes
      List<PersonWithoutEquality> selectedItems = [];

      // Create a StatefulWidget to manage the data
      await tester.pumpWidget(
        FluentApp(
          home: StatefulBuilder(
            builder:
                (context, setState) => FluentTheme(
                  data: FluentThemeData.light(),
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            final index = people.indexWhere((p) => p.id == 1);
                            if (index != -1) {
                              people[index] = PersonWithoutEquality(
                                'Alice Updated',
                                1,
                              );
                            }
                          });
                        },
                        child: const Text('Update Alice'),
                      ),
                      Expanded(
                        child: DataGrid<PersonWithoutEquality>(
                          data: people,
                          columns: [
                            DataGridColumn<PersonWithoutEquality>(
                              title: 'Name',
                              valueBuilder: (p) => p.name,
                              width: 150,
                            ),
                          ],
                          selectionMode: SelectionMode.multi,
                          // No itemIdentifier - uses reference equality only
                          onSelectionChanged: (items) {
                            selectedItems = items;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select Alice
      final rowCheckboxes = find.byType(Checkbox);
      await tester.tap(rowCheckboxes.at(1));
      await tester.pumpAndSettle();

      // Verify Alice is selected
      expect(selectedItems.length, 1);

      // Update Alice (new object reference)
      final updateButton = find.text('Update Alice');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify selection was lost due to object reference change
      expect(selectedItems.length, 0);
    });
  });
}

class Person {
  final String name;
  final int id;

  Person(this.name, this.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Person{name: $name, id: $id}';
}

/// Person class without custom == and hashCode (uses Object's default implementation)
class PersonWithoutEquality {
  final String name;
  final int id;

  PersonWithoutEquality(this.name, this.id);

  @override
  String toString() => 'PersonWithoutEquality{name: $name, id: $id}';
}
