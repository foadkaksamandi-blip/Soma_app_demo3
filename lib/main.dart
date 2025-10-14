import 'package:flutter/material.dart';
void main() => runApp(const SomaApp());
class SomaApp extends StatelessWidget {
  const SomaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Soma Demo Ready')),
        body: const Center(child: Text('Base structure working ✅')),
      ),
    );
  }
}
