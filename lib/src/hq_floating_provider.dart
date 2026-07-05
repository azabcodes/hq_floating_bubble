import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

class HQFloatingProvider extends InheritedWidget {
  final HQFloatingWindow? window;
  @override
  final Widget child;

  const HQFloatingProvider({
    super.key,
    required this.child,
    required this.window,
  }) : super(child: child);

  @override
  bool updateShouldNotify(HQFloatingProvider oldWidget) {
    return oldWidget.window != window;
  }
}

class HQFloatingContainer extends StatefulWidget {
  final Widget? child;
  final WidgetBuilder? builder;
  final bool debug;
  final bool app;

  const HQFloatingContainer({
    super.key,
    this.child,
    this.builder,
    this.debug = false,
    this.app = false,
  }) : assert(child != null || builder != null);

  @override
  State<HQFloatingContainer> createState() => _HQFloatingContainerState();
}

class _HQFloatingContainerState extends State<HQFloatingContainer> {
  HQFloatingWindow? _window = HQFloatingService().currentWindow;

  var _ignorePointer = false;
  var _autosize = true;
  HQFloatingWindowListener? _resumeListener;

  @override
  void initState() {
    super.initState();
    initSyncState();
  }

  Future<void> initSyncState() async {
    if (_window == null) {
      log('[provider] have not sync window at init, need to do at here');
      final win = await HQFloatingService().ensureWindow();
      if (!mounted) return;
      _window = win;
    }
    await _changed();

    if (!mounted) return;
    _resumeListener = (w, _) => _changed();
    _window?.on(HQFloatingEventType.WindowResumed, _resumeListener!);
  }

  static const Widget _empty = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    if (!widget.debug && _window == null) return _empty;
    return Builder(builder: widget.builder ?? (_) => widget.child!)
        ._provider(_window)
        ._autosize(enabled: _autosize, onChange: _onSizeChanged)
        ._material(color: Colors.transparent)
        ._pointerless(_ignorePointer)
        ._app(enabled: widget.app, debug: widget.debug);
  }

  @override
  void dispose() {
    if (_resumeListener != null && _window != null) {
      _window!.off(HQFloatingEventType.WindowResumed, _resumeListener!);
    }
    super.dispose();
  }

  Future<void> _changed() async {
    final newIgnore = !(_window?.config?.clickable ?? true);
    final newAutosize = _window?.config?.autosize ?? true;

    if (newIgnore == _ignorePointer && newAutosize == _autosize) {
      return;
    }

    _ignorePointer = newIgnore;
    _autosize = newAutosize;
    if (mounted) setState(() {});
  }

  Size? _lastSize;
  int? _lastWidth;
  int? _lastHeight;

  void _onSizeChanged(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;

    final radio = _window?.pixelRadio ?? 1;

    final width = (size.width * radio).round();
    final height = (size.height * radio).round();

    if (_lastWidth == width && _lastHeight == height) {
      return;
    }

    _lastWidth = width;
    _lastHeight = height;

    _window?.update(
      HQFloatingWindowConfig(
        width: width,
        height: height,
      ),
    );
  }
}

class _MeasuredSized extends StatefulWidget {
  const _MeasuredSized({
    required this.onChange,
    required this.child,
    this.delay = 0,
  });

  final Widget child;

  final int delay;

  final void Function(Size size)? onChange;

  @override
  _MeasuredSizedState createState() => _MeasuredSizedState();
}

class _MeasuredSizedState extends State<_MeasuredSized> {
  bool _scheduled = false;
  Size? oldSize;

  void _scheduleMeasure() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      postFrameCallback(Duration.zero);
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onChange == null) return widget.child;
    _scheduleMeasure();
    return OverflowBox(
      minWidth: 0.0,
      minHeight: 0.0,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _scheduleMeasure();
          return true;
        },
        child: SizeChangedLayoutNotifier(child: widget.child),
      ),
    );
  }

  void postFrameCallback(Duration _) async {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    if (widget.delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: widget.delay));
    }
    if (!mounted) return;

    final newSize = box.size;
    if (newSize == Size.zero) return;
    if (oldSize == newSize) return;
    oldSize = newSize;
    widget.onChange?.call(newSize);
  }
}

