import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //# important utils
  late PullToRefreshController pullToRefreshController;
  double progress = 0.0;
  final urlController = TextEditingController();
  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      clearCache: true,
      allowFileAccessFromFileURLs: true,
      useOnDownloadStart: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
  );
  String? currentURL;
  final secureIcon = Icon(Icons.lock);
  final insecureIcon = Icon(Icons.lock_open);
  bool? isSecure = true;
  void showControllerDialog() {}

  Future<void> changeURL(var value) async {
    print(value);
    var url = Uri.parse(value);
    if (url.toString().startsWith("?")) {
      print(url.scheme);
      url = Uri.parse(
          "https://duckduckgo.com/?q=" + value.toString().substring(1));
      setState(() {
        isSecure = true;
      });
    }
    if (url.toString().startsWith("http://")) {
      isSecure = false;
    }
    if (!url.toString().startsWith("https://")) {
      url = Uri.https(url.toString(), "/");
      print(url);
    }
    await webViewController?.loadUrl(
      urlRequest: URLRequest(url: url),
    );
  }

  @override
  void initState() {
    super.initState();
    currentURL = "https://www.duckduckgo.com";
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        }
      },
    );
    isSecure = true;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    urlController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          topBar(context),
          progress < 1.00
              ? LinearProgressIndicator(value: progress, color: Colors.blue)
              : Container(),
          webPage(context),
        ],
      ),
    );
  }

  Widget topBar(BuildContext context) {
    return Flexible(
      flex: 1,
      child: Container(
        height: MediaQuery.of(context).size.height / 9,
        child: ColoredBox(
          color: Colors.grey.shade900,
          child: Row(
            textBaseline: TextBaseline.ideographic,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    webViewController!.loadUrl(
                      urlRequest: URLRequest(
                        url: Uri.parse(
                          "https://www.duckduckgo.com/",
                        ),
                      ),
                    );
                  });
                },
                icon: Icon(
                  Icons.home_filled,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: TextField(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(
                        () {
                          urlController.clear();
                        },
                      );
                    },
                    cursorColor: Colors.blue,
                    //textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: const BorderRadius.all(
                          const Radius.circular(12.0),
                        ),
                      ),
                      prefixIcon:
                          (isSecure == true) ? secureIcon : insecureIcon,
                      contentPadding: EdgeInsets.only(top: 16),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                    ),
                    controller: urlController,
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      print(value);
                    },
                    onSubmitted: (value) {
                      setState(() {
                        this.currentURL = value;
                        changeURL(value);
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.black,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(
                            16,
                          ),
                        ),
                      ),
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () async {
                              HapticFeedback.vibrate();
                              var bb = await webViewController!.canGoBack();
                              if (bb) {
                                webViewController!.goBack();
                              }
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.vibrate();
                              webViewController!.reload();
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.refresh_rounded),
                          ),
                          IconButton(
                            onPressed: () async {
                              HapticFeedback.vibrate();
                              var ff = await webViewController!.canGoForward();
                              if (ff) {
                                webViewController!.goForward();
                              }
                              Navigator.of(context).pop();
                            },
                            icon: Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget webPage(BuildContext context) {
    return Container(
      //height: double.infinity,
      child: Flexible(
        flex: 8,
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse(
              currentURL.toString(),
            ),
          ),
          initialOptions: options,
          onWebViewCreated: (controller) {
            webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(
              () {
                this.currentURL = url.toString();
                urlController.text = this.currentURL.toString();
              },
            );
          },
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(
              resources: resources,
              action: PermissionRequestResponseAction.GRANT,
            );
          },
          pullToRefreshController: pullToRefreshController,
          onProgressChanged: (controller, progress) {
            if (progress == 100) {
              pullToRefreshController.endRefreshing();
            }
            setState(
              () {
                this.progress = progress / 100;
                urlController.text = this.currentURL.toString();
              },
            );
          },
        ),
      ),
    );
  }
}
