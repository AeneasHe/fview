import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:oktoast/oktoast.dart';
import 'dart:convert';

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
<script>

function callJS(message){
  //供flutter调用的函数
  document.getElementById("p1").style.visibility = message;
  return message;
}

function callFlutter(){
  //1.通过url拦截调用，比如约定的url协议为：js://webview?arg1=111&arg2=222
  document.location = "js://webview?arg1=111&args2=222";

  //2.通过channel调用
  Toast.postMessage("JS调用了Flutte，哈哈");
}

</script>
</body>
</html>
''';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WebViewPage(),
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WebViewPageState();
  }
}

class WebViewPageState extends State<WebViewPage> {
  String url = "http://www.baidu.com";
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('地址 $url'),
      ),
      body: Builder(builder: (BuildContext context) {
        return WebView(
          initialUrl:
              'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(htmlString))}',
          javascriptMode: JavascriptMode.unrestricted,

          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },

          javascriptChannels: <JavascriptChannel>[
            _alertJavascriptChannel(context),
          ].toSet(),

          //url拦截
          navigationDelegate: (NavigationRequest request) {
            setState(() {
              url = request.url;
            });
            if (request.url.startsWith('js://webview')) {
              showToast('JS调用了Flutter 通过url拦截');
              print('blocking navigation to $request}');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to');
            return NavigationDecision.navigate;
          },

          onPageFinished: (String url) {
            print('Page finished loading');
          },
        );
      }),
      floatingActionButton: jsButton(),
    );
  }

  Widget jsButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return FloatingActionButton(
              onPressed: () async {
                _controller.future.then((controller) {
                  controller
                      .evaluateJavascript(
                          'callJS("visible")') //flutter按钮调用html页面的js函数
                      .then((result) {});
                });
              },
              child: Text('call JS'),
            );
          }
          return Container();
        });
  }

  //js channel
  JavascriptChannel _alertJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toast',
        onMessageReceived: (JavascriptMessage message) {
          print(message.message);
          showToast(message.message);
        });
  }
}
