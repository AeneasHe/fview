// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'menu.dart';
import 'navigation.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(home: WebViewExample()));

const String htmlString = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport"
        content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <title>Amaze UI 在线调试</title>
  <link rel="stylesheet" href="http://cdn.amazeui.org/amazeui/2.5.0/css/amazeui.min.css"/>
</head>
<body>
  <button onclick="callFlutter()">callFlutter</button>
   <button onclick="callJS('hidden')">hide</button>
  <p id="p1" style="visibility:hidden;">
    Flutter 调用了 JS.
    Flutter 调用了 JS.
    Flutter 调用了 JS.
  </p>
<script src="http://code.jquery.com/jquery-2.1.4.min.js"></script>
<script src="http://cdn.amazeui.org/amazeui/2.5.0/js/amazeui.min.js"></script>
</body>
</html>



function callJS(message){
  document.getElementById("p1").style.visibility = message;
}

function callFlutter(){
  /*约定的url协议为：js://webview?arg1=111&arg2=222*/
  document.location = "js://webview?arg1=111&args2=222";
//   Toast.postMessage("JS调用了Flutter");
}
''';

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  //webview的控件
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter WebView example'),
        actions: <Widget>[
          NavigationControls(_controller.future), //导航工具栏
          SampleMenu(_controller.future), //菜单栏
        ],
      ),
      body: Builder(builder: (BuildContext context) {
        return WebView(
          //要显示的url
          // initialUrl: 'http://www.baidu.com',

          initialUrl:
              'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(htmlString))}',

          //JS执行模式
          javascriptMode: JavascriptMode.unrestricted,

          onWebViewCreated: (WebViewController webViewController) {
            //将webViewController绑定到_controller变量上
            _controller.complete(webViewController);
          },

          //执行js
          javascriptChannels: <JavascriptChannel>[
            _toasterJavascriptChannel(context),
          ].toSet(),

          //拦截请求
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('https')) {
              print('blocking navigation to $request}');
              Scaffold.of(context).showSnackBar(
                SnackBar(content: Text('拦截了 $request')),
              );
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },

          //页面开始加载执行
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          //页面加载完成执行
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          // gestureNavigationEnabled: true,
        );
      }),
      floatingActionButton: favoriteButton(), //悬浮按钮
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  Widget favoriteButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return FloatingActionButton(
              onPressed: () async {
                final String url = await controller.data.currentUrl();
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('Favorited $url')),
                );
              },
              child: const Icon(Icons.favorite),
            );
          }
          return Container();
        });
  }
}
