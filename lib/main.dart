import 'package:flutter/material.dart';

void main() => runApp(const UniversalSshApp());

class UniversalSshApp extends StatelessWidget {
  const UniversalSshApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Universal SSH',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Universal SSH')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal, size: 72),
              SizedBox(height: 16),
              Text('Universal SSH', style: TextStyle(fontSize: 28)),
              SizedBox(height: 8),
              Text('Web • Android • Windows x64 • Xbox One'),
              SizedBox(height: 24),
              FilledButton(onPressed: null, child: Text('Nova conexão')),
            ],
          ),
        ),
      );
}
