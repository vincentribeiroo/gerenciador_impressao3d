class LinkStl {
  final String id;
  final String titulo;
  final String url;
  final String observacoes;

  LinkStl({
    required this.id,
    required this.titulo,
    required this.url,
    this.observacoes = '',
  });

  String get plataforma {
    final minusculo = url.toLowerCase();
    if (minusculo.contains('makerworld')) return 'MakerWorld';
    if (minusculo.contains('printables')) return 'Printables';
    if (minusculo.contains('thingiverse')) return 'Thingiverse';
    if (minusculo.contains('cults3d')) return 'Cults3D';
    return 'Site Externo';
  }

  Map<String, dynamic> paraJson() => {
        'id': id,
        'titulo': titulo,
        'url': url,
        'observacoes': observacoes,
      };

  factory LinkStl.deJson(Map<String, dynamic> json) => LinkStl(
        id: json['id'],
        titulo: json['titulo'],
        url: json['url'],
        observacoes: json['observacoes'] ?? '',
      );
}