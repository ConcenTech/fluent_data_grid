# Copilot Instructions for fluent_data_grid

## Project Overview
This is a Flutter package that provides a Fluent UI-style DataGrid widget for all Flutter-supported platforms. While primarily tested on Windows/macOS, it uses no platform-specific code and should work across all platforms supported by `fluent_ui`. The package follows a clean architecture with internal state management for filtering, sorting, and pagination.

## Architecture & Key Components

### Core Structure
- **Main API**: `lib/fluent_data_grid.dart` - The single public export file
- **Internal Implementation**: `lib/src/` - All implementation details are private
- **Generic Design**: The entire grid is generic `<T>` for type-safe data handling

### Component Hierarchy
```
DataGrid<T> (main widget)
├── DataGridHeader<T> (column headers with sort indicators)
├── FilterControls (collapsible filter panel using Expander)
├── DataGridContent<T> (scrollable table body)
│   └── DataGridRow<T> (individual rows)
│       └── DataGridCell<T> (individual cells)
└── PaginationControls (page navigation)
```

### Data Flow Pipeline
The grid processes data in this exact order: **filter → sort → paginate**. This is critical for understanding behavior:
- Filters are applied to raw data first
- Sorting operates on filtered results
- Pagination shows pages of the filtered+sorted dataset
- All counts (items, pages) reflect the filtered state

## Development Patterns

### Column Configuration
Use `DataGridColumn<T>` for type-safe column definitions:
```dart
DataGridColumn<Person>(
  title: 'Name',
  valueBuilder: (p) => p.name,           // Required: extract display value
  sortBy: (a, b) => a.name.compareTo(b.name), // Optional: enable sorting
  filterType: FilterType.text,           // Optional: enable filtering
  width: 180,                           // Prefer fixed widths for performance
)
```

### Selection Modes
- `SelectionMode.none` - No selection
- `SelectionMode.single` - Click-to-select with highlighting
- `SelectionMode.multi` - Checkboxes with "select all" functionality

### Filter Types
- `FilterType.text` - Case-insensitive substring matching
- `FilterType.dropdown` - Fixed options via `filterOptions`
- `FilterType.none` - No filtering (default)
- Custom filtering via `filterPredicate` override

## Testing & Development

### Testing Requirements
- **All new features must include tests**
- **Changed code must ensure existing tests still pass**
- **Add tests for previously uncovered code when modifying**
- Thorough testing of the existing codebase is planned/ongoing

### Running the Example
```bash
cd example
flutter run -d macos  # or -d windows, or any supported platform
```

### Running Tests
```bash
flutter test  # Run all package tests
```

### Package Structure
- Keep public API minimal in `lib/fluent_data_grid.dart`
- All implementation goes in `lib/src/`
- Use relative imports within `src/`
- Follow the existing `analysis_options.yaml` linting rules

### Performance Considerations
- Fixed column widths are preferred over auto-width
- Large datasets should be pre-filtered before passing to the grid
- The grid is client-side only - no built-in data source abstraction

## Common Patterns

### State Management
The grid manages its own internal state for:
- Current sort column and direction
- Active filters per column
- Selected items (with callbacks to parent)
- Current pagination state

### Callbacks
- `onSelectionChanged` - Emitted when user changes selection
- `onViewChanged` - Emitted when visible items change (useful for debugging)
- `onColumnFiltersChanged` - Emitted when filters change (for persistence)

### Initialization
Use `initialColumnFilters` to set default filters on first load only. These values are validated against column configuration in debug mode.

## Limitations & Constraints
- Single-column sorting only (no multi-column)
- Client-side processing only
- Basic keyboard navigation
- Primarily tested on Windows/macOS (though should work on all Flutter platforms)

## File Organization Tips
- **New components**: Add to `lib/src/` with appropriate subfolder
- **Filters**: Extend existing pattern in `lib/src/filter/`
- **Headers**: Header-related components go in `lib/src/header/`
- **Public exports**: Only add to main library file if part of public API