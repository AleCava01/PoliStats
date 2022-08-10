import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'studente.dart';
import 'sessione.dart';
import 'esame.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'webView.dart';

//--------------------------------------------------------------------------Main

void main() {
  runApp(PoliStats());
}

//-------------------------------------------------------------------Application

class PoliStats extends StatefulWidget {
  @override
  PoliStatsState createState() => PoliStatsState();
}

class PoliStatsState extends State<PoliStats> {
  final _studente= Studente.empty();
  final _esami = <Esame>{};
  final _sessioni = <Sessione>{};

  final _sites = <String>{
    'https://servizionline.polimi.it/portaleservizi/portaleservizi/controller/servizi/Servizi.do?evn_srv=evento&idServizio=2161',
  };

  bool isLoading =false;


  @override
  //--------------------------------------------------------------Update()
  Future<int> _update(BuildContext context) async{
    //1
    await _loadSessioni();
    //2
    bool sessionAreValid = await _testSessioni();
    print(sessionAreValid);
    if(!sessionAreValid){
      _pushWebView(context);
      return 1;
    }
    else{
      for(Sessione sessione in _sessioni){
        if(sessione.url.contains("www12.ceda.polimi.it/portale_carriera_studente")){
          List<String> tableRows= await _getWebsiteTableRows(sessione);
          int result = await _dataProcessor(tableRows);
          if(result==0){
            await _writeEsami();
            await _writeStudente();
          }
        }
      }
    }

    return 0;
  }
  //--------------------------------------------------------------Test Sessioni
  Future <bool> _testSessioni() async{
    if(_sessioni.isEmpty){
      return false;
    }
    var tableRows = await _getWebsiteTableRows(_sessioni.first);
    var tableText='';
    for(String row in tableRows){
      tableText+=row;
    }
    if(tableText.contains('Preferiti')){
      return true;
    }
    return false;
  }

