import 'package:flutter/material.dart';
import '../modelos/filamento.dart';
import '../modelos/produto.dart';
import '../servicos/servico_armazenamento.dart';

class _DadosImpressora {
  final double watts;
  final double preco;
  final double vidaUtilHoras;

  const _DadosImpressora({
    required this.watts,
    required this.preco,
    required this.vidaUtilHoras,
  });
}

class TelaCalculadora extends StatefulWidget {
  const TelaCalculadora({super.key});

  @override
  State<TelaCalculadora> createState() => _TelaCalculadoraState();
}

class _TelaCalculadoraState extends State<TelaCalculadora> {
  final _armazenamento = ServicoArmazenamento();
  final _nomeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController(text: '50');
  final _horasCtrl = TextEditingController(text: '2.5');
  final _wattsCtrl = TextEditingController(text: '100');
  final _precoImpressoraCtrl = TextEditingController(text: '3800');
  final _vidaUtilCtrl = TextEditingController(text: '2500');
  final _precoKwhCtrl = TextEditingController(text: '0.82');
  final _extrasCtrl = TextEditingController(text: '0');
  final _margemFalhaCtrl = TextEditingController(text: '15');
  final _margemLucroCtrl = TextEditingController(text: '100');

  // Modelos pré-definidos com consumo (W), preço médio (R$) e vida útil (h)
  final Map<String, _DadosImpressora?> _impressorasPredefinidas = {
    'Bambu Lab A1 (100W • R\$ 3.800)': const _DadosImpressora(
      watts: 100.0,
      preco: 3800.0,
      vidaUtilHoras: 2500.0,
    ),
    'Bambu Lab A1 Mini (75W • R\$ 2.500)': const _DadosImpressora(
      watts: 75.0,
      preco: 2500.0,
      vidaUtilHoras: 2500.0,
    ),
    'Bambu Lab P1S / X1C (120W • R\$ 6.500)': const _DadosImpressora(
      watts: 120.0,
      preco: 6500.0,
      vidaUtilHoras: 3000.0,
    ),
    'Creality Ender 3 V3 (130W • R\$ 1.800)': const _DadosImpressora(
      watts: 130.0,
      preco: 1800.0,
      vidaUtilHoras: 2000.0,
    ),
    'Creality K1 / K1C (200W • R\$ 3.600)': const _DadosImpressora(
      watts: 200.0,
      preco: 3600.0,
      vidaUtilHoras: 2500.0,
    ),
    'Outra / Personalizada': null,
  };

  // Tarifas residenciais/comerciais médias de Santa Catarina (com impostos)
  final Map<String, double?> _tarifasSantaCatarina = {
    'Celesc SC - Bandeira Verde (R\$ 0,82/kWh)': 0.82,
    'Celesc SC - Bandeira Amarela (R\$ 0,84/kWh)': 0.84,
    'Celesc SC - Bandeira Vermelha P1 (R\$ 0,87/kWh)': 0.87,
    'Celesc SC - Bandeira Vermelha P2 (R\$ 0,90/kWh)': 0.90,
    'Cooperativas SC / Rural (R\$ 0,72/kWh)': 0.72,
    'Tarifa Personalizada': null,
  };

  String _impressoraSelecionada = 'Bambu Lab A1 (100W • R\$ 3.800)';
  String _tarifaSelecionada = 'Celesc SC - Bandeira Verde (R\$ 0,82/kWh)';

  List<Filamento> _filamentos = [];
  Filamento? _filamentoSelecionado;
  bool _descontarDoEstoque = true;

  @override
  void initState() {
    super.initState();
    _carregarFilamentos();
  }

  Future<void> _carregarFilamentos() async {
    final lista = await _armazenamento.obterFilamentos();
    setState(() {
      _filamentos = lista;
      if (lista.isNotEmpty) _filamentoSelecionado = lista.first;
    });
  }

