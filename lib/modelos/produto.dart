class Produto {
  final String id;
  final String nome;
  final String infoFilamento;
  final double pesoGramas;
  final double horasImpressao;
  final double custoTotal;
  final double precoVenda;
  final double lucroEstimado;
  final DateTime criadoEm;

  Produto({
    required this.id,
    required this.nome,
    required this.infoFilamento,
    required this.pesoGramas,
    required this.horasImpressao,
    required this.custoTotal,
    required this.precoVenda,
    required this.lucroEstimado,
    required this.criadoEm,
  });

  Map<String, dynamic> paraJson() => {
        'id': id,
        'nome': nome,
        'infoFilamento': infoFilamento,
        'pesoGramas': pesoGramas,
        'horasImpressao': horasImpressao,
        'custoTotal': custoTotal,
        'precoVenda': precoVenda,
        'lucroEstimado': lucroEstimado,
        'criadoEm': criadoEm.toIso8601String(),
      };

  factory Produto.deJson(Map<String, dynamic> json) => Produto(
        id: json['id'],
        nome: json['nome'],
        infoFilamento: json['infoFilamento'],
        pesoGramas: (json['pesoGramas'] as num).toDouble(),
        horasImpressao: (json['horasImpressao'] as num).toDouble(),
        custoTotal: (json['custoTotal'] as num).toDouble(),
        precoVenda: (json['precoVenda'] as num).toDouble(),
        lucroEstimado: (json['lucroEstimado'] as num).toDouble(),
        criadoEm: DateTime.parse(json['criadoEm']),
      );
}