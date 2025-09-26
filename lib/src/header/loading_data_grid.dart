import 'package:fluent_ui/fluent_ui.dart';

import '../data_grid.dart';
import '../data_grid_column.dart';

class LoadingDataGrid extends StatefulWidget {
  final List<String> columns;

  final int rowCount;

  const LoadingDataGrid({super.key, required this.columns, this.rowCount = 10});

  @override
  State<LoadingDataGrid> createState() => _LoadingDataGridSate();
}

class _LoadingDataGridSate extends State<LoadingDataGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DataGrid<String>(
      data: List.filled(widget.rowCount, ''),
      columns:
          widget.columns
              .map(
                (e) => DataGridColumn<String>(
                  title: e,
                  valueBuilder: (data) => data,
                  width: 200,
                  cellBuilder:
                      (_, _, _) => ShimmerBox(
                        height: 20,
                        width: 200,
                        animation: _animation,
                      ),
                ),
              )
              .toList(),
      // Disable pagination
      itemsPerPage: null,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    required this.animation,
  });
  final double height;
  final double width;

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final boxWidth = width + (width * 0.3);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: FluentTheme.of(context).cardColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Shimmer highlight that moves from left to right
              Positioned(
                left:
                    boxWidth * animation.value -
                    boxWidth * 0.3, // Moves from left to right
                right:
                    boxWidth * (1 - animation.value) -
                    boxWidth * 0.3, // Ensures it exits on the right
                top: 0,
                bottom: 0,
                child: Container(
                  width: width * 0.3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        FluentTheme.of(
                          context,
                        ).scaffoldBackgroundColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