typedef DragCallback = void Function(Offset offset);

class _DragAnchor extends StatefulWidget {
  final Widget child;
  // TODO:
  // final bool horizontal;
  // final bool vertical;

  // final DragCallback? onDragStart;
  // final DragCallback? onDragUpdate;
  // final DragCallback? onDragEnd;

  const _DragAnchor({
    required this.child,

    // this.horizontal = true,
    // this.vertical = true,

    // this.onDragStart,
    // this.onDragUpdate,
    // this.onDragEnd,
  });

  @override
  State<_DragAnchor> createState() => _DragAnchorState();
}

class _DragAnchorState extends State<_DragAnchor> {
  @override
  Widget build(BuildContext context) {
    // return Draggable();
    return GestureDetector(
      onTapDown: _enableDrag,
      onTapUp: _disableDrag2,
      onTapCancel: _disableDrag,
      child: widget.child,
    );
  }

  void _enableDrag(_) {
    // enabe drag
    HQFloatingWindow.of(
      context,
    )?.update(HQFloatingWindowConfig(draggable: true));
  }

  void _disableDrag() {
    // disable drag
    HQFloatingWindow.of(
      context,
    )?.update(HQFloatingWindowConfig(draggable: false));
  }

  void _disableDrag2(_) {
    _disableDrag();
  }
}

class _ResizeAnchor extends StatefulWidget {
  final Widget child;

  // Reserved for future resize direction support
  // ignore: unused_element
  final bool horizontal;
  // ignore: unused_element
  final bool vertical;

  const _ResizeAnchor({required this.child}) : horizontal = true, vertical = true;

  @override
  State<_ResizeAnchor> createState() => __ResizeAnchorState();
}

class __ResizeAnchorState extends State<_ResizeAnchor> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (v) {
        if (kDebugMode) {
          log(
            'scale update $v',
            name: 'HQFloating',
          );
        }
      },
      onScaleUpdate: (v) {
        if (kDebugMode) {
          log(
            'scale update $v',
            name: 'HQFloating',
          );
        }
      },
      onScaleEnd: (v) {
        if (kDebugMode) {
          log(
            'scale update $v',
            name: 'HQFloating',
          );
        }
      },
      child: widget.child,
    );
  }
}

extension WidgetProviderExtension on Widget {
  /// Export floating extension function to inject for root widget
  Widget floating({bool debug = false, bool app = false}) {
    return HQFloatingContainer(debug: debug, app: app, child: this);
  }

  /// Export draggable extension function to inject for child widget
  // Widget draggable({
  //   bool enabled = true,
  // }) {
  //   return enabled?_DragAnchor(child: this):this;
  // }

  /// Export resizable extension function to inject for child
  // Widget resizable({
  //   bool enabled = true,
  // }) {
  //   return enabled?_ResizeAnchor(child: this):this;
  // }

  Widget _provider(HQFloatingWindow? window) {
    return HQFloatingProvider(window: window, child: this);
  }

  Widget _autosize({
    bool enabled = false,
    void Function(Size)? onChange,
    int delay = 0,
  }) {
    return !enabled ? this : _MeasuredSized(delay: delay, onChange: onChange, child: this);
  }

  Widget _pointerless([bool ignoring = false]) {
    return IgnorePointer(ignoring: ignoring, child: this);
  }

  Widget _material({bool enabled = false, Color? color}) {
    return !enabled ? this : Material(color: color, child: this);
  }

  Widget _app({bool enabled = false, bool debug = false}) {
    return !enabled
        ? this
        : MaterialApp(
            debugShowCheckedModeBanner: debug,
            scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),
            theme: ThemeData(
              splashFactory: InkRipple.splashFactory,
            ),
            home: Scaffold(
              backgroundColor: Colors.transparent,
              body: this,
            ),
          );
  }
}

extension WidgetBuilderProviderExtension on WidgetBuilder {
  WidgetBuilder floating({bool debug = false, bool app = false}) {
    return (_) => HQFloatingContainer(builder: this, debug: debug, app: app);
  }

  Widget make() {
    return Builder(builder: this);
  }
}
