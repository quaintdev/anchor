import 'package:flutter/material.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'package:device_apps/device_apps.dart';
import 'package:search_page/search_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:android_intent/android_intent.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      home: MyHomePage(title: 'Anchor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var wallpaper;
  List<Application> apps = List();
  String todoData = "";

  @override
  initState() {
    super.initState();
    DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            onlyAppsWithLaunchIntent: true,
            includeSystemApps: true)
        .then((applications) {
      setState(() {
        apps = applications;
      });
    });
    _reloadTodo();
    // Get wallpaper as binary data
    LauncherAssist.getWallpaper().then((imageData) {
      setState(() {
        wallpaper = imageData;
      });
    });
  }

  _reloadTodo() {
    http.get("http://192.168.0.25:8008/todo.md").then((response) {
      print(response.statusCode);
      if (response.statusCode == 200) {
        setState(() {
          todoData = response.body.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 50.0),
        decoration: BoxDecoration(
          image: DecorationImage(
              image: MemoryImage(wallpaper),
              fit: BoxFit.cover), //todo: include an asset image
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Row(
                children: <Widget>[
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.dialpad),
                    onPressed: () {
                      DeviceApps.openApp("com.android.dialer");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.web),
                    onPressed: () {
                      DeviceApps.openApp("org.mozilla.fenix");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.camera_alt),
                    onPressed: () {
                      DeviceApps.openApp("com.oneplus.camera");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.music_note),
                    onPressed: () {
                      DeviceApps.openApp("com.spotify.music");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.attach_money),
                    onPressed: () {
                      DeviceApps.openApp("com.snapwork.hdfcsec");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      DeviceApps.openApp("com.android.settings");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      _reloadTodo();
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.file_copy),
                    onPressed: () {
                      DeviceApps.openApp("pl.solidexplorer2");
                    },
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.image),
                    onPressed: () {
                      DeviceApps.openApp("com.simplemobiletools.gallery.pro");
                    },
                  )
                ],
              ),
            ),
            Container(
              child: Markdown(
                shrinkWrap: true,
                data: todoData,
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey[800],
        tooltip: 'Search apps',
        onPressed: () => showSearch(
          context: context,
          delegate: SearchPage<Application>(
            showItemsOnEmpty: true,
            items: apps,
            searchLabel: 'Search app',
            suggestion: Center(
              child: Text('Filter apps'),
            ),
            failure: Center(
              child: Text('No app found :('),
            ),
            filter: (app) => [app.appName],
            builder: (app) {
              ApplicationWithIcon appWithIcon = app as ApplicationWithIcon;
              return ListTile(
                leading: Image.memory(appWithIcon.icon, width: 24.0),
                title: Text(app.appName),
                onTap: () {
                  DeviceApps.openApp(app.packageName);
                },
                onLongPress: (){
                  AndroidIntent intent = AndroidIntent(
                    action: "android.settings.APPLICATION_DETAILS_SETTINGS",
                    package: app.packageName,
                    data: "package:"+app.packageName,
                  );
                  intent.launch();
                },
              );
            },
          ),
        ),
        child: Icon(Icons.search),
      ),
    );
  }
}
