import 'dart:async';

import 'package:flip_curl_animation_widget/src/builders/builder.dart';
import 'package:flutter/material.dart';

class CustomPageFlip extends StatefulWidget {
  const CustomPageFlip({
    Key? key,
    this.duration = const Duration(milliseconds: 450),
    this.cutoffForward = 0.8,
    this.cutoffPrevious = 0.1,
    this.backgroundColor = Colors.white,
    required this.children,
    this.initialIndex = 0,
    this.lastPage,
    this.isRightSwipe = false,
    this.showControllerButton = false,
    this.onPageChanged,
  })  : assert(initialIndex < children.length,
            'initialIndex cannot be greater than children length'),
        super(key: key);

  final Color backgroundColor;
  final List<Widget> children;
  final Duration duration;
  final int initialIndex;
  final Widget? lastPage;
  final double cutoffForward;
  final double cutoffPrevious;
  final bool isRightSwipe;
  final bool showControllerButton;
  final ValueChanged<int>? onPageChanged;

  @override
  CustomPageFlipState createState() => CustomPageFlipState();
}

class CustomPageFlipState extends State<CustomPageFlip>
    with TickerProviderStateMixin {
  int pageNumber = 0;
  List<Widget> pages = [];
  final List<AnimationController> _controllers = [];
  bool? _isForward;

  @override
  void didUpdateWidget(CustomPageFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    imageData = {};
    currentPage = ValueNotifier(-1);
    currentWidget = ValueNotifier(Container());
    currentPageIndex = ValueNotifier(0);
    _setUp();
  }

  void _setUp({bool isRefresh = false}) {
    _controllers.clear();
    pages.clear();
    if (widget.lastPage != null) {
      widget.children.add(widget.lastPage!);
    }
    for (var i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        value: 1,
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(controller);
      final child = PageFlipBuilder(
        amount: controller,
        backgroundColor: widget.backgroundColor,
        isRightSwipe: widget.isRightSwipe,
        pageIndex: i,
        key: Key('item$i'),
        child: widget.children[i],
      );
      pages.add(child);
    }
    pages = pages.reversed.toList();
    if (isRefresh) {
      goToPage(pageNumber);
    } else {
      pageNumber = widget.initialIndex;
      lastPageLoad = pages.length < 3 ? 0 : 3;
    }
    if (widget.initialIndex != 0) {
      currentPage = ValueNotifier(widget.initialIndex);
      currentWidget = ValueNotifier(pages[pageNumber]);
      currentPageIndex = ValueNotifier(widget.initialIndex);
    }
  }

  bool get _isLastPage => (pages.length - 1) == pageNumber;

  int lastPageLoad = 0;

  bool get _isFirstPage => pageNumber == 0;

  void _turnPage(DragUpdateDetails details, BoxConstraints dimens) {
    currentPage.value = pageNumber;
    currentWidget.value = Container();
    final ratio = details.delta.dx / dimens.maxWidth;
    if (_isForward == null) {
      if (widget.isRightSwipe
          ? details.delta.dx < 0.0
          : details.delta.dx > 0.0) {
        _isForward = false;
      } else if (widget.isRightSwipe
          ? details.delta.dx > 0.2
          : details.delta.dx < -0.2) {
        _isForward = true;
      } else {
        _isForward = null;
      }
    }

    if (_isForward == true || pageNumber == 0) {
      final pageLength = pages.length;
      final pageSize = widget.lastPage != null ? pageLength : pageLength - 1;
      if (pageNumber != pageSize && !_isLastPage) {
        widget.isRightSwipe
            ? _controllers[pageNumber].value -= ratio
            : _controllers[pageNumber].value += ratio;
      }
    }
  }

  Future _onDragFinish() async {
    if (_isForward != null) {
      if (_isForward == true) {
        if (!_isLastPage &&
            _controllers[pageNumber].value <= (widget.cutoffForward + 0.15)) {
          await nextPage();
        } else {
          if (!_isLastPage) {
            await _controllers[pageNumber].forward();
          }
        }
      } else {
        if (!_isFirstPage &&
            _controllers[pageNumber - 1].value >= widget.cutoffPrevious) {
          await previousPage();
        } else {
          if (_isFirstPage) {
            await _controllers[pageNumber].forward();
          } else {
            await _controllers[pageNumber - 1].reverse();
            if (!_isFirstPage) {
              await previousPage();
            }
          }
        }
      }
    }

    _isForward = null;
    currentPage.value = -1;
  }

  Future animateToNextPage() async {
    if (_isLastPage) return;

    // Update currentPage and currentPageIndex to the current page to render new page
    currentPage.value = pageNumber;
    currentPageIndex.value = pageNumber;

    // Let Flutter rebuild widgets and capture images asynchronously
    await Future.delayed(const Duration(milliseconds: 50));

    // Then animate flipping the page backward (reverse animation)
    await _controllers[pageNumber].reverse();

    if (mounted) {
      setState(() {
        pageNumber++;
      });

      // Update the notifiers for the new page
      currentPageIndex.value = pageNumber;
      currentWidget.value = pages[pageNumber];

      if (widget.onPageChanged != null) {
        widget.onPageChanged!(pageNumber);
      }
    }
  }

  Future animateToPreviousPage() async {
    if (_isFirstPage) return;

    // Update currentPage and currentPageIndex
    currentPage.value = pageNumber - 1;
    currentPageIndex.value = pageNumber - 1;

    // Wait to let widget render and image capture
    await Future.delayed(const Duration(milliseconds: 50));

    // Animate the previous page flip forward
    await _controllers[pageNumber - 1].forward();

    if (mounted) {
      setState(() {
        pageNumber--;
      });

      currentPageIndex.value = pageNumber;
      currentWidget.value = pages[pageNumber];

      if (widget.onPageChanged != null) {
        widget.onPageChanged!(pageNumber);
      }
    }
  }

  Future nextPage() async {
    await _controllers[pageNumber].reverse();
    if (mounted) {
      setState(() {
        pageNumber++;
      });
      if (widget.onPageChanged != null) widget.onPageChanged!(pageNumber);
    }

    if (pageNumber < pages.length) {
      currentPageIndex.value = pageNumber;
      currentWidget.value = pages[pageNumber];
    }

    if (_isLastPage) {
      currentPageIndex.value = pageNumber;
      currentWidget.value = pages[pageNumber];
      return;
    }
  }

  Future previousPage() async {
    await _controllers[pageNumber - 1].forward();
    if (mounted) {
      setState(() {
        pageNumber--;
      });
      if (widget.onPageChanged != null) widget.onPageChanged!(pageNumber);
    }
    currentPageIndex.value = pageNumber;
    currentWidget.value = pages[pageNumber];
    imageData[pageNumber] = null;
  }

  Future goToPage(int index) async {
    if (mounted) {
      setState(() {
        pageNumber = index;
      });
      if (widget.onPageChanged != null) widget.onPageChanged!(pageNumber);
    }
    for (var i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].forward();
      } else if (i < index) {
        _controllers[i].reverse();
      } else {
        if (_controllers[i].status == AnimationStatus.reverse) {
          _controllers[i].value = 1;
        }
      }
    }
    currentPageIndex.value = pageNumber;
    currentWidget.value = pages[pageNumber];
    currentPage.value = pageNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      LayoutBuilder(
        builder: (context, dimens) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {},
          onTapUp: (details) {},
          onPanDown: (details) {},
          onPanEnd: (details) {},
          onTapCancel: () {},
          onHorizontalDragCancel: () => _isForward = null,
          onHorizontalDragUpdate: (details) => _turnPage(details, dimens),
          onHorizontalDragEnd: (details) => _onDragFinish(),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (widget.lastPage != null) ...[
                widget.lastPage!,
              ],
              if (pages.isNotEmpty) ...pages else ...[const SizedBox.shrink()],
            ],
          ),
        ),
      ),

      if (!_isFirstPage && widget.showControllerButton)
        Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: FloatingActionButton(
              heroTag: "prev_btn",
              onPressed: () async {
                if (!_isFirstPage) await animateToPreviousPage();
              },
              child: Icon(Icons.arrow_back_ios_new_rounded),
              backgroundColor: Colors.grey.withValues(alpha: 0.7),
              mini: true,
              elevation: 4,
            ),
          ),
        ),
      // Right-side Next button
      if (!_isLastPage && widget.showControllerButton)
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: FloatingActionButton(
              heroTag: "next_btn",
              onPressed: () async {
                if (!_isLastPage) await animateToNextPage();
              },
              child: Icon(Icons.arrow_forward_ios_rounded),
              backgroundColor: Colors.grey.withValues(alpha: 0.7),
              mini: true,
              elevation: 4,
            ),
          ),
        ),
    ]);
  }
}
