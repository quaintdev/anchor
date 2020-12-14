import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launcher_assist/launcher_assist.dart';
import 'package:device_apps/device_apps.dart';
import 'package:search_page/search_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:android_intent/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

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
  String todoData = "", _quote = "";
  PermissionStatus storagePermissionStatus;

  @override
  initState() {
    super.initState();
    Permission.storage.isRestricted.then((result) {
      if (!result) {
        Permission.storage.request().then((permissionStatus) {
          if (permissionStatus.isGranted) {
            storagePermissionStatus = permissionStatus;
          } else {
            SystemNavigator.pop();
          }
        });
      }
    });
    _loadQuote();
    Future.wait([_loadWallpaper(), _loadApps(), _loadTodo()])
        .then((List response) {
      setState(() {
        todoData = response[2];
      });
    });
  }

  Future _loadWallpaper() async {
    if (storagePermissionStatus.isGranted)
      wallpaper = await LauncherAssist.getWallpaper();
  }

  Future _loadApps() async {
    apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true);
    apps.sort((a, b) => a.appName.compareTo(b.appName));
  }

  Future<String> _loadTodo() async {
    var response = await http.get("http://192.168.0.25:8008/todo.md");
    if (response.statusCode == 200) {
      return response.body.toString();
    }
    return "";
  }

  //fetch qotd from server
  _loadQuote() async {
    Socket socket = await Socket.connect('192.168.0.25', 1717);
    socket.listen((List<int> event) {
      setState(() {
        _quote = utf8.decode(event).trim();
      });
    });
    socket.close();
    return "";
  }

  SearchPage<Application> _searchDelegate;
  SearchPage<Application> _prepareSearchDelegate() {
    _searchDelegate = SearchPage<Application>(
      showItemsOnEmpty: true,
      items: apps,
      searchLabel: 'Search app',
      suggestion: Center(
        child: Text('Filter apps'),
      ),
      failure: Center(
        child: FlatButton(
          onPressed: () {
            AndroidIntent _playStoreIntent = AndroidIntent(
              action: "action_view",
              data: "market://search?q=" + _searchDelegate.query,
            );
            _playStoreIntent.launch();
            Navigator.of(context).maybePop();
          },
          color: Colors.blue,
          child: Text("Open in play store"),
        ),
      ),
      filter: (app) => [app.appName],
      builder: (app) {
        ApplicationWithIcon appWithIcon = app as ApplicationWithIcon;
        return ListTile(
          leading: Image.memory(appWithIcon.icon, width: 24.0),
          title: Text(app.appName),
          onTap: () {
            DeviceApps.openApp(app.packageName);
            Navigator.of(context).maybePop();
          },
          onLongPress: () {
            AndroidIntent intent = AndroidIntent(
              action: "android.settings.APPLICATION_DETAILS_SETTINGS",
              package: app.packageName,
              data: "package:" + app.packageName,
            );
            intent.launch();
          },
        );
      },
    );
    return _searchDelegate;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.only(top: 50.0),
          decoration: wallpaper != null
              ? BoxDecoration(
                  image: DecorationImage(
                      image: MemoryImage(wallpaper), fit: BoxFit.cover),
                )
              : BoxDecoration(),
          child: PageView(
            children: [
              Stack(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.topCenter,
                      child: InkWell(
                        child: Text(
                          _quote,
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          _loadQuote().then((result) {
                            setState(() {
                              _quote = result;
                            });
                          });
                        },
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          Future.wait([_loadWallpaper(), _loadApps()])
                              .then((List response) {
                            setState(() {});
                          });
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
                        icon: Icon(Icons.settings),
                        onPressed: () {
                          DeviceApps.openApp("com.android.settings");
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
                          DeviceApps.openApp(
                              "com.simplemobiletools.gallery.pro");
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
                        icon: Icon(Icons.music_note),
                        onPressed: () {
                          DeviceApps.openApp("com.spotify.music");
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
                        icon: Icon(Icons.dialpad),
                        onPressed: () {
                          DeviceApps.openApp("com.android.dialer");
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                color: Colors.black54,
                child: Stack(
                  children: [
                    Markdown(
                      shrinkWrap: true,
                      data: todoData,
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          _loadTodo().then((response) {
                            setState(() {
                              todoData = response;
                            });
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white70,
          tooltip: 'Search apps',
          onPressed: () => showSearch(
            context: context,
            delegate: _prepareSearchDelegate(),
          ),
          child: Icon(Icons.search),
        ),
      ),
    );
  }
}

//todo add eventlistener for fingeprint key
