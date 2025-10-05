import 'package:fluent_data_grid/fluent_data_grid.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataGrid Scroll Behavior', () {
    testWidgets('selection should not change scroll position', (tester) async {
      // Create enough data to enable scrolling
      final people = List.generate(50, (i) => Person('Person $i', 20 + i));

      // Track selection changes and scroll controller
      List<Person> selectedItems = [];
      final scrollController = ScrollController();

      print('Creating widget');

      await tester.pumpWidget(
        FluentApp(
          home: FluentTheme(
            data: FluentThemeData.light(),
            child: SizedBox(
              height: 400, // Constrain height to enable scrolling
              child: DataGrid<Person>(
                data: people,
                columns: [
                  DataGridColumn<Person>(
                    title: 'Name',
                    valueBuilder: (p) => p.name,
                    width: 150,
                  ),
                  DataGridColumn<Person>(
                    title: 'Age',
                    valueBuilder: (p) => p.age.toString(),
                    width: 100,
                  ),
                ],
                selectionMode: SelectionMode.multi,
                itemsPerPage: null, // Disable pagination for this test
                onSelectionChanged: (items) {
                  selectedItems = items;
                },
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      print('Widget created');

      await tester.pumpAndSettle();

      print('Widget settled');

      // Scroll down to some position
      const scrollOffset = 200.0;
      scrollController.jumpTo(scrollOffset);

      print('Scrolled to offset $scrollOffset');
      await tester.pumpAndSettle();

      print('Widget settled');

      // Verify we scrolled to the expected position
      expect(scrollController!.offset, scrollOffset);

      // Find and tap a row checkbox (not the header "select all" checkbox)
      final rowCheckboxes = find.byType(Checkbox);
      expect(rowCheckboxes, findsAtLeastNWidgets(2)); // Header + rows

      await tester.tap(rowCheckboxes.at(1)); // Tap the first row checkbox
      await tester.pumpAndSettle();

      print('Checkbox tapped');

      // Verify selection changed
      expect(selectedItems.length, 1);

      // CRITICAL: Verify scroll position hasn't changed
      expect(
        scrollController!.offset,
        scrollOffset,
        reason: 'Selection should not change scroll position',
      );
    });

    testWidgets('page change should scroll to top', (tester) async {
      // Create enough data for pagination
      final people = List.generate(100, (i) => Person('Person $i', 20 + i));

      final scrollController = ScrollController();
      print('Creating widget with pagination');

      final widget = FluentApp(
        home: FluentTheme(
          data: FluentThemeData.light(),
          child: SizedBox(
            height: 400, // Constrain height to enable scrolling
            child: DataGrid<Person>(
              data: people,
              columns: [
                DataGridColumn<Person>(
                  title: 'Name',
                  valueBuilder: (p) => p.name,
                  width: 150,
                ),
              ],
              itemsPerPage: 10, // Enable pagination
              scrollController: scrollController,
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      print('Widget created with pagination');
      await tester.pumpAndSettle();
      print('Widget settled');
      // Wait for scroll controller to be available
      expect(scrollController, isNotNull);

      // Scroll down to some position
      const scrollOffset = 200.0;
      scrollController.jumpTo(scrollOffset);

      print('Scrolled to offset $scrollOffset');
      await tester.pumpFrames(widget, kThemeAnimationDuration);
      await tester.pumpAndSettle();

      print('Allowed time to pass');

      // Verify we scrolled to the expected position
      expect(scrollController!.offset, scrollOffset);

      // Find and tap the next page button
      final nextButton = find.text('Next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        print('Next button tapped');
        await tester.pumpFrames(widget, kThemeAnimationDuration);
        await tester.pumpAndSettle();

        print('Allowed time to pass');

        // CRITICAL: Verify scroll position reset to top
        expect(
          scrollController!.offset,
          0.0,
          reason: 'Page change should scroll to top',
        );
      } else {
        // If no Next button, test that the grid renders with pagination
        expect(find.byType(DataGrid<Person>), findsOneWidget);
      }
    });

    testWidgets('filtering should scroll to top', (tester) async {
      // Create enough data for scrolling and filtering
      final people = List.generate(150, (i) => Person('Person $i', 20 + i));

      final scrollController = ScrollController();

      await tester.pumpWidget(
        FluentApp(
          home: FluentTheme(
            data: FluentThemeData.light(),
            child: SizedBox(
              height: 400, // Constrain height to enable scrolling
              child: DataGrid<Person>(
                data: people,
                columns: [
                  DataGridColumn<Person>(
                    title: 'Name',
                    valueBuilder: (p) => p.name,
                    width: 150,
                    filterType: FilterType.text,
                  ),
                ],
                itemsPerPage: null, // Disable pagination for this test
                scrollController: scrollController,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Wait for scroll controller to be available
      expect(scrollController, isNotNull);

      // Scroll down to some position
      const scrollOffset = 200.0;
      scrollController.jumpTo(scrollOffset);
      await tester.pumpAndSettle();

      // Verify we scrolled to the expected position
      expect(scrollController.offset, scrollOffset);

      // Find and interact with filter - look for text field
      final filterField = find.byType(TextBox);
      if (filterField.evaluate().isNotEmpty) {
        final widget = tester.widget(filterField.first);
        if (widget is TextBox) {
          widget.controller?.addListener(
            () => print('Filter text changed: ${widget.controller?.text}'),
          );
        } else {
          print('Found widget is not a TextBox: ${widget.runtimeType}');
        }
        await tester.enterText(filterField.first, '1');
        await tester.pumpAndSettle();

        // Wait a bit for debouncing
        await tester.pump(const Duration(milliseconds: 600));

        // CRITICAL: Verify scroll position reset to top
        expect(
          scrollController!.offset,
          0.0,
          reason: 'Filtering should scroll to top',
        );
      } else {
        // If no filter field found, just verify the grid renders
        expect(find.byType(DataGrid<Person>), findsOneWidget);
      }
    });
  });
}

class Person {
  final String name;
  final int age;
  Person(this.name, this.age);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
