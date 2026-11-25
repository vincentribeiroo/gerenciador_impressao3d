import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../modelos/produto.dart';
import '../servicos/servico_armazenamento.dart';

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  final _armazenamento = ServicoArmazenamento();
  final _buscaCtrl = TextEditingController();
  List<Produto> _produtos = [];
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
    final dados = await _armazenamento.obterProdutos();
    setState(() => _produtos = dados);
  }

  List<Produto> get _produtosFiltrados {
    if (_termoBusca.trim().isEmpty) return _produtos;
    final termo = _termoBusca.toLowerCase();
    return _produtos.where((p) {
      return p.nome.toLowerCase().contains(termo) ||
          p.infoFilamento.toLowerCase().contains(termo);
    }).toList();
  }

  // Exporta todos os dados (Filamentos, Produtos e Links STL) para um arquivo .json
  Future<void> _exportarArquivoBackup() async {
    try {
      final jsonTexto = await _armazenamento.exportarBackupJson();
      final bytes = utf8.encode(jsonTexto);
      final dataFormatada = DateTime.now().toIso8601String().split('T').first;
      final nomeArquivo = 'backup_gestor_3d_$dataFormatada.json';

      final caminhoSalvo = await FilePicker.saveFile(
        dialogTitle: 'Salvar Backup Completo (JSON)',
        fileName: nomeArquivo,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (caminhoSalvo == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Arquivo de backup exportado com sucesso (filamentos, produtos e links)!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar arquivo: $e')),
      );
    }
  }

  // Seleciona o arquivo .json do computador/celular e restaura todos os dados
  Future<void> _importarArquivoBackup() async {
    try {
      final arquivos = await FilePicker.pickFiles(
        dialogTitle: 'Selecionar Arquivo de Backup (.json)',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (arquivos.isEmpty) return;

      final bytes = await arquivos.first.readAsBytes();
      final conteudoJson = utf8.decode(bytes);
      final resumo = await _armazenamento.importarBackupJson(conteudoJson);

      if (!mounted) return;
      await _carregar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup restaurado! ${resumo['filamentos']} filamentos, '
            '${resumo['produtos']} produtos e ${resumo['links']} links carregados.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD32F2F),
          content: Text(
              'Arquivo inválido! Selecione um documento .json gerado pelo Gestor 3D.'),
        ),
      );
    }
  }

  void _abrirMenuBackup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_zip, color: Color(0xFFD32F2F)),
            SizedBox(width: 8),
            Text('Backup em Documento'),
          ],
        ),
        content: const Text(
          'Exporte um arquivo .json com todos os seus filamentos, produtos salvos e links STL de uma só vez, ou importe um documento salvo anteriormente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _importarArquivoBackup();
            },
            icon: const Icon(Icons.upload_file, color: Color(0xFF111111)),
            label: const Text(
              'Importar Arquivo',
              style: TextStyle(color: Color(0xFF111111)),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _exportarArquivoBackup();
            },
            icon: const Icon(Icons.download),
            label: const Text('Exportar Tudo (.json)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaExibida = _produtosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos Salvos'),
        actions: [
          IconButton(
            tooltip: 'Exportar ou Importar Documento de Backup',
            icon: const Icon(Icons.folder_zip),
            onPressed: _abrirMenuBackup,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(
                hintText: 'Pesquisar produto ou filamento...',
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
                      _produtos.isEmpty
                          ? 'Nenhum produto salvo ainda.'
                          : 'Nenhum produto encontrado para "$_termoBusca".',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listaExibida.length,
                    itemBuilder: (context, indice) {
                      final p = listaExibida[indice];
                      final lucroHora = p.horasImpressao > 0
                          ? p.lucroEstimado / p.horasImpressao
                          : 0.0;
                      final margemPercentual = p.custoTotal > 0
                          ? (p.lucroEstimado / p.custoTotal) * 100
                          : 0.0;
                      final valeAPena = p.lucroEstimado > 0 &&
                          margemPercentual >= 35 &&
                          lucroHora >= 4.0;

                      return Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: valeAPena
                                      ? const Color(0xFF111111)
                                      : const Color(0xFFD32F2F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  valeAPena ? 'VALE A PENA' : 'NÃO VALE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${p.infoFilamento}\n'
                              'Peso: ${p.pesoGramas}g | Tempo: ${p.horasImpressao}h (R\$ ${lucroHora.toStringAsFixed(2)}/h)\n'
                              'Custo: R\$ ${p.custoTotal.toStringAsFixed(2)}  •  Venda: R\$ ${p.precoVenda.toStringAsFixed(2)}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+R\$ ${p.lucroEstimado.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: valeAPena
                                      ? const Color(0xFF111111)
                                      : const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Lucro',
                                  style: TextStyle(fontSize: 11)),
                            ],
                          ),
                          onLongPress: () async {
                            _produtos.removeWhere((item) => item.id == p.id);
                            await _armazenamento.salvarProdutos(_produtos);
                            _carregar();
                          },
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