import 'package:flutter/material.dart';
import 'package:hq_floating_bubble/hq_floating_bubble.dart';

class NightView extends StatefulWidget {
  const NightView({super.key});

  @override
  State<NightView> createState() => _NightViewState();
}

class _NightViewState extends State<NightView> {
  Color color = Color.fromARGB(255, 192, 200, 41).withValues(alpha: 0.20);

  @override
  void initState() {
    super.initState();
  }

  HQFloatingWindow? w;

  final _show = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _show ? MediaQuery.of(context).size.height : 0,
      width: _show ? MediaQuery.of(context).size.width : 0,
      color: color,
    );
  }
}
