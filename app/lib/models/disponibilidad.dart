class Disponibilidad {
  const Disponibilidad({
    required this.id,
    required this.diaSemana,
    required this.nombreDia,
    required this.inicioMinutos,
    required this.finMinutos,
    required this.inicioHora,
    required this.finHora,
  });

  final int id;
  final int diaSemana;
  final String nombreDia;
  final int inicioMinutos;
  final int finMinutos;
  final String inicioHora;
  final String finHora;

  factory Disponibilidad.fromJson(Map<String, dynamic> json) {
    return Disponibilidad(
      id: json['id'] as int,
      diaSemana: json['dia_semana'] as int,
      nombreDia: json['nombre_dia'] as String,
      inicioMinutos: json['inicio_minutos'] as int,
      finMinutos: json['fin_minutos'] as int,
      inicioHora: json['inicio_hora'] as String,
      finHora: json['fin_hora'] as String,
    );
  }
}
