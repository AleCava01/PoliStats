import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart' as parser;
import 'package:webview_flutter/webview_flutter.dart';

//--------------------------------------------------------------------------Main

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: WebViewExample()
    );
  }
}

//-------------------------------------------------------------------Application

class WebViewExample extends StatefulWidget {
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  final _pastoneRows = <String>[];
  final cookieManager = WebviewCookieManager();
  late WebViewController controller;
  var _Cookies;
  var _url = '';
  final _titles = <String>[];


  @override
  //-------------------------------------------------------General
  void initState() {
    super.initState();
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("PoliStats"),
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
  Future<void> _pushSaved() async {
    await getWebsiteData();
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
  //-------------------------------------------------Login handler
  Future<void> collectCookies(String url) async {
    final gotCookies = await cookieManager.getCookies(url);
    for (var item in gotCookies) {
      print(item.toString());
    }
    print(url);
    print('-----------------------------');
    this._Cookies=gotCookies;
    this._url=url;

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
  //-------------------------------------------------------Scraper
  parseHtml() async {
    http.Response response = await http.get(
        Uri.parse(_url),
        headers: {'Cookie': _Cookies[1].toString()}
    );
    dom.Document document = parser.parse(response.body);
    print(document.body); // null

    for (dom.Element element in document.getElementsByTagName("tr")) {
      this._pastoneRows.add(element.text);
    }
  }
  Future getWebsiteData() async {
    print("Scraping...");
    parseHtml();
  }

  Widget _buildView(){
    return Scaffold(
      appBar: AppBar(
        title: Text(_url),
      ),
      body:Text(_pastoneRows[1],
      style: TextStyle(fontWeight: FontWeight.w800,fontSize: 16) )
    );
  }

}

