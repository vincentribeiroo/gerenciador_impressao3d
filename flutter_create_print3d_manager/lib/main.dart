import 'package:flutter/material.dart';
import 'telas/tela_calculadora.dart';
import 'telas/tela_filamentos.dart';
import 'telas/tela_produtos.dart';
import 'telas/tela_links_stl.dart';

void main() {
  runApp(const AppImpressao3D());
}

class AppImpressao3D extends StatelessWidget {
  const AppImpressao3D({super.key});

  @override
  Widget build(BuildContext context) {
    const preto = Color(0xFF111111);
    const branco = Color(0xFFFFFFFF);
    const vermelho = Color(0xFFD32F2F);

    return MaterialApp(
      title: 'Gestor Impressão 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: const ColorScheme.light(
          primary: vermelho,
          onPrimary: branco,
          secondary: preto,
          onSecondary: branco,
          surface: branco,
          onSurface: preto,
          error: vermelho,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: preto,
          foregroundColor: branco,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: branco,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: vermelho,
            foregroundColor: branco,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: vermelho,
          foregroundColor: branco,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: preto,
          indicatorColor: vermelho,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: branco, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return const IconThemeData(color: branco);
          }),
        ),
      ),
      home: const TelaNavegacaoPrincipal(),
    );
  }
}

class TelaNavegacaoPrincipal extends StatefulWidget {
  const TelaNavegacaoPrincipal({super.key});

  @override
  State<TelaNavegacaoPrincipal> createState() => _TelaNavegacaoPrincipalState();
}

class _TelaNavegacaoPrincipalState extends State<TelaNavegacaoPrincipal> {
  int _indiceAtual = 0;

  final List<Widget> _telas = const [
    TelaCalculadora(),
    TelaFilamentos(),
    TelaProdutos(),
    TelaLinksStl(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _telas[_indiceAtual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (indice) => setState(() => _indiceAtual = indice),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calculate), label: 'Calculadora'),
          NavigationDestination(icon: Icon(Icons.album), label: 'Filamentos'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.link), label: 'Links STL'),
        ],
      ),
    );
  }
}