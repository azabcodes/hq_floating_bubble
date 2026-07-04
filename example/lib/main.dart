import 'package:flutter/material.dart';

import 'package:hq_floating_bubble/hq_floating_bubble.dart';
import 'package:hq_floating_bubble_example/views/example2.dart';
import 'package:hq_floating_bubble_example/views/example3.dart';
import 'package:hq_floating_bubble_example/views/example1.dart';

void main() {
  runApp(MyApp());
}

@pragma("vm:entry-point")
void floating() {
  runApp(((_) => NonrmalView()).floating().make());
}

void floating2(HQFloatingWindow w) {
  runApp(
    MaterialApp(
      // floating on widget can't use HQFloatingWindow.of(context)
      // to access window instance
      // should use HQFloatingService().currentWindow
      home: NonrmalView().floating(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _configs = [
    HQFloatingWindowConfig(
      id: "normal",
      // entry: "floating",
      route: "/normal",
      draggable: true,
    ),
    HQFloatingWindowConfig(
      id: "assitive_touch",
      // entry: "floating",
      route: "/assitive_touch",
      draggable: true,
    ),
    HQFloatingWindowConfig(
      id: "night",
      // entry: "floating",
      route: "/night",
      width: HQFloatingWindowSize.matchParent,
      height: HQFloatingWindowSize.matchParent,
      clickable: false,
    ),
  ];

  final Map<String, WidgetBuilder> _builders = {
    "normal": (_) => NonrmalView(),
    "assitive_touch": (_) => AssistiveTouch(),
    "night": (_) => NightView(),
  };

  final Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();

    _routes["/"] = (_) => HomePage(configs: _configs);

    _configs.forEach(
      (c) => {
        if (c.route != null && _builders[c.id] != null)
          {_routes[c.route!] = _builders[c.id]!.floating(debug: false)},
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: _routes,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<HQFloatingWindowConfig> configs;
  const HomePage({Key? key, required this.configs}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    widget.configs.forEach((c) => _windows.add(c.to()));

    HQFloatingService().initialize();

    initAsyncState();
  }

  final List<HQFloatingWindow> _windows = [];

  final Map<HQFloatingWindow, bool> _readys = {};

  bool _ready = false;

  initAsyncState() async {
    var p1 = await HQFloatingService().checkPermission();
    var p2 = await HQFloatingService().isServiceRunning();

    // get permission first
    if (!p1) {
      HQFloatingService().openPermissionSetting();
      return;
    }

    // start service
    if (!p2) {
      HQFloatingService().startService();
    }

    _createWindows();

    setState(() {
      _ready = true;
    });
  }

  _createWindows() async {
    await HQFloatingService().isServiceRunning().then((v) async {
      if (!v)
        await HQFloatingService().startService().then((_) {
          print("start the backgroud service success.");
        });
    });

    _windows.forEach((w) {
      var _w = HQFloatingService().windows[w.id];
      if (null != _w) {
        // replace w with _w
        _readys[w] = true;
        return;
      }
      w.on(HQFloatingEventType.WindowCreated, (window, data) {
        _readys[window] = true;
        setState(() {});
      }).create();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HQFloating example app')),
      body: _ready
          ? ListView(children: _windows.map((e) => _item(e)).toList())
          : Center(
              child: ElevatedButton(
                onPressed: () {
                  initAsyncState();
                },
                child: Text("Start"),
              ),
            ),
    );
  }

  _debug(HQFloatingWindow w) {
    Navigator.of(context).pushNamed(w.config!.route!);
  }

  Widget _item(HQFloatingWindow w) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              w.id,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 214, 213, 213),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: Text(w.config?.toString() ?? ""),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: (_readys[w] == true) ? () => w.start() : null,
                  child: Text("Open"),
                ),
                TextButton(
                  onPressed: w.config?.route != null ? () => _debug(w) : null,
                  child: Text("Debug"),
                ),
                TextButton(
                  onPressed: (_readys[w] == true)
                      ? () => {w.close(), w.share("close")}
                      : null,
                  child: Text("Close", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
