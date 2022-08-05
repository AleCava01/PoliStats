import 'dart:async';
import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';
import 'package:webview_flutter/webview_flutter.dart';

//--------------------------------------------------------------Main

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Welcome to Flutter'),
          ),
          body: WebViewExample()
      ),
    );
  }
}

//------------------------------------------------------------WebView and Scraper

class WebViewExample extends StatefulWidget {
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  final cookieManager = WebviewCookieManager();
  late WebViewController controller;
  final _titles = <String>[];


  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Startup Name Generator"),
        actions:[
          IconButton(
            onPressed: _pushSaved,
            icon: const Icon(Icons.list),
            tooltip: 'Saved Suggestions',
          ),
        ],
      ),
      body: _buildLogin(),
    );
  }
  void _pushSaved(){
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (context){
              return Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  title: const Text('Saved Suggestions'),
                ),
                body: _buildView(),
              );
            }
        )
    );
  }
  Future<void> collectCookies(url) async {
    final gotCookies = await cookieManager.getCookies(url);
    for (var item in gotCookies) {
      print(item);
    }
    print(url);
    print('-----------------------------');
    //final String cookies = await controller.runJavascriptReturningResult('document.cookie');
    //print(cookies);
  }
  Widget _buildLogin(){
    return WillPopScope(
      onWillPop: () async {
        if(await controller.canGoBack()) {
          controller.goBack();
        }
        return false;
      },
      child:Scaffold(
          appBar: AppBar(
            title: const Text('WebView'),
            actions: [
              IconButton(
                  onPressed: () async{
                    if(await controller.canGoBack()) {
                      controller.goBack();
                    }
                  },
                  icon: Icon(Icons.arrow_back)
              ),
              IconButton(
                  onPressed: () => controller.reload(),
                  icon:Icon(Icons.refresh)
              ),
            ],
          ),
          body: WebView(
            initialUrl: 'https://aunicalogin.polimi.it/aunicalogin/getservizio.xml?id_servizio=376&lang=IT',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              this.controller = controller;
            },
            onPageFinished: (String url) {
              if(url=="https://servizionline.polimi.it/portaleservizi/portaleservizi/controller/Portale.do?jaf_currentWFID=main&EVN_SHOW_PORTALE=evento"){
                print('sus');
                print('---------------------------------');

              }
              collectCookies(url);
            },
            gestureNavigationEnabled: true,
          )
      ),
    );
  }

  Future getWebsiteData(cookies,_url) async {
    final url = Uri.parse(_url);
    final response = await http.get(url);
    dom.Document html = dom.Document.html(response.body);

    final titles = html
        .querySelectorAll('h2 > a > span')
        .map((element)=>element.innerHtml.trim())
        .toList();

    print('Count: ${titles.length}');
    for (final title in titles){
      _titles.add(title);
      debugPrint(title);
    }
  }
  Widget _buildView(){
    return Text('WIP');
  }

}


