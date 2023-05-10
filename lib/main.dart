import 'package:fluffy_maps/map/views/map_view.dart';
import 'package:fluffy_maps/menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const FluffyMaps());
}

class FluffyMaps extends StatelessWidget {
  const FluffyMaps({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: MaterialApp(
      title: 'Fluffy Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainMenu(),
    ));
  }
}
