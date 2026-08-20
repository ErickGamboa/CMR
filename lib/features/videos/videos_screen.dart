import 'package:flutter/material.dart';

import '../../widgets/aviso_pendiente.dart';

/// Módulo Videos.
///
/// A la espera del material: hay que definir cuáles videos van, de dónde se
/// sirven (YouTube, Vimeo o subidos a Supabase Storage) y si son los mismos
/// para todos los pacientes o dependen del plan.
class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Videos')),
      body: const AvisoPendiente(
        icono: Icons.play_circle_outline,
        mensaje: 'Se ocupan los videos y de dónde se van a servir',
      ),
    );
  }
}
