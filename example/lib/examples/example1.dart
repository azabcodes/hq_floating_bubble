import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

import '../bloc/assistive_pannel/assistive_pannel_bloc.dart';
import '../bloc/assistive_touch/assistive_touch_bloc.dart';

@pragma('vm:entry-point')
void _pannelMain() {
  runApp(((_) => AssistivePannel()).floating(app: true).make());
}

class AssistiveTouch extends StatefulWidget {
  const AssistiveTouch({super.key});

  @override
  State<AssistiveTouch> createState() => _AssistiveTouchState();
}

class _AssistiveTouchState extends State<AssistiveTouch> {
  late final AssistiveTouchBloc _bloc = AssistiveTouchBloc();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bloc.add(
        InitializeAssistiveTouch(
          touchWindow: HQFloatingWindow.of(context),
          pannelMainCallback: _pannelMain,
        ),
      );
    });
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: SizedBox(
        width: 56,
        height: 56,
        child: AssistiveButton(
          onTap: () {
            final w = HQFloatingWindow.of(context);
            final pixelRatio = w?.pixelRadio ?? 3.0;
            final x = (w?.config?.x ?? 0) / pixelRatio;
            final y = (w?.config?.y ?? 0) / pixelRatio;
            _bloc.add(OpenPanelRequested(x: x, y: y));
          },
        ),
      ),
    );
  }
}

@immutable
class AssistiveButton extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// Switches between showing the [child] or hiding it.
  final bool visible;

  /// Whether it sticks to the side.
  final bool shouldStickToSide;

  /// Empty space to surround the [child].
  final EdgeInsets margin;

  final Offset initialOffset;

  /// A tap with a primary button has occurred.
  final VoidCallback? onTap;

  /// Custom animated builder.
  final Widget Function(BuildContext context, Widget child, bool visible)? animatedBuilder;

  const AssistiveButton({
    super.key,
    this.child = const _DefaultChild(),
    this.visible = true,
    this.shouldStickToSide = true,
    this.margin = const EdgeInsets.all(8.0),
    this.initialOffset = Offset.infinite,
    this.onTap,
    this.animatedBuilder,
  });

  @override
  State<AssistiveButton> createState() => _AssistiveButtonState();
}

class _AssistiveButtonState extends State<AssistiveButton> with SingleTickerProviderStateMixin {
  Size? _lastScreenSize;
  EdgeInsets? _lastPadding;
  EdgeInsets? _lastViewInsets;
  bool _repositionScheduled = false;
  late Offset offset = widget.initialOffset;
  late Offset largerOffset = offset;

  static const Size size = Size(56, 56);

  bool isDragging = false;
  bool isIdle = true;
  Timer? timer;
  Timer? _focusDebounceTimer;

