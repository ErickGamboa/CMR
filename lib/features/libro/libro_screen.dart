import 'package:flutter/material.dart';

import '../../widgets/aviso_pendiente.dart';

/// Módulo Libro. A la espera del material de Esteban.
class LibroScreen extends StatelessWidget {
  const LibroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Libro')),
      body: const AvisoPendiente(
        icono: Icons.menu_book_outlined,
        mensaje: 'Se ocupa libro de Esteban',
      ),
    );
  }
}
