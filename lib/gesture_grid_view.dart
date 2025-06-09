import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GestureGridView extends StatefulWidget {
  final EdgeInsets? padding;
  final int minAxisCount;
  final int maxAxisCount;
  final int? initialAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration animationDuration;
  final Curve animationCurve;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  final void Function(int newAxisCount)? onAxisChanged;

  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final DragStartBehavior dragStartBehavior;
  final Clip clipBehavior;
  final String? restorationId;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const GestureGridView({
    super.key,
    this.padding,
    this.minAxisCount = 1,
    this.maxAxisCount = 4,
    this.initialAxisCount,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 4.0,
    this.crossAxisSpacing = 4.0,
    required this.itemCount,
    required this.itemBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOutCubic,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.onAxisChanged,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  @override
  State<GestureGridView> createState() => _GestureGridViewState();
}

class _GestureGridViewState extends State<GestureGridView>
    with TickerProviderStateMixin {
  late int _currentColumns;
  late AnimationController _animationController;
  late Animation<double> _animation;

  double _baseScale = 1.0;
  double _currentScale = 1.0;
  bool _isScaling = false;
  bool _isAnimating = false;

  // アニメーション用の列数
  int _fromColumns = 4;
  int _toColumns = 4;

  @override
  void initState() {
    super.initState();
    if (widget.minAxisCount <= 0) {
      throw ArgumentError(
          'minAxisCount must be greater than 0. Got: ${widget.minAxisCount}');
    }
    if (widget.maxAxisCount <= 0) {
      throw ArgumentError(
          'maxAxisCount must be greater than 0. Got: ${widget.maxAxisCount}');
    }
    if (widget.minAxisCount > widget.maxAxisCount) {
      throw ArgumentError(
          'minAxisCount (${widget.minAxisCount}) must be less than or equal to maxAxisCount (${widget.maxAxisCount})');
    }
    if (widget.initialAxisCount != null) {
      if (widget.initialAxisCount! < widget.minAxisCount) {
        throw ArgumentError(
            'initialAxisCount (${widget.initialAxisCount}) must be greater than or equal to minAxisCount (${widget.minAxisCount})');
      }
      if (widget.initialAxisCount! > widget.maxAxisCount) {
        throw ArgumentError(
            'initialAxisCount (${widget.initialAxisCount}) must be less than or equal to maxAxisCount (${widget.maxAxisCount})');
      }
    }

    // 初期列数の設定
    _currentColumns = widget.initialAxisCount ?? widget.maxAxisCount;
    _fromColumns = _currentColumns;
    _toColumns = _currentColumns;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_isAnimating) return;
    _baseScale = _currentScale;
    _isScaling = true;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isScaling || details.pointerCount < 2 || _isAnimating) return;

    _currentScale = _baseScale * details.scale;

    int targetColumns = _calculateColumnsFromScale(_currentScale);

    if (targetColumns != _currentColumns) {
      _animateToColumns(targetColumns);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
    _currentScale = 1.0;
    _baseScale = 1.0;
  }

  int _calculateColumnsFromScale(double scale) {
    if (scale > 1.2) {
      int targetColumns = _currentColumns - 1;
      return targetColumns.clamp(widget.minAxisCount, widget.maxAxisCount);
    } else if (scale < 0.8) {
      int targetColumns = _currentColumns + 1;
      return targetColumns.clamp(widget.minAxisCount, widget.maxAxisCount);
    }
    return _currentColumns;
  }

  void _animateToColumns(int newColumns) {
    if (newColumns == _currentColumns || _isAnimating) return;

    widget.onAxisChanged?.call(newColumns);

    setState(() {
      _isAnimating = true;
      _fromColumns = _currentColumns;
      _toColumns = newColumns;
      _currentColumns = newColumns;
    });

    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
        _fromColumns = _toColumns;
      });
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: _isAnimating ? _buildAnimatedGrid() : _buildStaticGrid(),
    );
  }

  Widget _buildStaticGrid() {
    return GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      primary: widget.primary,
      dragStartBehavior: widget.dragStartBehavior,
      clipBehavior: widget.clipBehavior,
      restorationId: widget.restorationId,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _currentColumns,
        childAspectRatio: widget.childAspectRatio,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
      ),
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }

  Widget _buildAnimatedGrid() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _CustomAnimatedGrid(
          animation: _animation,
          fromColumns: _fromColumns,
          toColumns: _toColumns,
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
          padding: widget.padding ?? EdgeInsets.zero,
          childAspectRatio: widget.childAspectRatio,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
        );
      },
    );
  }
}

class _CustomAnimatedGrid extends StatelessWidget {
  final Animation<double> animation;
  final int fromColumns;
  final int toColumns;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets padding;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const _CustomAnimatedGrid({
    required this.animation,
    required this.fromColumns,
    required this.toColumns,
    required this.itemCount,
    required this.itemBuilder,
    required this.padding,
    required this.childAspectRatio,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final contentWidth = screenWidth - padding.left - padding.right;

        return Stack(
          children: List.generate(itemCount, (index) {
            final fromPos =
                _calculateItemPosition(index, fromColumns, contentWidth);
            final toPos =
                _calculateItemPosition(index, toColumns, contentWidth);

            final currentPos = Rect.lerp(fromPos, toPos, animation.value)!;

            return AnimatedPositioned(
              duration: Duration.zero, // アニメーションはanimation.valueで制御
              left: currentPos.left + padding.left,
              top: currentPos.top + padding.top,
              width: currentPos.width,
              height: currentPos.height,
              child: itemBuilder(context, index),
            );
          }),
        );
      },
    );
  }

  Rect _calculateItemPosition(int index, int columns, double contentWidth) {
    final totalSpacing = crossAxisSpacing * (columns - 1);
    final itemWidth = (contentWidth - totalSpacing) / columns;
    final itemHeight = itemWidth / childAspectRatio;

    final row = index ~/ columns;
    final col = index % columns;

    final x = col * (itemWidth + crossAxisSpacing);
    final y = row * (itemHeight + mainAxisSpacing);

    return Rect.fromLTWH(x, y, itemWidth, itemHeight);
  }
}