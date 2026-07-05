// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';
import 'package:hq_floating_bubble_example/views/example1.dart';
import 'package:hq_floating_bubble_example/views/example2.dart';
import 'package:hq_floating_bubble_example/views/example3.dart';
import 'package:hq_floating_bubble_example/views/example4.dart';

void main() {
  runApp(MyApp());
}

@pragma('vm:entry-point')
void floating() {
  runApp(((_) => NonrmalView()).floating().make());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _configs = [
    HQFloatingWindowConfig(
      id: 'normal',
      // entry: "floating",
      route: '/normal',
      draggable: true,
    ),
    HQFloatingWindowConfig(
      id: 'assitive_touch',
      // entry: "floating",
      route: '/assitive_touch',
      draggable: true,
    ),
    HQFloatingWindowConfig(
      id: 'night',
      // entry: "floating",
      route: '/night',
      width: HQFloatingWindowSize.matchParent,
      height: HQFloatingWindowSize.matchParent,
      clickable: false,
    ),
    HQFloatingWindowConfig(
      id: 'showcase_bubble',
      route: '/showcase_bubble_view',
      width: 160,
      height: 160,
      draggable: true,
      magnet: true,
      snapDuration: 250,
      snapCurve: 'bounce',
    ),
  ];

  final Map<String, WidgetBuilder> _builders = {
    'normal': (_) => NonrmalView(),
    'assitive_touch': (_) => AssistiveTouch(),
    'night': (_) => NightView(),
    'showcase_bubble': (_) => const ShowcaseBubbleView(),
  };

  final Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();

    _routes['/'] = (_) => HomePage(configs: _configs);
    _routes['/showcase'] = (_) => const CompleteShowcaseView();

    for (final c in _configs) {
      if (c.route != null && _builders[c.id] != null) {
        _routes[c.route!] = _builders[c.id]!.floating(debug: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),
      theme: ThemeData(
        useMaterial3: false,
        splashFactory: InkRipple.splashFactory,
      ),
      initialRoute: '/',
      routes: _routes,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<HQFloatingWindowConfig> configs;
  const HomePage({super.key, required this.configs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List<HQFloatingWindow> _windows = [];
  final Map<HQFloatingWindow, bool> _readys = {};
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var c in widget.configs) {
      _windows.add(c.to());
    }
    initAsyncState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      initAsyncState();
    }
  }

  Future<void> initAsyncState() async {
    await HQFloatingService().initialize(force: true);

    var p1 = await HQFloatingService().checkPermission();
    var p2 = await HQFloatingService().isServiceRunning();

    if (!p1) {
      HQFloatingService().openPermissionSetting();
      return;
    }

    if (!p2) {
      await HQFloatingService().startService();
    }

    await _createWindows();

    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  Future<void> _createWindows() async {
    await HQFloatingService().isServiceRunning().then((v) async {
      if (!v) {
        await HQFloatingService().startService().then((_) {
          print('start the backgroud service success.');
        });
      }
    });

    for (int i = 0; i < _windows.length; i++) {
      var w = _windows[i];
      var w0 = HQFloatingService().windows[w.id];
      if (null != w0) {
        _windows[i] = w0;
        _readys[w0] = true;
        continue;
      }
      w.create().then((createdWindow) {
        if (createdWindow != null && mounted) {
          _windows[i] = createdWindow;
          _readys[createdWindow] = true;
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'HQ Floating Overlays',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode_rounded, color: Colors.white),
            tooltip: 'Showcase Dashboard',
            onPressed: () => Navigator.of(context).pushNamed('/showcase'),
          ),
        ],
      ),
      body: _ready
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _windows.length,
                    itemBuilder: (context, index) => _item(_windows[index]),
                  ),
                ),
              ],
            )
          : Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Permission Required',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please grant overlay permissions to display bubbles.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: initAsyncState,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Grant & Start'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.amber, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Interactive Showcase View',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control and test all floating settings and options inside our showcase dashboard.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/showcase'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Launch'),
          ),
        ],
      ),
    );
  }

  void _debug(HQFloatingWindow w) {
    Navigator.of(context).pushNamed(w.config!.route!);
  }

  Widget _item(HQFloatingWindow w) {
    IconData icon;
    Color iconColor;
    String description;

    if (w.id == 'normal') {
      icon = Icons.layers_outlined;
      iconColor = Colors.blue;
      description = 'Standard system alert floating window overlay.';
    } else if (w.id == 'assitive_touch') {
      icon = Icons.fingerprint_rounded;
      iconColor = Colors.orange;
      description = 'Assistive touch style bubble with snap alignments.';
    } else if (w.id == 'night') {
      icon = Icons.nightlight_round_outlined;
      iconColor = Colors.indigo;
      description = 'Full screen night tint overlay bubble.';
    } else {
      icon = Icons.grid_view_rounded;
      iconColor = Colors.teal;
      description = 'Complete showcase bubble featuring multi-views.';
    }

    final isReady = _readys[w] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.id.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isReady ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isReady ? 'Ready' : 'Initializing',
                    style: TextStyle(
                      fontSize: 10,
                      color: isReady ? Colors.green.shade700 : Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Badges showing configurations
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge("Route: ${w.config?.route ?? 'None'}"),
                if (w.config?.width != null) _buildBadge('W: ${w.config?.width}'),
                if (w.config?.height != null) _buildBadge('H: ${w.config?.height}'),
                if (w.config?.draggable ?? false) _buildBadge('Draggable'),
                if (w.config?.magnet ?? false) _buildBadge('Magnet'),
                if (w.config?.clickable ?? false) _buildBadge('Clickable'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isReady ? () => w.start() : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Open'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: w.config?.route != null ? () => _debug(w) : null,
                  icon: const Icon(Icons.bug_report_outlined, size: 18),
                  label: const Text('Debug'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    side: const BorderSide(color: Colors.blueGrey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isReady ? () => {w.close(), w.share('close')} : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
      ),
    );
  }
}