  //-----------------------------------------------------------initState()
  @override
  void initState() {
    super.initState();
    // Enable virtual display.
    isLoading=true;
    _loadData();

    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }
  //----------------------------------------------------------build
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: Builder(
        builder: (context) => Center(
          child:Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text("PoliStats"),
                actions:[
                  IconButton(
                    onPressed: () {
                      _pushWebView(context);
                    },
                    icon: const Icon(Icons.web),
                    tooltip: 'Esami',
                  ),
                  IconButton(
                    onPressed: () {
                      _update(context);
                    },
                    icon: const Icon(Icons.update),
                    tooltip: 'WebView',
                  ),
                ],
              ),
              body: _loadingCheck(),
          )
        )
      )
    );
  }
  Widget _loadingCheck(){
    if(isLoading){
      return Text("Loading...");
    }
    else{
      return _buildHome();
    }
  }

  //-----------------------------------------------------------routing
  Future<void> _pushHomepage() async {
    var tableRows = await _getWebsiteTableRows(_sessioni.last);
    await _dataProcessor(tableRows);

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
  Future<void> _pushWebView(BuildContext context) async {
    print("pushing webview");
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => const SecondRoute(),
        ))
        .then((value) async {
          isLoading=true;
          await _update(context);
          await _loadData();
        });


  }
  //--------------------------------------------------------Login handling

  //-------------------------------------------------------getWebsiteData()
  Future<List<String>> _getWebsiteTableRows(Sessione sessione) async {
    List<String> tableRows = <String>[];
    http.Response response = await http.get(
        Uri.parse(sessione.url),
        headers: {'Cookie': sessione.cookie.toString()}
    );
    dom.Document document = parser.parse(response.body);
    for (dom.Element element in document.getElementsByTagName("tr")) {
      tableRows.add(element.text);
    }
    return tableRows;
  }
  //------------------------------------------------------_buildHome() v0
  Widget _buildHome(){
      return ListView(
        padding: const EdgeInsets.all(8),
        children: _buildList(),
      );
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

  }//----------------temp
  List<Widget> _buildList()  {
    var list = <Widget>[];
    list.clear();
    /*list.add(TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
      onPressed: () async {await _writeStudente(); },
      child: Text('Salva'),
    )
    );
    list.add(TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
      onPressed: () async {await _loadStudente(); },
      child: Text('Carica'),
    )
    );

    */
    list.add(TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
      ),
      onPressed: () async {await _clearAllData(); },
      child: Text('Erasa'),
    ));
    list.add(Text(_studente.nome));
    list.add(Text(_studente.cognome));
    list.add(Text(_studente.codicePersona));
    list.add(Text(_studente.corsoDiStudi.replaceAll('\n', ' ')));
    list.add(Text(_studente.matricola));
    list.add(Text("--------------------------------------"));
    for(Esame esame in _esami){
      list.add( Expanded(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Expanded(child: Text(esame.descrizione)) ,
            Expanded(child: Text(esame.voto)) ,
            Expanded(child: Text(esame.crediti)) ,
          ],
        )),
      );
    }
    list.add(Text("--------------------------------------"));
    for(Sessione sessione in _sessioni){
      list.add( Expanded(child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(child: Text(sessione.webId)) ,
          Expanded(child: Text(sessione.url)) ,
          Expanded(child: Text(sessione.cookie)) ,
        ],
      )),
      );
    }


    return list;
  } //--------temp
  //----------------------------------------------------dataProcessor() v1
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
  Future<int> _dataProcessor(List<String> tableRows) async{
    _esami.clear();
    for(String pasta in tableRows){
      if(pasta.contains("Stato esame")){
        await _examProcessor(pasta);
      }
    }
    await _studentProcessor(tableRows[1]+tableRows[3]);
    return 0;
  }
  //--------------------------------------------------------------Load Data

  Future<int> _loadData() async {
    await _loadEsami();
    await _loadStudente();
    isLoading=false;
    print("data loaded");
    return 0;
  }
  Future<int> _loadStudente() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonStudente = prefs.getString('studente_key') ?? '';
    if(jsonStudente==''){
      print("No data");
      return 1;
    }
    else{
      //print('Loaded json $jsonStudente');
      Map<String, dynamic> map = jsonDecode(jsonStudente);
      Studente studente = Studente.fromJson(map);
      _studente.nome=studente.nome;
      _studente.corsoDiStudi=studente.corsoDiStudi;
      _studente.codicePersona=studente.codicePersona;
      _studente.matricola=studente.matricola;
      _studente.email=studente.email;
      _studente.cognome=studente.cognome;
    }
    return 0;
  }
  Future<int> _loadEsami() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonEsami = prefs.getString('esami_key') ?? '';
    if(jsonEsami==''){
      print("No data");
      return 1;
    }
    else{
      Set<Esame> esami = Esame.decode(jsonEsami);
      //print(esami.first.descrizione);
      _esami.clear();
      for(Esame esame in esami){
        _esami.add(esame);
      }
    }
    return 0;
  }
  Future<int> _loadSessioni() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonSessioni = prefs.getString('sessioni_key') ?? '';
    if(jsonSessioni ==''){
      print("No data");
      return 1;
    }
    else{
      Set<Sessione> sessioni = Sessione.decode(jsonSessioni);
      //print(sessioni.first.url);
      _sessioni.clear();
      for(Sessione sessione in sessioni){
        _sessioni.add(sessione);
      }
    }
    return 0;
  }

  //-------------------------------------------------------------Write Data

  Future<int> _writeStudente() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonStudente = jsonEncode(_studente);
    print("Generated json studente $jsonStudente");
    prefs.setString('studente_key',jsonStudente);
    return 0;
  }
  Future<int> _writeEsami() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonEsami = Esame.encode(_esami);
    print("Generated json esami $jsonEsami");
    prefs.setString('esami_key',jsonEsami);
    return 0;
  }


  //--------------------------------------------------------------Clear data
  Future<int> _clearAllData() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    print("Data cleared");
    return 0;
  }


}
