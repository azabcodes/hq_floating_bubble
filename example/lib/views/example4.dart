import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

class CompleteShowcaseView extends StatefulWidget {
  const CompleteShowcaseView({super.key});

  @override
  State<CompleteShowcaseView> createState() => _CompleteShowcaseViewState();
}

class _CompleteShowcaseViewState extends State<CompleteShowcaseView> {
  // Config state
  bool _magnet = true;
  int _snapDuration = 250;
  String _snapCurve = 'bounce'; // Default to bounce to showcase the effect clearly

  // WakeLock state
  bool _wakeLockEnabled = false;

  // Foreground Service states
  final _titleController = TextEditingController(text: 'HQ Showcase Service');
  final _descController = TextEditingController(
    text: 'Complete features test is active',
  );
  final _iconController = TextEditingController(text: 'ic_launcher');

  // Event stream subscription and logs
  StreamSubscription? _eventSubscription;
  final List<String> _eventLogs = [];

  // Active window reference
  HQFloatingWindow? _showcaseWindow;
  bool _isWindowCreated = false;
  bool _isWindowStarted = false;

  @override
  void initState() {
    super.initState();
    // Register global event listener
    _eventSubscription = HQFloatingService().onEvent.listen((event) {
      if (mounted) {
        setState(() {
          _eventLogs.insert(
            0,
            "${DateTime.now().toString().split(' ').last} - Event: ${event.name} Data: ${event.data}",
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // Action methods
  Future<void> _createWindow() async {
    final hasPermission = await HQFloatingService().checkPermission();
    if (!hasPermission) {
      await HQFloatingService().openPermissionSetting();
      return;
    }

    final config = HQFloatingWindowConfig(
      id: 'showcase_bubble',
      entry: 'main',
      route: '/showcase_bubble_view',
      width: 160,
      height: 160,
      draggable: true,
      magnet: _magnet,
      snapDuration: _snapDuration,
      snapCurve: _snapCurve,
      clickable: true,
    );

    final win = await config.create(id: 'showcase_bubble');
    if (win != null) {
      setState(() {
        _showcaseWindow = win;
        _isWindowCreated = true;
      });
    }
  }

  Future<void> _startWindow() async {
    if (_showcaseWindow != null) {
      final success = await _showcaseWindow!.start();
      if (success != null && success) {
        setState(() {
          _isWindowStarted = true;
        });
      }
    }
  }

  Future<void> _closeWindow() async {
    if (_showcaseWindow != null) {
      await _showcaseWindow!.close();
      setState(() {
        _isWindowStarted = false;
      });
    }
  }

  Future<void> _showWindow() async {
    if (_showcaseWindow != null) {
      await _showcaseWindow!.show();
    }
  }

  Future<void> _hideWindow() async {
    if (_showcaseWindow != null) {
      await _showcaseWindow!.hide();
    }
  }

  Future<void> _updateConfig() async {
    if (_showcaseWindow != null) {
      await _showcaseWindow!.update(
        HQFloatingWindowConfig(
          magnet: _magnet,
          snapDuration: _snapDuration,
          snapCurve: _snapCurve,
        ),
      );
    }
  }

  Future<void> _promote() async {
    await HQFloatingService().promoteService(
      title: _titleController.text,
      description: _descController.text,
      icon: _iconController.text,
      showWhen: true,
      subText: 'Showcase Mode',
    );
  }

  Future<void> _demote() async {
    await HQFloatingService().demoteService();
  }

  Future<void> _toggleWakeLock(bool value) async {
    final success = await HQFloatingService().setWakeLock(value);
    if (success) {
      setState(() {
        _wakeLockEnabled = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Features Showcase'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Window Controls
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Window Control Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _isWindowCreated ? null : _createWindow,
                          child: const Text('Create'),
                        ),
                        ElevatedButton(
                          onPressed: (_isWindowCreated && !_isWindowStarted) ? _startWindow : null,
                          child: const Text('Start'),
                        ),
                        ElevatedButton(
                          onPressed: _isWindowStarted ? _closeWindow : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[100],
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isWindowStarted ? _showWindow : null,
                          icon: const Icon(Icons.visibility),
                          label: const Text('Show (Scale & Fade)'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isWindowStarted ? _hideWindow : null,
                          icon: const Icon(Icons.visibility_off),
                          label: const Text('Hide'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Section 2: Custom Snapping Physics Config
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Magnet Snap Customization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Enable Magnet Snapping'),
                      value: _magnet,
                      onChanged: (val) {
                        setState(() => _magnet = val);
                        _updateConfig();
                      },
                    ),
                    ListTile(
                      title: const Text('Snap Curve/Interpolator'),
                      trailing: DropdownButton<String>(
                        value: _snapCurve,
                        items:
                            [
                              'decelerate',
                              'bounce',
                              'overshoot',
                              'accelerate',
                              'linear',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _snapCurve = val);
                            _updateConfig();
                          }
                        },
                      ),
                    ),
                    Text('Snap Duration: $_snapDuration ms'),
                    Slider(
                      value: _snapDuration.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '$_snapDuration ms',
                      onChanged: (val) {
                        setState(() => _snapDuration = val.toInt());
                        _updateConfig();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Section 3: Foreground Customization & WakeLock
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Foreground & Wakelock Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Description',
                      ),
                    ),
                    TextField(
                      controller: _iconController,
                      decoration: const InputDecoration(
                        labelText: 'Drawable Icon Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: _promote,
                          child: const Text('Promote Service'),
                        ),
                        ElevatedButton(
                          onPressed: _demote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Demote'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('CPU WakeLock'),
                      subtitle: const Text(
                        'Keep CPU running when screen is off',
                      ),
                      value: _wakeLockEnabled,
                      onChanged: _toggleWakeLock,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Section 4: Real-time Event Logger
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '4. Real-time Event Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _eventLogs.clear()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _eventLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No events recorded yet.\nTry dragging, showing, or hiding the bubble.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _eventLogs.length,
                              itemBuilder: (context, idx) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Text(
                                    _eventLogs[idx],
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple floating bubble overlay view widget
class ShowcaseBubbleView extends StatelessWidget {
  const ShowcaseBubbleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.offline_bolt_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