  late final AnimationController _scaleAnimationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );
  late final Animation<double> _scaleAnimation = CurvedAnimation(
    parent: _scaleAnimationController,
    curve: Curves.easeInOut,
  );

  HQFloatingWindow? window;
  HQFloatingWindowListener? _dragStartListener;
  HQFloatingWindowListener? _draggingListener;
  HQFloatingWindowListener? _dragEndListener;

  @override
  void initState() {
    super.initState();
    // Drive the initial scale state once instead of polling every 60ms.
    widget.visible ? _scaleAnimationController.forward() : _scaleAnimationController.reverse();
    FocusManager.instance.addListener(listener);
  }

  @override
  void didUpdateWidget(covariant AssistiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      widget.visible ? _scaleAnimationController.forward() : _scaleAnimationController.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    final currentSize = mq.size;
    final currentPadding = mq.padding;
    final currentViewInsets = mq.viewInsets;

    if (_lastScreenSize != currentSize ||
        _lastPadding != currentPadding ||
        _lastViewInsets != currentViewInsets) {
      _lastScreenSize = currentSize;
      _lastPadding = currentPadding;
      _lastViewInsets = currentViewInsets;

      if (!_repositionScheduled) {
        _repositionScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _repositionScheduled = false;
          if (mounted) {
            _setOffset(offset);
          }
        });
      }
    }
    if (window == null) {
      window = HQFloatingWindow.of(context);
      _dragStartListener = (window, data) => _onDragStart();
      _draggingListener = (window, data) {
        final p = data as List<dynamic>;
        _onDragUpdate(p[0], p[1]);
      };
      _dragEndListener = (window, data) => _onDragEnd();

      window!.on(HQFloatingEventType.WindowDragStart, _dragStartListener!);
      window!.on(HQFloatingEventType.WindowDragging, _draggingListener!);
      window!.on(HQFloatingEventType.WindowDragEnd, _dragEndListener!);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _focusDebounceTimer?.cancel();
    FocusManager.instance.removeListener(listener);
    if (window != null) {
      if (_dragStartListener != null) {
        window!.off(HQFloatingEventType.WindowDragStart, _dragStartListener!);
      }
      if (_draggingListener != null) {
        window!.off(HQFloatingEventType.WindowDragging, _draggingListener!);
      }
      if (_dragEndListener != null) {
        window!.off(HQFloatingEventType.WindowDragEnd, _dragEndListener!);
      }
    }
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void listener() {
    // Cancel any pending debounce so rapid focus changes don't stack up
    // multiple timers running concurrently.
    _focusDebounceTimer?.cancel();
    _focusDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      largerOffset = Offset(
        max(largerOffset.dx, offset.dx),
        max(largerOffset.dy, offset.dy),
      );

      _setOffset(largerOffset, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    child = GestureDetector(onTap: _onTap, child: child);

    child = widget.animatedBuilder != null
        ? widget.animatedBuilder!(context, child, widget.visible)
        : ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedOpacity(
              opacity: isIdle ? .3 : 1,
              duration: const Duration(milliseconds: 300),
              child: child,
            ),
          );

    return child;
  }

  void _onTap() {
    final callback = widget.onTap;
    if (callback == null) return;

    if (isIdle) {
      setState(() {
        isIdle = false;
      });
    }
    _scheduleIdle();
    callback();
  }

  void _onDragStart() {
    if (isDragging) return;
    setState(() {
      isDragging = true;
      isIdle = false;
    });
    timer?.cancel();
  }

  void _onDragUpdate(int x, int y) {
    _setOffset(Offset(x.toDouble(), y.toDouble()));
  }

  void _onDragEnd() {
    if (!isDragging) return;
    setState(() {
      isDragging = false;
    });
    _scheduleIdle();

    _setOffset(offset);
  }

  void _scheduleIdle() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 2), () {
      if (!mounted || isDragging || isIdle) return;
      setState(() {
        isIdle = true;
      });
    });
  }

  Point<int>? _lastPosition;
  void _updatePosition() {
    final current = Point(
      offset.dx.round(),
      offset.dy.round(),
    );

    if (_lastPosition == current) return;
    _lastPosition = current;

    window?.update(
      HQFloatingWindowConfig(
        x: current.x,
        y: current.y,
      ),
    );
  }

  /// Returns the [left, top, right, bottom] usable bounds for the button,
  /// accounting for screen padding, view insets, margins, and the button's
  /// own measured size.
  ({double left, double top, double right, double bottom}) _bounds(Size screenSize) {
    final mediaQuery = MediaQuery.of(context);
    final screenPadding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;
    final left = screenPadding.left + viewInsets.left + widget.margin.left;
    final top = screenPadding.top + viewInsets.top + widget.margin.top;
    final right =
        screenSize.width -
        screenPadding.right -
        viewInsets.right -
        widget.margin.right -
        size.width;
    final bottom =
        screenSize.height -
        screenPadding.bottom -
        viewInsets.bottom -
        widget.margin.bottom -
        size.height;
    return (left: left, top: top, right: right, bottom: bottom);
  }

  /// TODO: this function should depend on the gravity to calcute the position
  void _setOffset(Offset offset, [bool shouldUpdateLargerOffset = true]) {
    if (offset.dx.isInfinite || offset.dy.isInfinite) {
      final screenSize = window?.system?.screenSize ?? MediaQuery.of(context).size;
      offset = Offset(screenSize.width, screenSize.height / 2);
    }

    if (shouldUpdateLargerOffset) {
      largerOffset = offset;
    }

    if (isDragging) {
      this.offset = offset;
      return;
    }

    final screenSize = window?.system?.screenSize ?? MediaQuery.of(context).size;
    final b = _bounds(screenSize);

    final normalizedTop = max(min(offset.dy, b.bottom), b.top);

    double normalizedLeft;
    if (widget.shouldStickToSide) {
      final centerX = b.left + ((b.right - b.left) / 2);
      final stuckToVerticalEdge = normalizedTop == b.bottom || normalizedTop == b.top;
      final targetX = stuckToVerticalEdge ? offset.dx : (offset.dx < centerX ? b.left : b.right);
      normalizedLeft = max(min(targetX, b.right), b.left);
    } else {
      normalizedLeft = max(min(offset.dx, b.right), b.left);
    }

    this.offset = Offset(normalizedLeft, normalizedTop);
    _updatePosition();
  }
}

