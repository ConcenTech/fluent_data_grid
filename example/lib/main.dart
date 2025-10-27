import 'package:fluent_ui/fluent_ui.dart';
import 'insertable_example_page.dart';

void main() {
  runApp(
    FluentApp(
      theme: FluentThemeData.light(),
      darkTheme: FluentThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: InsertablExamplePage(),
    ),
  );
}
