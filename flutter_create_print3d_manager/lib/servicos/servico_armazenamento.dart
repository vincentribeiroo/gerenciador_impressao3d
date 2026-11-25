import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/filamento.dart';
import '../modelos/produto.dart';
import '../modelos/link_stl.dart';

class ServicoArmazenamento {
  static const _chaveFilamentos = 'filamentos_v1';
  static const _chaveProdutos = 'produtos_v1';
  static const _chaveLinks = 'links_stl_v1';

  Future<List<Filamento>> obterFilamentos() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveFilamentos);
    if (bruto == null) return [];
    final List decodificado = jsonDecode(bruto);
    return decodificado.map((e) => Filamento.deJson(e)).toList();
  }

  Future<void> salvarFilamentos(List<Filamento> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveFilamentos,
      jsonEncode(lista.map((e) => e.paraJson()).toList()),
    );
  }

  Future<void> descontarEstoqueFilamento(
      String idFilamento, double gramasUsadas) async {
    final filamentos = await obterFilamentos();
    final indice = filamentos.indexWhere((f) => f.id == idFilamento);
    if (indice != -1) {
      filamentos[indice].pesoRestanteGramas =
          (filamentos[indice].pesoRestanteGramas - gramasUsadas)
              .clamp(0.0, 99999.0);
      await salvarFilamentos(filamentos);
    }
  }

  Future<List<Produto>> obterProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveProdutos);
    if (bruto == null) return [];
    final List decodificado = jsonDecode(bruto);
    return decodificado.map((e) => Produto.deJson(e)).toList();
  }

  Future<void> salvarProdutos(List<Produto> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveProdutos,
      jsonEncode(lista.map((e) => e.paraJson()).toList()),
    );
  }

  Future<List<LinkStl>> obterLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chaveLinks);
    if (bruto == null) return [];
    final List decodificado = jsonDecode(bruto);
    return decodificado.map((e) => LinkStl.deJson(e)).toList();
  }

  Future<void> salvarLinks(List<LinkStl> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chaveLinks,
      jsonEncode(lista.map((e) => e.paraJson()).toList()),
    );
  }

  Future<String> exportarBackupJson() async {
    final filamentos = await obterFilamentos();
    final produtos = await obterProdutos();
    final links = await obterLinks();

    final dados = {
      'versao': 1,
      'exportadoEm': DateTime.now().toIso8601String(),
      'filamentos': filamentos.map((e) => e.paraJson()).toList(),
      'produtos': produtos.map((e) => e.paraJson()).toList(),
      'links': links.map((e) => e.paraJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(dados);
  }

  Future<Map<String, int>> importarBackupJson(String jsonTexto) async {
    final decodificado = jsonDecode(jsonTexto);
    if (decodificado is! Map<String, dynamic>) {
      throw const FormatException('Formato de backup inválido.');
    }

    if (!decodificado.containsKey('filamentos') &&
        !decodificado.containsKey('produtos') &&
        !decodificado.containsKey('links')) {
      throw const FormatException(
          'O texto colado não contém dados válidos do Gestor 3D.');
    }

    final listaFilamentos = (decodificado['filamentos'] as List? ?? [])
        .map((e) => Filamento.deJson(Map<String, dynamic>.from(e)))
        .toList();

    final listaProdutos = (decodificado['produtos'] as List? ?? [])
        .map((e) => Produto.deJson(Map<String, dynamic>.from(e)))
        .toList();

    final listaLinks = (decodificado['links'] as List? ?? [])
        .map((e) => LinkStl.deJson(Map<String, dynamic>.from(e)))
        .toList();

    await salvarFilamentos(listaFilamentos);
    await salvarProdutos(listaProdutos);
    await salvarLinks(listaLinks);

    return {
      'filamentos': listaFilamentos.length,
      'produtos': listaProdutos.length,
      'links': listaLinks.length,
    };
  }
}