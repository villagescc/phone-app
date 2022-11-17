import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.microphone.request();

  await Permission.mediaLibrary.request();

  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId('c63122cc-03be-4b63-b767-b581171e2966');
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print('accepted permission ${accepted}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VILLAGES.IO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyWebApp(),
    );
  }
}

class MyWebApp extends StatefulWidget {
  @override
  _MyWebAppState createState() => new _MyWebAppState();
}

class _MyWebAppState extends State<MyWebApp> {
  // static final oneSignalAppId = "c63122cc-03be-4b63-b767-b581171e2966";
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Villages.io"),
        actions: [
          IconButton(
            onPressed: () async {
              if (await webViewController!.canGoBack()) {
                webViewController?.goBack();
              } else {
                // ignore: deprecated_member_use
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('No back history item'),
                  duration: Duration(seconds: 3),
                ));
                // _scaffoldKey.currentState!.showSnackBar(const SnackBar(
                //   content: Text('No back history item'),
                //   duration: Duration(seconds: 3),
                // ));
                return;
              }
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          IconButton(
            onPressed: () async {
              if (await webViewController!.canGoForward()) {
                webViewController?.goForward();
              } else {
                // ignore: deprecated_member_use
                // _scaffoldKey.currentState!.showSnackBar(const SnackBar(
                //   content: Text('No forward history item'),
                //   duration: Duration(seconds: 3),
                // ));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('No forward history item'),
                  duration: Duration(seconds: 3),
                ));
                return;
              }
            },
            icon: const Icon(Icons.arrow_forward_ios),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_outlined),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text("Refresh"),
              ),
            ],
            onSelected: (index) {
              if (index == 1) {
                webViewController?.reload();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(
                        url: Uri.parse(
                            "https://villages.io/accounts/sign_in/log_in/")),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      var uri = navigationAction.request.url!;
                      print(uri.toString());
                      if (uri.toString().startsWith("https://instagram") ||
                          uri.toString().startsWith("https://mobile.twitter") ||
                          uri.toString().startsWith("https://t.me") ||
                          uri.toString().startsWith("https://m.youtube") ||
                          uri.toString().startsWith("https://github")) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                        return NavigationActionPolicy.CANCEL;
                      }
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
