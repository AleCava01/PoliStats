import 'dart:async';
import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';


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

//-------------------------------------------------------------------Oggetti
class Student{
  String codicePersona;
  String matricola;
  String nome;
  String cognome;
  String email;
  String corsoDiStudi;

  Student({required this.codicePersona, required this.matricola, required this.nome,required this.cognome,required this.email,required this.corsoDiStudi});
  changeCodicePersona(String newCodicePersona){
    codicePersona=newCodicePersona;
  }
}
class Esame{
  String descrizione;
  String semestre;
  String statoEsame;
  String crediti;
  String docenti;
  String dataEsame;
  String voto;

  Esame({required this.descrizione, required this.semestre, required this.statoEsame,required this.crediti,required this.docenti,required this.dataEsame,required this.voto});
}
//-------------------------------------------------------------------Application

class WebViewExample extends StatefulWidget {
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  final _studente=new Student(corsoDiStudi: '', nome: '', matricola: '', email: '', cognome: '', codicePersona: '');
  final _esami = <Esame>{};
  final _pastoneRows = <String>[];
  final cookieManager = WebviewCookieManager();
  late WebViewController controller;
  final _cookies = <Cookie>{};
  var _url = '';


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
          IconButton(
            onPressed: _pushWebView,
            icon: const Icon(Icons.star),
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
                body: _buildHome(),
              );
            }
        )
    );
  }
  Future<void> _pushWebView() async {
    await getWebsiteData();
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (context){
              return Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  title: const Text('Saved Suggestions'),
                ),
                body: _buildLogin(),
              );
            }
        )
    );
  }
  //-------------------------------------------------Login handler
  Future<void> collectCookies(String url) async {
    this._cookies.clear();
    final gotCookies = await cookieManager.getCookies(url);
    for (var item in gotCookies) {
      this._cookies.add(item);
    }
    this._url=url;
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
            initialUrl: 'https://servizionline.polimi.it/portaleservizi/portaleservizi/controller/servizi/Servizi.do?evn_srv=evento&idServizio=2161',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (controller) {
              this.controller = controller;
            },
            onPageFinished: (String url) {
              collectCookies(url);
            },
            gestureNavigationEnabled: true,
          )
      ),
    );
  }
  //-------------------------------------------------------Scraper
  Future<String> getFilePath() async {
    Directory appDocumentsDirectory = await getApplicationDocumentsDirectory(); // 1
    String appDocumentsPath = appDocumentsDirectory.path; // 2
    String filePath = '$appDocumentsPath/demoTextFile.txt'; // 3

    return filePath;
  }

  Future getWebsiteData() async {
    print("Scraping...");
    String headerCookie = '';
    int i=1;
    for(Cookie cookie in _cookies){
      if (i!=1){
        headerCookie += cookie.toString();
      }

    }
    http.Response response = await http.get(
        Uri.parse(_url),
        headers: {'Cookie': _cookies.last.toString()}
    );
    dom.Document document = parser.parse(response.body);
    File file = File(await getFilePath());
    for (dom.Element element in document.getElementsByTagName("tr")) {
      this._pastoneRows.add(element.text);
      //file.writeAsString(element.text);
      print('////////////////////////////////////////////////');
      print(element.text);
      print('////////////////////////////////////////////////');

    }
    await _dataProcessor();

  }
  void readFile() async {
    File file = File(await getFilePath()); // 1
    String fileContent = await file.readAsString(); // 2

    print('File Content: $fileContent');
  }
  Widget _buildHome(){
    if(_pastoneRows.isEmpty){
      return Text('Si è verificato un minchia di errore, si prega di riprovare a loggare');
    }
    else{
      print(_url);
      return Scaffold(
          appBar: AppBar(
            title: Text(_buildMedia()),
          ),
          body: ListView(
            padding: const EdgeInsets.all(8),
            children: _buildList(),
          ),
      );
    }
  }
  String _buildMedia(){
    double somma=0;
    double conta=0;
    for(Esame esame in _esami){
      double voto=0;
      double crediti=0;
      if(esame.voto=="30L"){voto=30;}
      if(esame.voto!="30L" && esame.voto.length>0){voto = double.parse(esame.voto);}
      if(esame.crediti.length>0){crediti=double.parse(esame.crediti);}
      if(voto!=0 && crediti!=0){
        somma+=voto*crediti;
        conta+=crediti;
      }

    }
    return (somma/conta).toStringAsFixed(2);

  }
  List<Widget> _buildList()  {
    var list = <Widget>[];
    list.clear();
    for(Esame esame in _esami){
      list.add( Container(
        height: 50,
        child: Center(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(esame.descrizione),
            Text(esame.voto),
            Text(esame.crediti),
          ],
        )),
      ));
    }
    return list;
  }
  Future<int> _studentProcessor(String pasta) async{
    final codicePersonaRegex = RegExp(r'[0-9]{8}');
    final nomeRegex = RegExp(r'[^\s][A -Z]{0,}');
    final emailRegex = RegExp(r"([-!#-'*+/-9=?A-Z^-~]+(\.[-!#-'*+/-9=?A-Z^-~]+)*|([]!#-[^-~ \t]|(\\[\t -~])))@[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?(\.[0-9A-Za-z]([0-9A-Za-z-]{0,61}[0-9A-Za-z])?)+");
    final matricolaRegex = RegExp(r'a[0-9]{6}');
    final corsoStudiRegex = RegExp(r'Corso di studi[a-zA-Z \-\(0-9\.\)]{0,}');

    String codicePersona=codicePersonaRegex.firstMatch(pasta)![0] ?? "not found";
    String cognome=nomeRegex.allMatches(pasta).elementAt(1)[0] ?? "not found";
    String nome=nomeRegex.allMatches(pasta).elementAt(2)[0] ?? "not found";
    String email=emailRegex.firstMatch(pasta)![0] ?? "not found";
    String matricola=matricolaRegex.firstMatch(pasta)![0] ?? "not found";
    matricola = matricola.substring(1,matricola.length);
    String corsoStudi=corsoStudiRegex.firstMatch(pasta)![0] ?? "not found";
    corsoStudi = corsoStudi.substring(14,corsoStudi.length);

    _studente.codicePersona=codicePersona;
    _studente.cognome=cognome;
    _studente.nome=nome;
    _studente.email=email;
    _studente.matricola=matricola;
    _studente.corsoDiStudi=corsoStudi;

    return 0;
  }
  Future<int> _examProcessor(String pasta) async{
    final votoRegex = RegExp(r'Voto[0-9]{0,2}L?');
    final creditiRegex = RegExp(r'Crediti[0-9.]{0,}');
    final dataEsameRegex = RegExp(r'Data esame\n[0-9-]{0,}');
    final descrizioneRegex = RegExp(r"Descrizione\n[a-zA-Z0-9\(\)', ]{0,}Corso");
    final statoEsameRegex = RegExp(r'Stato esame\n[A-Z]');
    final semestreRegex = RegExp(r'Semestre[\n?0-9]{0,}');
    final docentiRegex = RegExp(r"Docenti[\n?A-Za-z'0-9\(\), ]{0,}Data");

    String voto='';
    String crediti='';
    String dataEsame = '';
    String descrizione ='';
    String statoEsame='';
    String semestre='';
    String docenti='';


    voto=votoRegex.firstMatch(pasta)![0] ?? "not found";
    if(voto.length>4){voto = voto.substring(4,voto.length);}
    else{voto='';}
    crediti=creditiRegex.firstMatch(pasta)![0] ?? "not found";
    crediti = crediti.substring(7,crediti.length);
    dataEsame=dataEsameRegex.firstMatch(pasta)![0] ?? "not found";
    if(dataEsame.length>11){dataEsame = dataEsame.substring(11,dataEsame.length);}
    else{dataEsame='';}
    descrizione=descrizioneRegex.firstMatch(pasta)![0] ?? "not found";
    descrizione = descrizione.substring(12,descrizione.length-5);
    statoEsame=statoEsameRegex.firstMatch(pasta)![0] ?? "not found";
    if(statoEsame.length>11){statoEsame = statoEsame.substring(11,statoEsame.length);}
    else{statoEsame='';}
    semestre=semestreRegex.firstMatch(pasta)![0] ?? "not found";
    semestre = semestre.substring(semestre.length-1,semestre.length);
    docenti=docentiRegex.firstMatch(pasta)![0] ?? "not found";
    if(docenti.length>7){docenti = docenti.substring(7,docenti.length-4);}
    else{docenti='';}

    if(descrizione.length>0){
      Esame esame = new Esame(descrizione: descrizione,semestre: semestre,statoEsame: statoEsame,crediti: crediti,docenti: docenti,dataEsame: dataEsame,voto: voto);
      _esami.add(esame);
      return 0;
    }
    return 1;

  }
  Future<int> _dataProcessor() async{
    _esami.clear();
    for(String pasta in _pastoneRows){
      if(pasta.contains("Stato esame")){
        await _examProcessor(pasta);
      }
    }
    await _studentProcessor(_pastoneRows[1]+_pastoneRows[3]);
    _printEsami();
    return 0;
  }
  void _printEsami() {
    for(Esame esame in _esami){
      print(esame.descrizione);
    }
  }
  //------------------------------------------------------Boot load
  Widget _buildLoadingScreen(){
    return Text('loading...');
  }


}
