import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

// typedef TransitionBuilder = Widget Function(BuildContext context, Widget? child);
// typedef WidgetBuilder = Widget Function(BuildContext context);

class HQFloatingProvider extends InheritedWidget {
  final HQFloatingWindow? window;
  final Widget child;

  const HQFloatingProvider({
    super.key,
    required this.child,
    required this.window,
  }) : super(child: child);

  @override
  bool updateShouldNotify(HQFloatingProvider oldWidget) {
    return true;
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

  @override
  void initState() {
    super.initState();
    initSyncState();
  }

  Future<void> initSyncState() async {
    // send started message to service
    // this make sure ui already
    if (_window == null) {
      log("[provider] have not sync window at init, need to do at here");
      await HQFloatingService().ensureWindow().then((w) => _window = w);
    }
    // init window from engine and save, only call this int here
    // sync a window from engine
    _changed();
    _window?.on(HQFloatingEventType.WindowResumed, (w, _) => _changed());
  }

  Widget _empty = Container();

  @override
  Widget build(BuildContext context) {
    // make sure window is ready?
    if (!widget.debug && _window == null) return _empty;
    // in production, make sure builder when window is ready
    return Builder(builder: widget.builder ?? (_) => widget.child!)
        ._provider(_window)
        ._autosize(enabled: _autosize, onChange: _onSizeChanged)
        ._material(color: Colors.transparent)
        ._pointerless(_ignorePointer)
        ._app(enabled: widget.app, debug: widget.debug);
  }

  @override
  void dispose() {
    super.dispose();
    // TODO: remove event listener
    // w.un("resumed").un("")
  }

  Future<void> _changed() async {
    // clickable == !ignorePointer
    _ignorePointer = !(_window?.config?.clickable ?? true);
    _autosize = _window?.config?.autosize ?? true;
    // update the flutter ui
    if (mounted) setState(() {});
  }

  void _onSizeChanged(Size size) {
    var radio = _window?.pixelRadio ?? 1;
    _window?.update(
      HQFloatingWindowConfig(
        width: (size.width * radio).toInt(),
        height: (size.height * radio).toInt(),
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
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onChange == null) return widget.child;
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    return UnconstrainedBox(
      child: Container(
        key: widgetKey,
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
            return true;
          },
          child: SizeChangedLayoutNotifier(child: widget.child),
        ),
      ),
    );
  }

  final widgetKey = GlobalKey();
  Size? oldSize;

  void postFrameCallback(Duration _) async {
    final ctx = widgetKey.currentContext;
    if (ctx == null) return;

    if (widget.delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: widget.delay));
    }
    if (mounted == false) return;

    final newSize = ctx.size;
    if (newSize == null || newSize == Size.zero) return;
    // if (oldSize == newSize) return;
    oldSize = newSize;
    widget.onChange!(newSize);
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

  const _ResizeAnchor({required this.child})
    : horizontal = true,
      vertical = true;

  @override
  State<_ResizeAnchor> createState() => __ResizeAnchorState();
}

class __ResizeAnchorState extends State<_ResizeAnchor> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (v) {
        if (kDebugMode) {
          print("=======> scale start $v");
        }
      },
      onScaleUpdate: (v) {
        if (kDebugMode) {
          print("=======> scale update $v");
        }
      },
      onScaleEnd: (v) {
        if (kDebugMode) {
          print("=======> scale end $v");
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
    return !enabled
        ? this
        : _MeasuredSized(delay: delay, onChange: onChange, child: this);
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
        : MaterialApp(debugShowCheckedModeBanner: debug, home: this);
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
