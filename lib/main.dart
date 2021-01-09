import 'dart:async';
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
  List<ApplicationWithIcon> apps = List();
  String todoData = "", _quote = "";
  PermissionStatus storagePermissionStatus;
  bool isLoading = true;
  @override
  initState() {
    super.initState();
    _init();
  }

  _init() async {
    bool status = await Permission.storage.isRestricted;
    if (!status) {
      PermissionStatus permissionStatus = await Permission.storage.request();
      if (!permissionStatus.isGranted) {
        SystemNavigator.pop();
      }
    }
    _loadQuote();
    Future.wait([_loadWallpaper(), _loadApps(), _loadTodo()])
        .then((List response) {
      setState(() {
        wallpaper = response[0];
        todoData = response[2];
        isLoading = false;
      });
    });
  }

  Future<dynamic> _loadWallpaper() async {
    return await LauncherAssist.getWallpaper();
  }

  Future _loadApps() async {
    List<Application> appList = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        onlyAppsWithLaunchIntent: true,
        includeSystemApps: true);
    if (apps.length == 0) {
      appList.forEach((element) {
        apps.add(element as ApplicationWithIcon);
      });
    }
    apps.sort((a, b) => a.appName.compareTo(b.appName));
  }

  Future<String> _loadTodo() async {
    try {
      var response = await http
          .get("http://192.168.0.25:8008/todo.md")
          .timeout(Duration(seconds: 3), onTimeout: () {
        throw TimeoutException("error fetching todo");
      });
      if (response.statusCode == 200) {
        return response.body.toString();
      }
    } on TimeoutException catch (_) {
      SnackBar(content: Text("error fetching todo"));
    } on SocketException catch (_) {
      SnackBar(content: Text("error fetching todo"));
    }
    return "";
  }

  //fetch qotd from server
  _loadQuote() async {
    try {
      Socket socket = await Socket.connect('192.168.0.25', 1717)
          .timeout(Duration(seconds: 3), onTimeout: () {
        throw TimeoutException("error fetching quote");
      });
      socket.listen((List<int> event) {
        setState(() {
          _quote = utf8.decode(event).trim();
        });
      });
      socket.close();
    } on TimeoutException catch (_) {
      SnackBar(content: Text("error fetching quote"));
    } on SocketException catch (_) {
      SnackBar(content: Text("error fetching quote"));
    }
    return "";
  }

  String searchQuery = "";
  SearchPage<ApplicationWithIcon> _prepareSearchDelegate() {
    return SearchPage<ApplicationWithIcon>(
      showItemsOnEmpty: true,
      items: apps,
      onQueryUpdate: (query) => searchQuery = query,
      searchLabel: 'Search app',
      failure: Center(
        child: FlatButton(
          onPressed: () {
            AndroidIntent _playStoreIntent = AndroidIntent(
              action: "action_view",
              data: "market://search?q=" + searchQuery,
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
        return ListTile(
          leading: Image.memory(app.icon, width: 24.0),
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Scaffold(
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
                        Container(
                          padding: EdgeInsets.all(16.0),
                          alignment: Alignment.topCenter,
                          child: InkWell(
                            child: Text(
                              _quote,
                              style: TextStyle(color: Colors.white54),
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                    Stack(
                      children: [
                        Container(
                          color: Colors.black54,
                          child: Markdown(
                            shrinkWrap: true,
                            data: todoData,
                          ),
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
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.white24,
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
