class Filamento {
  final String id;
  final String marca;
  final String material; // PLA, PETG, ABS, TPU, ASA
  final String nomeCor;
  final int valorCor;
  final double precoPorKg;
  final double pesoInicialGramas;
  double pesoRestanteGramas;

  Filamento({
    required this.id,
    required this.marca,
    required this.material,
    required this.nomeCor,
    required this.valorCor,
    required this.precoPorKg,
    this.pesoInicialGramas = 1000.0,
    required this.pesoRestanteGramas,
  });

  double get percentualRestante =>
      (pesoRestanteGramas / pesoInicialGramas).clamp(0.0, 1.0);

  Map<String, dynamic> paraJson() => {
        'id': id,
        'marca': marca,
        'material': material,
        'nomeCor': nomeCor,
        'valorCor': valorCor,
        'precoPorKg': precoPorKg,
        'pesoInicialGramas': pesoInicialGramas,
        'pesoRestanteGramas': pesoRestanteGramas,
      };

  factory Filamento.deJson(Map<String, dynamic> json) => Filamento(
        id: json['id'],
        marca: json['marca'],
        material: json['material'],
        nomeCor: json['nomeCor'],
        valorCor: json['valorCor'],
        precoPorKg: (json['precoPorKg'] as num).toDouble(),
        pesoInicialGramas: (json['pesoInicialGramas'] as num).toDouble(),
        pesoRestanteGramas: (json['pesoRestanteGramas'] as num).toDouble(),
      );
}