class AssistivePannel extends StatefulWidget {
  const AssistivePannel({super.key});

  @override
  State<AssistivePannel> createState() => _AssistivePannelState();
}

class _AssistivePannelState extends State<AssistivePannel> {
  late final AssistivePannelBloc _bloc = AssistivePannelBloc();
  bool _windowInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_windowInitialized) {
      _windowInitialized = true;
      _bloc.add(UpdatePannelWindow(HQFloatingWindow.of(context)));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  final double _touchSize = 56.0;
  var factor = 0.8;

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double size = 0.0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AssistivePannelBloc, AssistivePannelState>(
        builder: (context, state) {
          screenWidth = MediaQuery.of(context).size.width;
          screenHeight = MediaQuery.of(context).size.height;
          size = screenWidth * factor;

          final touchCenterX = state.touchX + _touchSize / 2;
          final touchCenterY = state.touchY + _touchSize / 2;

          final expandedLeft = (screenWidth - size) / 2;
          final expandedTop = max(
            20.0,
            min(touchCenterY - size / 2, screenHeight - size - 20),
          );

          final panelCenterX = expandedLeft + size / 2;
          final panelCenterY = expandedTop + size / 2;

          final alignX = (touchCenterX - panelCenterX) / (size / 2);
          final alignY = (touchCenterY - panelCenterY) / (size / 2);

          Widget action(
            IconData icon,
            String title,
            VoidCallback onTap,
          ) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _bloc.add(ClosePannelRequested()),
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned(
                    left: expandedLeft,
                    top: expandedTop,
                    width: size,
                    height: size,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedScale(
                        scale: state.show ? 1.0 : 0.01,
                        alignment: Alignment(
                          alignX.clamp(-1.0, 1.0),
                          alignY.clamp(-1.0, 1.0),
                        ),
                        duration: _bloc.duration,
                        curve: Curves.easeOutCubic,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            color: Color.fromARGB(255, 25, 24, 24),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .85),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: GridView.count(
                              padding: const EdgeInsets.all(24),
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                action(Icons.home, 'Home', () {}),
                                action(Icons.screenshot, 'Screenshot', () {}),
                                action(Icons.volume_up, 'Volume', () {}),
                                action(Icons.brightness_6, 'Brightness', () {}),
                                action(Icons.settings, 'Settings', () {}),
                                action(
                                  Icons.close,
                                  'Close',
                                  () => _bloc.add(ClosePannelRequested()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DefaultChild extends StatelessWidget {
  const _DefaultChild();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: Container(
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[400]!.withValues(alpha: .6),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        child: Container(
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[300]!.withValues(alpha: .6),
            borderRadius: const BorderRadius.all(Radius.circular(28)),
          ),
          child: Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
