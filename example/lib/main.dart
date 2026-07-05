import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';
import 'package:hq_floating_bubble_example/bloc/home_page/home_page_bloc.dart';
import 'package:hq_floating_bubble_example/examples/example1.dart';

void main() {
  runApp(MyApp());
}

@pragma('vm:entry-point')
void floating() {
  runApp(((_) => AssistiveTouch()).floating().make());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _configs = [
    HQFloatingWindowConfig(
      id: 'assitive_touch',
      route: '/assitive_touch',
      autosize: false,
      width: 200,
      height: 200,
      x: 300,
      y: 300,
      draggable: true,
    ),
  ];

  final Map<String, WidgetBuilder> _builders = {
    'assitive_touch': (_) => AssistiveTouch(),
  };

  final Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();
    debugPrint('$_configs');
    _routes['/'] = (_) => HomePage(configs: _configs);

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
  late final HomePageBloc _bloc = HomePageBloc();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc.add(InitializeServiceAndWindows(widget.configs));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.add(RefreshServiceStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<HomePageBloc, HomePageState>(
        builder: (context, state) {
          final showList = !state.loading && state.hasPermission && state.ready;

          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FB),
            appBar: AppBar(
              title: const Text(
                'HQ Floating Overlays',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              elevation: 0,
              backgroundColor: Colors.indigo,
            ),
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : (showList
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: state.windows.length,
                          itemBuilder: (context, index) => _item(
                            state.windows[index],
                            state.readys[state.windows[index].id] == true,
                          ),
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
                                  Icon(
                                    state.errorMessage != null
                                        ? Icons.error_rounded
                                        : Icons.security_rounded,
                                    size: 64,
                                    color: state.errorMessage != null ? Colors.red : Colors.orange,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    state.errorMessage != null
                                        ? 'Error Occurred'
                                        : 'Permission Required',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.errorMessage ??
                                        'Please grant overlay permissions to display bubbles.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _bloc.add(InitializeServiceAndWindows(widget.configs)),
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
                        )),
          );
        },
      ),
    );
  }

  Widget _item(HQFloatingWindow w, bool isReady) {
    IconData icon;
    Color iconColor;

    if (w.id == 'assitive_touch') {
      icon = Icons.fingerprint_rounded;
      iconColor = Colors.orange;
    } else {
      icon = Icons.grid_view_rounded;
      iconColor = Colors.teal;
    }

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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: isReady ? () => _bloc.add(OpenWindowRequested(w)) : null,
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
                  onPressed: isReady ? () => _bloc.add(CloseWindowRequested(w)) : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
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
}
