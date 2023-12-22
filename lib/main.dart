// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
// #docregion platform_imports
// Import for Android features.
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        theme: ThemeData(
            appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      ),
    );

class WebViewpage extends StatefulWidget {
  const WebViewpage({super.key, required this.url});
  final String url;

  @override
  State<WebViewpage> createState() => _WebViewpageState();
}

class _WebViewpageState extends State<WebViewpage> {
  late final WebViewController _controller;
  bool isLoading = false;
  double value = 0;

  @override
  void initState() {
    super.initState();

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile View'),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
      ),
      body: isLoading
          ? const LinearProgressIndicator(
              color: Colors.blue,
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final formKey = GlobalKey<FormState>();
  final fcocusNode = FocusNode();
  RegExp urlRegex =
      RegExp(r"^(http|https):\/\/([\w\-]+\.)+[\w\-]+(\/[\w\- .\/?%&=]*)?$");
  final controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mobile Responsive"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 8,
            minLines: 1,
            focusNode: fcocusNode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Paste Your URL",
                suffixIcon: IconButton(
                    onPressed: () {
                      controller.clear();
                    },
                    icon: const Icon(Icons.cancel))),
            onFieldSubmitted: (d) {
              if (d.isNotEmpty) {
                final value = formKey.currentState?.validate();

                if (value!) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => WebViewpage(
                            url: d,
                          )));
                }
              }
            },
            validator: (f) {
              if (f == null) {
                return "Please Enter URL";
              } else {
                if (urlRegex.hasMatch(f)) {
                  return null;
                } else {
                  return "Please  Valid Enter URL";
                }
              }
            },
          ),
        ),
      )),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () {
          if (FocusScope.of(context).hasFocus) {
            fcocusNode.unfocus();
          }
          final value = formKey.currentState?.validate();
          if (value!) {
            if (controller.text.isNotEmpty) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WebViewpage(
                        url: controller.text,
                      )));
            }
          }
        },
        child: Icon(Icons.send),
      ),
    );
  }
}
