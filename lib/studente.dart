class Studente{
  late String codicePersona;
  late String matricola;
  late String nome;
  late String cognome;
  late String email;
  late String corsoDiStudi;

  Studente({required this.codicePersona, required this.matricola, required this.nome,required this.cognome,required this.email,required this.corsoDiStudi});

  Studente.empty(){
    this.codicePersona='';
    this.matricola='';
    this.nome='';
    this.cognome='';
    this.email='';
    this.corsoDiStudi='';
  }

  Map<String, dynamic> toJson(){
    return{
      'codicePersona': codicePersona,
      'matricola': matricola,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'corsoDiStudi': corsoDiStudi,
    };
  }
  factory Studente.fromJson(Map<String,dynamic> json){
    return Studente(
        codicePersona: json['codicePersona'].toString(),
        matricola: json['matricola'].toString(),
        nome: json['nome'].toString(),
        cognome: json['cognome'].toString(),
        email: json['email'].toString(),
        corsoDiStudi: json['corsoDiStudi'].toString()
    );
  }
}