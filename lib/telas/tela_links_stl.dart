import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../modelos/link_stl.dart';
import '../servicos/servico_armazenamento.dart';

class TelaLinksStl extends StatefulWidget {
  const TelaLinksStl({super.key});

  @override
  State<TelaLinksStl> createState() => _TelaLinksStlState();
}

class _TelaLinksStlState extends State<TelaLinksStl> {
  final _armazenamento = ServicoArmazenamento();
  final _buscaCtrl = TextEditingController();
  List<LinkStl> _links = [];
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final dados = await _armazenamento.obterLinks();
    setState(() => _links = dados);
  }

  List<LinkStl> get _linksFiltrados {
    if (_termoBusca.trim().isEmpty) return _links;
    final termo = _termoBusca.toLowerCase();
    return _links.where((item) {
      return item.titulo.toLowerCase().contains(termo) ||
          item.plataforma.toLowerCase().contains(termo) ||
          item.observacoes.toLowerCase().contains(termo) ||
          item.url.toLowerCase().contains(termo);
    }).toList();
  }

  Future<void> _abrirUrl(String urlBruta) async {
    final formatada =
        urlBruta.startsWith('http') ? urlBruta : 'https://$urlBruta';
    final uri = Uri.tryParse(formatada);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _abrirDialogoAdicionarLink() {
    final tituloCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar Link STL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome do Modelo (ex: Suporte Headset)'),
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                  labelText: 'URL (Printables, MakerWorld, etc.)'),
            ),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Observações (configuração, suporte...)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (tituloCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
              _links.insert(
                0,
                LinkStl(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  titulo: tituloCtrl.text.trim(),
                  url: urlCtrl.text.trim(),
                  observacoes: obsCtrl.text.trim(),
                ),
              );
              await _armazenamento.salvarLinks(_links);
              if (!mounted) return;
              Navigator.pop(ctx);
              _carregar();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaExibida = _linksFiltrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Links de Modelos STL')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirDialogoAdicionarLink,
        child: const Icon(Icons.add_link),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(
                hintText: 'Pesquisar modelo, site ou observação...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD32F2F)),
                suffixIcon: _termoBusca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _buscaCtrl.clear();
                          setState(() => _termoBusca = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: listaExibida.isEmpty
                ? Center(
                    child: Text(
                      _links.isEmpty
                          ? 'Nenhum link STL salvo.'
                          : 'Nenhum link encontrado para "$_termoBusca".',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listaExibida.length,
                    itemBuilder: (context, indice) {
                      final item = listaExibida[indice];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(item.titulo),
                          subtitle: Text(
                            '${item.plataforma}${item.observacoes.isNotEmpty ? ' • ${item.observacoes}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _abrirUrl(item.url),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  _links.removeWhere((l) => l.id == item.id);
                                  await _armazenamento.salvarLinks(_links);
                                  _carregar();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}