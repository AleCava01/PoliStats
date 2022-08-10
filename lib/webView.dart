import 'dart:io';

import 'package:flutter/material.dart';
import 'package:poli_stats/sessione.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
class SecondRoute extends StatefulWidget {
  const SecondRoute({Key? key}) : super(key: key);

  @override
  State<SecondRoute> createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  final cookieManager = WebviewCookieManager();
  final _sessioni = <Sessione>{};
  late WebViewController controller;
  String initialUrl = 'https://aunicalogin.polimi.it/aunicalogin/getservizio.xml?id_servizio=376&lang=IT';
  int sessionId=0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            initialUrl: initialUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              this.controller = controller;
            },
            onPageFinished: (String url) async {
              if(url.compareTo('https://servizionline.polimi.it/portaleservizi/portaleservizi/controller/Portale.do?jaf_currentWFID=main&EVN_SHOW_PORTALE=evento')==0){
                await _grabSession(url);
                await _writeSessioni();
                controller.loadUrl('https://servizionline.polimi.it/portaleservizi/portaleservizi/controller/servizi/Servizi.do?evn_srv=evento&idServizio=2161');
              }
              String pageTitle= await controller.getTitle() ?? '';
              if(pageTitle == "Piano di studio"){
                await _grabSession(url);
                await _writeSessioni();
                Navigator.pop(context);

              }
            },
            gestureNavigationEnabled: true,
          )
      );
  }
  Future<void> _grabSession(String url) async {
    List<Cookie> cookies = <Cookie>[];
    final gotCookies = await cookieManager.getCookies(url);
    for (var item in gotCookies) {
      cookies.add(item);
    }
    _sessioni.add(Sessione(webId: sessionId.toString(),url: url, cookie:cookies.last.toString()));
    sessionId++;
    print("sessione aggiunta");
  }
  Future<int> _writeSessioni() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonSessioni = Sessione.encode(_sessioni);
    print("Generated json sessioni $jsonSessioni");
    prefs.setString('sessioni_key',jsonSessioni);
    return 0;
  }

}


