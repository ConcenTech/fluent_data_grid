# fluent_data_grid

A Fluent UI-style DataGrid for Flutter desktop (Windows and macOS) built on top of `fluent_ui`.

## What it provides

- Sorting (single-column) with visual indicators
- Row selection (single and multi-select)
- Pagination (page size, current page, and callbacks)
- Column filters (text and dropdown)
- Collapsible filter panel (using Expander)
- Row numbering, alternating row colors, horizontal/vertical scrolling

## Getting started

1) Add the package to your Flutter project. For local development, use a path dependency in your app's `pubspec.yaml` pointing to this package folder.

2) Import the library and use the exported types in your UI. You will typically:

- Provide a list of data items
- Declare a list of columns (one per field you want to display), each defining how to extract values and (optionally) how to sort and filter
- Opt-in to features like selection, pagination, filters, and visual options (row numbers, alternating colors)

3) Wire callbacks for:

- Page changes (to keep `currentPage` in sync)
- Selection changes (to reflect changes in app state)
- Filter changes (if you need to persist or observe filter state externally)

## Concepts & configuration

- Data: The grid displays a list of items (`List<T>`). The grid internally applies filtering, then sorting, then pagination in that order.

- Columns: Each column defines:
  - A title and width
  - A `valueBuilder` to extract the value from a row item
  - Optional `sortBy` comparator
  - Optional filtering config (text or dropdown) and an optional `filterPredicate` for custom matching

- Selection: Opt-in via `selectable`. For multi-select, enable `multiSelect`. The grid will track selected items and emit changes via `onSelectionChanged`.

- Pagination: Enable via `enablePagination` and configure `itemsPerPage`, `currentPage`, and `onPageChanged`. The grid shows item counts and page counts derived from the filtered dataset.

- Filtering:
  - Column filters can be enabled via `showColumnFilters`
  - Each column can be filterable (`filterable: true`)
  - Dropdown filters accept a fixed set of options
  - Text filters perform case-insensitive substring matches by default, and can be overridden with a custom predicate
  - The filter panel is collapsible and starts collapsed

- Visuals: Optional row numbering, alternating row colors, and a Fluent-styled header with sort indicators. Horizontal scrolling is supported for wide sets of columns.

## Behavior details

- Ordering of operations: filter → sort → paginate
- Counts shown (items and pages) are based on the filtered set
- "Select all" applies to the filtered rows currently in view, not the entire unfiltered dataset
- Sorting applies to the full filtered set (not just the current page)

## Accessibility & keyboard

- Uses `fluent_ui` controls for consistency with Windows Fluent design
- The filter panel uses an Expander to expose a11y/keyboard expectations

## Best practices

- Keep `itemsPerPage` aligned with your layout height to minimize partial pages
- Use deterministic comparators for sorting
- For large datasets, consider applying coarse filtering in your data layer before passing to the grid
- Keep column widths explicit for predictable horizontal layouts

## Limitations

- Single-column sorting (multi-column sorting is not yet implemented)
- Client-side only (no built-in data source abstraction)
- Focus management and advanced keyboard navigation are basic; enhancements may be added later

## Versioning & stability

- This is an evolving local package intended for internal use
- API may change until a stable release is tagged

## Contributing

- Keep the public API small and documented
- Maintain a clean separation between public exports (`lib/fluent_data_grid.dart`) and internals (`lib/src/...`)
- Add small, focused examples to the `example` app for new features

## License

- Licensed under the BSD-3 License. See the LICENSE file for details.
