import 'package:fluffy_maps/map/map_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FluffyMaps());
}

class FluffyMaps extends StatelessWidget {
  const FluffyMaps({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluffy Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: MapView(),
      ),
    );
  }
}
