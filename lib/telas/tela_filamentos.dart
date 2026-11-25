import 'package:flutter/material.dart';
import '../modelos/filamento.dart';
import '../servicos/servico_armazenamento.dart';

class TelaFilamentos extends StatefulWidget {
  const TelaFilamentos({super.key});

  @override
  State<TelaFilamentos> createState() => _TelaFilamentosState();
}

class _TelaFilamentosState extends State<TelaFilamentos> {
  final _armazenamento = ServicoArmazenamento();
  final _buscaCtrl = TextEditingController();
  List<Filamento> _filamentos = [];
  String _termoBusca = '';

  final Map<String, Color> _coresPredefinidas = {
    'Preto': Colors.black87,
    'Branco': Colors.grey.shade200,
    'Cinza': Colors.grey,
    'Vermelho': Colors.red,
    'Azul': Colors.blue,
    'Verde': Colors.green,
    'Amarelo': Colors.amber,
    'Laranja': Colors.orange,
    'Roxo': Colors.purple,
  };

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
    final dados = await _armazenamento.obterFilamentos();
    setState(() => _filamentos = dados);
  }

  List<Filamento> get _filamentosFiltrados {
    if (_termoBusca.trim().isEmpty) return _filamentos;
    final termo = _termoBusca.toLowerCase();
    return _filamentos.where((f) {
      return f.marca.toLowerCase().contains(termo) ||
          f.material.toLowerCase().contains(termo) ||
          f.nomeCor.toLowerCase().contains(termo);
    }).toList();
  }

  // Diálogo unificado para Adicionar ou Editar filamento
  void _abrirDialogoFilamento({Filamento? filamentoExistente}) {
    final editando = filamentoExistente != null;
    final marcaCtrl = TextEditingController(
      text: editando ? filamentoExistente.marca : '',
    );
    final precoCtrl = TextEditingController(
      text: editando ? filamentoExistente.precoPorKg.toStringAsFixed(2) : '110',
    );
    final pesoRestanteCtrl = TextEditingController(
      text: editando
          ? filamentoExistente.pesoRestanteGramas.toStringAsFixed(0)
          : '1000',
    );
    final pesoTotalCtrl = TextEditingController(
      text: editando
          ? filamentoExistente.pesoInicialGramas.toStringAsFixed(0)
          : '1000',
    );

    final materiaisDisponiveis = ['PLA', 'PETG', 'ABS', 'TPU', 'ASA'];
    String materialSelecionado =
        editando && materiaisDisponiveis.contains(filamentoExistente.material)
            ? filamentoExistente.material
            : 'PLA';

    String corSelecionada =
        editando && _coresPredefinidas.containsKey(filamentoExistente.nomeCor)
            ? filamentoExistente.nomeCor
            : 'Preto';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, atualizarDialogo) => AlertDialog(
          title: Text(editando ? 'Editar Filamento' : 'Novo Filamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: marcaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Marca (ex: Voolt3D, eSUN, Bambu)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: materialSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(),
                  ),
                  items: materiaisDisponiveis
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      atualizarDialogo(() => materialSelecionado = v!),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cor do Filamento:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _coresPredefinidas.entries.map((entrada) {
                    final estaSelecionada = entrada.key == corSelecionada;
                    return ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: entrada.value),
                      label: Text(entrada.key),
                      selected: estaSelecionada,
                      selectedColor:
                          const Color(0xFFD32F2F).withValues(alpha: 0.2),
                      onSelected: (_) =>
                          atualizarDialogo(() => corSelecionada = entrada.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço por Kg (R\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: pesoRestanteCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              editando ? 'Saldo Atual (g)' : 'Peso Inicial (g)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (editando) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: pesoTotalCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Capacidade Rolo (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (marcaCtrl.text.trim().isEmpty) return;

                final pesoRestante = double.tryParse(
                        pesoRestanteCtrl.text.replaceAll(',', '.')) ??
                    1000.0;
                final pesoInicial = editando
                    ? (double.tryParse(
                            pesoTotalCtrl.text.replaceAll(',', '.')) ??
                        pesoRestante)
                    : pesoRestante;
                final preco =
                    double.tryParse(precoCtrl.text.replaceAll(',', '.')) ??
                        100.0;

                final filamentoAtualizado = Filamento(
                  id: editando
                      ? filamentoExistente.id
                      : DateTime.now().millisecondsSinceEpoch.toString(),
                  marca: marcaCtrl.text.trim(),
                  material: materialSelecionado,
                  nomeCor: corSelecionada,
                  valorCor: _coresPredefinidas[corSelecionada]!.toARGB32(),
                  precoPorKg: preco,
                  pesoInicialGramas:
                      pesoInicial < pesoRestante ? pesoRestante : pesoInicial,
                  pesoRestanteGramas: pesoRestante,
                );

                if (editando) {
                  final indice = _filamentos
                      .indexWhere((item) => item.id == filamentoExistente.id);
                  if (indice != -1) {
                    _filamentos[indice] = filamentoAtualizado;
                  }
                } else {
                  _filamentos.add(filamentoAtualizado);
                }

                await _armazenamento.salvarFilamentos(_filamentos);
                if (!mounted) return;
                Navigator.pop(ctx);
                _carregar();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editando
                        ? 'Filamento atualizado com sucesso!'
                        : 'Filamento adicionado ao estoque!'),
                  ),
                );
              },
              child: Text(editando ? 'Salvar Alterações' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo rápido para Repor Gramas no Estoque
  void _abrirDialogoReporEstoque(Filamento filamento) {
    final adicionarCtrl = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, atualizarDialogo) {
          final gramasAdicionar =
              double.tryParse(adicionarCtrl.text.replaceAll(',', '.')) ?? 0;
          final novoTotal = filamento.pesoRestanteGramas + gramasAdicionar;

          return AlertDialog(
            title: const Text('Repor Estoque'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${filamento.marca} • ${filamento.material} (${filamento.nomeCor})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saldo atual: ${filamento.pesoRestanteGramas.toStringAsFixed(0)}g',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [250, 500, 1000].map((qtd) {
                    return ActionChip(
                      label: Text('+${qtd}g'),
                      backgroundColor: const Color(0xFF111111),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onPressed: () {
                        atualizarDialogo(() {
                          adicionarCtrl.text = qtd.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adicionarCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => atualizarDialogo(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Gramas para adicionar (g)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add, color: Color(0xFFD32F2F)),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    'Novo saldo: ${novoTotal.toStringAsFixed(0)}g',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final qtd = double.tryParse(
                          adicionarCtrl.text.replaceAll(',', '.')) ??
                      0;
                  if (qtd <= 0) return;

                  final indice = _filamentos
                      .indexWhere((item) => item.id == filamento.id);
                  if (indice != -1) {
                    final saldoAtualizado =
                        filamento.pesoRestanteGramas + qtd;
                    final capacidadeAtualizada =
                        saldoAtualizado > filamento.pesoInicialGramas
                            ? saldoAtualizado
                            : filamento.pesoInicialGramas;

                    _filamentos[indice] = Filamento(
                      id: filamento.id,
                      marca: filamento.marca,
                      material: filamento.material,
                      nomeCor: filamento.nomeCor,
                      valorCor: filamento.valorCor,
                      precoPorKg: filamento.precoPorKg,
                      pesoInicialGramas: capacidadeAtualizada,
                      pesoRestanteGramas: saldoAtualizado,
                    );

                    await _armazenamento.salvarFilamentos(_filamentos);
                  }

                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _carregar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '+${qtd.toStringAsFixed(0)}g adicionados ao estoque!'),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirmar Reposição'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaExibida = _filamentosFiltrados;

    return Scaffold(
      appBar: AppBar(title: const Text('Estoque de Filamentos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirDialogoFilamento(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: (valor) => setState(() => _termoBusca = valor),
              decoration: InputDecoration(
                hintText: 'Pesquisar marca, material ou cor...',
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
                      _filamentos.isEmpty
                          ? 'Nenhum filamento cadastrado.'
                          : 'Nenhum filamento encontrado para "$_termoBusca".',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: listaExibida.length,
                    itemBuilder: (context, indice) {
                      final f = listaExibida[indice];
                      final estoqueBaixo = f.percentualRestante <= 0.20;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(f.valorCor),
                                    child: const Icon(Icons.album,
                                        color: Colors.white70),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${f.marca} • ${f.material} (${f.nomeCor})',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (estoqueBaixo)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFD32F2F),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'BAIXO',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Restante: ${f.pesoRestanteGramas.toStringAsFixed(0)}g / ${f.pesoInicialGramas.toStringAsFixed(0)}g • R\$ ${f.precoPorKg.toStringAsFixed(2)}/kg',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: f.percentualRestante,
                                color: estoqueBaixo
                                    ? const Color(0xFFD32F2F)
                                    : const Color(0xFF111111),
                                backgroundColor: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _abrirDialogoReporEstoque(f),
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 18, color: Color(0xFFD32F2F)),
                                    label: const Text(
                                      'Repor Gramas',
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _abrirDialogoFilamento(
                                        filamentoExistente: f),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Color(0xFF111111)),
                                    label: const Text(
                                      'Editar',
                                      style:
                                          TextStyle(color: Color(0xFF111111)),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir filamento',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.black54),
                                    onPressed: () async {
                                      _filamentos.removeWhere(
                                          (item) => item.id == f.id);
                                      await _armazenamento
                                          .salvarFilamentos(_filamentos);
                                      _carregar();
                                    },
                                  ),
                                ],
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