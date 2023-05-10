import 'package:flutter/material.dart';

import 'map/views/map_view.dart';

enum MainMenuStates { Map, Settings }

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String title = "Fluffy Maps";
  MainMenuStates selectedMenu = MainMenuStates.Map;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(child: Text("Fluffy Maps")),
            ListTile(
              title: Text("Map"),
              onTap: () {
                setState(() {
                  selectedMenu = MainMenuStates.Map;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Settings"),
              onTap: () {
                setState(() {
                  selectedMenu = MainMenuStates.Settings;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _getDrawerWidget(),
    );
  }

  _getDrawerWidget() {
    switch (selectedMenu) {
      case MainMenuStates.Map:
        return MapView();
      case MainMenuStates.Settings:
        return Container();
    }
  }
}
