import 'package:flutter/material.dart';

import '../../core/datos/modelos.dart';
import '../../widgets/foto_pendiente.dart';

/// Marcas recomendadas por el doctor para un tipo de suplemento.
class MarcasScreen extends StatelessWidget {
  const MarcasScreen({super.key, required this.categoria});

  final CategoriaSuplemento categoria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(categoria.nombre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Marcas recomendadas por tu doctor',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final marca in categoria.marcas)
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FotoPendiente(icono: categoria.icono, alto: 150),
                    const SizedBox(height: 14),
                    Text(
                      marca.nombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      marca.presentacion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
