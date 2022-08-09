import 'dart:convert';

class Sessione{
  String url;
  String cookie;

  Sessione({required this.url,required this.cookie});

  Map<String, dynamic> toJson(){
    return{
      'url': url,
      'cookie': cookie,
    };
  }
  factory Sessione.fromJson(Map<String,dynamic> json){
    return Sessione(
      url: json['url'].toString(),
      cookie: json['cookie'].toString(),
    );
  }
  static String encode(List<Sessione> sessioni) => json.encode(
    sessioni
        .map<Map<String, dynamic>>((sessione) => sessione.toJson())
        .toList(),
  );

  static List<Sessione> decode(String sessioni) =>
      (json.decode(sessioni) as List<dynamic>)
          .map<Sessione>((item) => Sessione.fromJson(item))
          .toList();
}
