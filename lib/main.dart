import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import 'package:webview_flutter/webview_flutter.dart';

String token = '';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.microphone.request();

  await Permission.mediaLibrary.request();

  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);
  OneSignal.shared.setAppId('c63122cc-03be-4b63-b767-b581171e2966');
  final accepted =
      await OneSignal.shared.promptUserForPushNotificationPermission();
  if (accepted) {
    final deviceState = await OneSignal.shared.getDeviceState();
    if (deviceState != null) {
      token = deviceState.userId ?? '';
    }
  }
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
      home: MyWebScreen(),
    );
  }
}

class MyWebScreen extends StatefulWidget {
  const MyWebScreen({super.key});

  @override
  State<MyWebScreen> createState() => _MyWebScreenState();
}

class _MyWebScreenState extends State<MyWebScreen> {
  late final WebViewController controller;
  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://villages.io'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Villages.io"),
        actions: [
          IconButton(
            onPressed: () async {
              if (await controller.canGoBack()) {
                controller.goBack();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('No back history item'),
                  duration: Duration(seconds: 3),
                ));
                return;
              }
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
          IconButton(
            onPressed: () async {
              if (await controller.canGoForward()) {
                controller.goForward();
              } else {
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
              // const PopupMenuItem(
              //   value: 2,
              //   child: Text("Copy"),
              // ),
              const PopupMenuItem(
                value: 3,
                child: Text("Share"),
              ),
            ],
            onSelected: (index) {
              if (index == 1) {
                controller.reload();
                // } else if (index == 2) {
                //   //copy current link to clipboard and show
                //   webViewController!.getUrl().then((value) {
                //     FlutterClipboard.copy(value.toString());
                //     ScaffoldMessenger.of(context)
                //         .showSnackBar(SnackBar(content: Text('Url copied')));
                //   });
              } else {
                //share link (share option)
                controller.currentUrl().then((value) {
                  Share.share(value.toString());
                });
              }
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

// class MyWebApp extends StatefulWidget {
//   @override
//   _MyWebAppState createState() => new _MyWebAppState();
// }

// class _MyWebAppState extends State<MyWebApp> {
//   // static final oneSignalAppId = "c63122cc-03be-4b63-b767-b581171e2966";
//   final GlobalKey webViewKey = GlobalKey();

//   InAppWebViewController? webViewController;
//   InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
//       crossPlatform: InAppWebViewOptions(
//           // useShouldOverrideUrlLoading: true,
//           // mediaPlaybackRequiresUserGesture: false,
//           ),
//       android: AndroidInAppWebViewOptions(
//         useHybridComposition: true,
//       ),
//       ios: IOSInAppWebViewOptions(
//         allowsInlineMediaPlayback: true,
//       ));

//   late PullToRefreshController pullToRefreshController;
//   String url = "";
//   double progress = 0;
//   final urlController = TextEditingController();
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   @override
//   void initState() {
//     super.initState();

//     pullToRefreshController = PullToRefreshController(
//       options: PullToRefreshOptions(
//         color: Colors.blue,
//       ),
//       onRefresh: () async {
//         if (Platform.isAndroid) {
//           webViewController?.reload();
//         } else if (Platform.isIOS) {
//           webViewController?.loadUrl(
//               urlRequest: URLRequest(url: await webViewController?.getUrl()));
//         }
//       },
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String myHandlerName = 'myHandlerName';
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: Text("Villages.io"),
//         actions: [
//           IconButton(
//             onPressed: () async {
//               if (await webViewController!.canGoBack()) {
//                 webViewController?.goBack();
//               } else {
//                 // ignore: deprecated_member_use
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   content: Text('No back history item'),
//                   duration: Duration(seconds: 3),
//                 ));
//                 // _scaffoldKey.currentState!.showSnackBar(const SnackBar(
//                 //   content: Text('No back history item'),
//                 //   duration: Duration(seconds: 3),
//                 // ));
//                 return;
//               }
//             },
//             icon: const Icon(Icons.arrow_back_ios),
//           ),
//           IconButton(
//             onPressed: () async {
//               if (await webViewController!.canGoForward()) {
//                 webViewController?.goForward();
//               } else {
//                 // ignore: deprecated_member_use
//                 // _scaffoldKey.currentState!.showSnackBar(const SnackBar(
//                 //   content: Text('No forward history item'),
//                 //   duration: Duration(seconds: 3),
//                 // ));
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   content: Text('No forward history item'),
//                   duration: Duration(seconds: 3),
//                 ));
//                 return;
//               }
//             },
//             icon: const Icon(Icons.arrow_forward_ios),
//           ),
//           PopupMenuButton(
//             icon: const Icon(Icons.more_vert_outlined),
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 1,
//                 child: Text("Refresh"),
//               ),
//               // const PopupMenuItem(
//               //   value: 2,
//               //   child: Text("Copy"),
//               // ),
//               const PopupMenuItem(
//                 value: 3,
//                 child: Text("Share"),
//               ),
//             ],
//             onSelected: (index) {
//               if (index == 1) {
//                 webViewController?.reload();
//                 // } else if (index == 2) {
//                 //   //copy current link to clipboard and show
//                 //   webViewController!.getUrl().then((value) {
//                 //     FlutterClipboard.copy(value.toString());
//                 //     ScaffoldMessenger.of(context)
//                 //         .showSnackBar(SnackBar(content: Text('Url copied')));
//                 //   });
//               } else {
//                 //share link (share option)
//                 webViewController!.getUrl().then((value) {
//                   Share.share(value.toString());
//                 });
//               }
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 children: [
//                   InAppWebView(
//                     key: webViewKey,
//                     initialUrlRequest:
//                         URLRequest(url: Uri.parse("https://villages.io")),
//                     initialOptions: options,
//                     pullToRefreshController: pullToRefreshController,
//                     onWebViewCreated: (controller) {
//                       webViewController = controller;
//                       controller.addJavaScriptHandler(
//                           handlerName: myHandlerName,
//                           callback: (args) {
//                             print('args${args}');
//                             return {
//                               'token': token,
//                             };
//                           });
//                     },
//                     onLoadStart: (controller, url) {
//                       setState(() {
//                         this.url = url.toString();
//                         urlController.text = this.url;
//                       });
//                     },
//                     androidOnPermissionRequest:
//                         (controller, origin, resources) async {
//                       return PermissionRequestResponse(
//                           resources: resources,
//                           action: PermissionRequestResponseAction.GRANT);
//                     },
//                     // shouldOverrideUrlLoading:
//                     //     (controller, navigationAction) async {
//                     //   var uri = navigationAction.request.url!;
//                     //   print(uri.toString());
//                     //   if (uri.toString().startsWith("https://instagram") ||
//                     //       uri.toString().startsWith("https://mobile.twitter") ||
//                     //       uri.toString().startsWith("https://t.me") ||
//                     //       uri.toString().startsWith("https://m.youtube") ||
//                     //       uri.toString().startsWith("https://github")) {
//                     //     await launchUrl(uri,
//                     //         mode: LaunchMode.externalApplication);
//                     //     return NavigationActionPolicy.CANCEL;
//                     //   }
//                     // },
//                     onLoadStop: (controller, url) async {
//                       pullToRefreshController.endRefreshing();
//                       setState(() {
//                         this.url = url.toString();
//                         urlController.text = this.url;
//                       });
//                     },
//                     onLoadError: (controller, url, code, message) {
//                       pullToRefreshController.endRefreshing();
//                     },
//                     onProgressChanged: (controller, progress) {
//                       if (progress == 100) {
//                         pullToRefreshController.endRefreshing();
//                       }
//                       setState(() {
//                         this.progress = progress / 100;
//                         urlController.text = this.url;
//                       });
//                     },
//                     onUpdateVisitedHistory: (controller, url, androidIsReload) {
//                       setState(() {
//                         this.url = url.toString();
//                         urlController.text = this.url;
//                       });
//                     },
//                     onConsoleMessage: (controller, consoleMessage) {
//                       print(consoleMessage);
//                     },
//                   ),
//                   progress < 1.0
//                       ? LinearProgressIndicator(value: progress)
//                       : Container(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
