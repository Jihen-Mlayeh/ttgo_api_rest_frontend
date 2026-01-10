import 'package:flutter/material.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails Capteurs'),
      ),
      body: const Center(
        child: Text('Détails des capteurs - En construction'),
      ),
    );
  }
}