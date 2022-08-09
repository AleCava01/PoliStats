import 'dart:convert';

class Esame{
  String descrizione;
  String semestre;
  String statoEsame;
  String crediti;
  String docenti;
  String dataEsame;
  String voto;

  Esame({required this.descrizione, required this.semestre, required this.statoEsame,required this.crediti,required this.docenti,required this.dataEsame,required this.voto});


  Map<String, dynamic> toJson(){
    return{
      'descrizione': descrizione,
      'semestre': semestre,
      'statoEsame': statoEsame,
      'crediti': crediti,
      'docenti': docenti,
      'dataEsame': dataEsame,
      'voto': voto,
    };
  }
  factory Esame.fromJson(Map<String,dynamic> json){
    return Esame(
      descrizione: json['descrizione'].toString(),
      semestre: json['semestre'].toString(),
      statoEsame: json['statoEsame'].toString(),
      crediti: json['crediti'].toString(),
      docenti: json['docenti'].toString(),
      dataEsame: json['dataEsame'].toString(),
      voto: json['voto'].toString(),
    );
  }
  static String encode(Set<Esame> esami) => json.encode(
    esami
        .map<Map<String, dynamic>>((esame) => esame.toJson())
        .toList(),
  );

  static Set<Esame> decode(String esami) =>
      (json.decode(esami) as List<dynamic>)
          .map<Esame>((item) => Esame.fromJson(item))
          .toSet();
}