  double get _peso =>
      double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _horas =>
      double.tryParse(_horasCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _watts =>
      double.tryParse(_wattsCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _precoImpressora =>
      double.tryParse(_precoImpressoraCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _vidaUtilHoras =>
      double.tryParse(_vidaUtilCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _precoKwh =>
      double.tryParse(_precoKwhCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _extras =>
      double.tryParse(_extrasCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _taxaFalha =>
      double.tryParse(_margemFalhaCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _margemLucro =>
      double.tryParse(_margemLucroCtrl.text.replaceAll(',', '.')) ?? 0;

  double get _custoMaterial {
    final precoPorKg = _filamentoSelecionado?.precoPorKg ?? 100.0;
    return (_peso / 1000.0) * precoPorKg;
  }

  double get _custoEnergia => (_watts / 1000.0) * _horas * _precoKwh;

  // Desgaste por hora = (Preço da Impressora / Vida Útil) + 10%
  double get _desgastePorHora {
    if (_vidaUtilHoras <= 0) return 0.0;
    return (_precoImpressora / _vidaUtilHoras) * 1.10;
  }

  double get _custoDesgasteTotal => _desgastePorHora * _horas;

  double get _custoTotal {
    final base = _custoMaterial + _custoEnergia + _custoDesgasteTotal + _extras;
    return base * (1 + (_taxaFalha / 100.0));
  }

  double get _precoVenda => _custoTotal * (1 + (_margemLucro / 100.0));
  double get _lucroEstimado => _precoVenda - _custoTotal;
  double get _lucroPorHora => _horas > 0 ? _lucroEstimado / _horas : 0;

  // Avaliação de viabilidade da venda
  Map<String, dynamic> get _avaliacaoVenda {
    if (_lucroEstimado <= 0 || _custoTotal <= 0) {
      return {
        'vale': false,
        'titulo': 'NÃO VALE A PENA (PREJUÍZO)',
        'motivo': 'O preço de venda não cobre os custos de produção.',
        'corFundo': const Color(0xFFD32F2F),
        'corTexto': Colors.white,
        'icone': Icons.cancel,
      };
    }

    if (_margemLucro < 35 || _lucroPorHora < 4.0) {
      return {
        'vale': false,
        'titulo': 'NÃO VALE A PENA VENDER',
        'motivo': _lucroPorHora < 4.0
            ? 'Retorno de R\$ ${_lucroPorHora.toStringAsFixed(2)}/h é muito baixo para ocupar a impressora.'
            : 'Margem abaixo de 35%: qualquer falha ou taxa de plataforma gera prejuízo.',
        'corFundo': const Color(0xFFD32F2F),
        'corTexto': Colors.white,
        'icone': Icons.thumb_down_alt,
      };
    }

    if (_margemLucro < 70 || _lucroPorHora < 8.0) {
      return {
        'vale': true,
        'titulo': 'MARGEM APERTADA (SÓ VENDA DIRETA)',
        'motivo':
            'Rende R\$ ${_lucroPorHora.toStringAsFixed(2)}/h. Compensa no Pix/WhatsApp, mas evite marketplaces com comissão.',
        'corFundo': const Color(0xFF212121),
        'corTexto': Colors.white,
        'icone': Icons.warning_amber_rounded,
      };
    }

    return {
      'vale': true,
      'titulo': 'VALE MUITO A PENA VENDER!',
      'motivo':
          'Ótimo retorno de R\$ ${_lucroPorHora.toStringAsFixed(2)}/h com margem segura para imprevistos.',
      'corFundo': const Color(0xFF111111),
      'corTexto': Colors.white,
      'icone': Icons.verified,
    };
  }

  Future<void> _salvarProduto() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da peça/produto.')),
      );
      return;
    }

    final produtos = await _armazenamento.obterProdutos();
    final novoProduto = Produto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeCtrl.text.trim(),
      infoFilamento: _filamentoSelecionado != null
          ? '${_filamentoSelecionado!.marca} ${_filamentoSelecionado!.material} (${_filamentoSelecionado!.nomeCor})'
          : 'Filamento padrão (R\$ 100/kg)',
      pesoGramas: _peso,
      horasImpressao: _horas,
      custoTotal: _custoTotal,
      precoVenda: _precoVenda,
      lucroEstimado: _lucroEstimado,
      criadoEm: DateTime.now(),
    );

    produtos.insert(0, novoProduto);
    await _armazenamento.salvarProdutos(produtos);

    if (_descontarDoEstoque && _filamentoSelecionado != null && _peso > 0) {
      await _armazenamento.descontarEstoqueFilamento(
          _filamentoSelecionado!.id, _peso);
      await _carregarFilamentos();
    }

    if (!mounted) return;
    _nomeCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto salvo e estoque atualizado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacao = _avaliacaoVenda;

    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora 3D')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              labelText: 'Nome da Peça / Produto',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.view_in_ar, color: Color(0xFFD32F2F)),
            ),
          ),
          const SizedBox(height: 12),

          // Seletor de Impressora Pré-definida
          DropdownButtonFormField<String>(
            value: _impressoraSelecionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Impressora 3D',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.print, color: Color(0xFF111111)),
            ),
            items: _impressorasPredefinidas.keys.map((nome) {
              return DropdownMenuItem(
                value: nome,
                child: Text(nome, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor == null) return;
              setState(() {
                _impressoraSelecionada = valor;
                final dados = _impressorasPredefinidas[valor];
                if (dados != null) {
                  _wattsCtrl.text = dados.watts.toStringAsFixed(0);
                  _precoImpressoraCtrl.text = dados.preco.toStringAsFixed(0);
                  _vidaUtilCtrl.text = dados.vidaUtilHoras.toStringAsFixed(0);
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Preço da Impressora e Vida Útil (para cálculo de desgaste/hora + 10%)
          Row(
            children: [
              Expanded(
                child: _campoNumerico(
                  _precoImpressoraCtrl,
                  'Valor Impressora (R\$)',
                  aoAlterarManualmente: () =>
                      _impressoraSelecionada = 'Outra / Personalizada',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campoNumerico(
                  _vidaUtilCtrl,
                  'Vida Útil (horas)',
                  aoAlterarManualmente: () =>
                      _impressoraSelecionada = 'Outra / Personalizada',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Seletor de Tarifa de Santa Catarina
          DropdownButtonFormField<String>(
            value: _tarifaSelecionada,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tarifa Energia - Santa Catarina (SC)',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.bolt, color: Color(0xFFD32F2F)),
            ),
            items: _tarifasSantaCatarina.keys.map((nome) {
              return DropdownMenuItem(
                value: nome,
                child: Text(nome, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor == null) return;
              setState(() {
                _tarifaSelecionada = valor;
                final tarifa = _tarifasSantaCatarina[valor];
                if (tarifa != null) {
                  _precoKwhCtrl.text = tarifa.toStringAsFixed(2);
                }
              });
            },
          ),
          const SizedBox(height: 12),

          // Seletor de Filamento do Estoque
          DropdownButtonFormField<Filamento>(
            value: _filamentoSelecionado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filamento do Estoque',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _filamentos.map((f) {
              return DropdownMenuItem(
                value: f,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color(f.valorCor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${f.marca} ${f.material} - ${f.nomeCor} (${f.pesoRestanteGramas.toStringAsFixed(0)}g)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (valor) => setState(() => _filamentoSelecionado = valor),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _campoNumerico(_pesoCtrl, 'Peso (g)')),
              const SizedBox(width: 12),
              Expanded(child: _campoNumerico(_horasCtrl, 'Tempo (horas)')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _campoNumerico(
                  _wattsCtrl,
                  'Potência (W)',
                  aoAlterarManualmente: () =>
                      _impressoraSelecionada = 'Outra / Personalizada',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campoNumerico(
                  _precoKwhCtrl,
                  'Tarifa kWh (R\$)',
                  aoAlterarManualmente: () =>
                      _tarifaSelecionada = 'Tarifa Personalizada',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _campoNumerico(_extrasCtrl, 'Extras/Embalagem (R\$)')),
              const SizedBox(width: 12),
              Expanded(
                  child: _campoNumerico(_margemFalhaCtrl, 'Taxa Falha (%)')),
            ],
          ),
          const SizedBox(height: 12),
          _campoNumerico(_margemLucroCtrl, 'Margem de Lucro / Markup (%)'),
          const SizedBox(height: 16),

          // Card de Veredito: Vale ou Não Vale a Pena
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: avaliacao['corFundo'],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    avaliacao['vale'] ? const Color(0xFFD32F2F) : Colors.black,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  avaliacao['icone'],
                  color: avaliacao['vale']
                      ? const Color(0xFFEF5350)
                      : Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avaliacao['titulo'],
                        style: TextStyle(
                          color: avaliacao['corTexto'],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        avaliacao['motivo'],
                        style: TextStyle(
                          color: (avaliacao['corTexto'] as Color)
                              .withValues(alpha: 0.9),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card de Resumo Financeiro
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _linhaResultado(
                      'Material:', 'R\$ ${_custoMaterial.toStringAsFixed(2)}'),
                  _linhaResultado(
                      'Energia (SC):', 'R\$ ${_custoEnergia.toStringAsFixed(2)}'),
                  _linhaResultado(
                    'Desgaste (R\$ ${_desgastePorHora.toStringAsFixed(2)}/h + 10%):',
                    'R\$ ${_custoDesgasteTotal.toStringAsFixed(2)}',
                  ),
                  _linhaResultado(
                      'Extras / Embalagem:', 'R\$ ${_extras.toStringAsFixed(2)}'),
                  const Divider(height: 16),
                  _linhaResultado(
                    'Custo Total Produção:',
                    'R\$ ${_custoTotal.toStringAsFixed(2)}',
                    negrito: true,
                  ),
                  const Divider(height: 20),
                  _linhaResultado(
                    'Preço de Venda Sugerido:',
                    'R\$ ${_precoVenda.toStringAsFixed(2)}',
                    negrito: true,
                  ),
                  _linhaResultado(
                    'Lucro Líquido Estimado:',
                    'R\$ ${_lucroEstimado.toStringAsFixed(2)}',
                    negrito: true,
                    cor: const Color(0xFFD32F2F),
                  ),
                  _linhaResultado(
                    'Ganho por Hora de Máquina:',
                    'R\$ ${_lucroPorHora.toStringAsFixed(2)} / h',
                  ),
                ],
              ),
            ),
          ),

          if (_filamentoSelecionado != null)
            SwitchListTile(
              title: const Text('Descontar peso do estoque ao salvar'),
              activeThumbColor: const Color(0xFFD32F2F),
              value: _descontarDoEstoque,
              onChanged: (v) => setState(() => _descontarDoEstoque = v),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _salvarProduto,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Produto Calculado'),
          ),
        ],
      ),
    );
  }

  Widget _campoNumerico(
    TextEditingController ctrl,
    String rotulo, {
    VoidCallback? aoAlterarManualmente,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {
        aoAlterarManualmente?.call();
      }),
      decoration: InputDecoration(
        labelText: rotulo,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _linhaResultado(String rotulo, String valor,
      {bool negrito = false, Color? cor}) {
    final estilo = TextStyle(
      fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
      fontSize: negrito ? 16 : 14,
      color: cor ?? const Color(0xFF111111),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(rotulo, style: estilo)),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}