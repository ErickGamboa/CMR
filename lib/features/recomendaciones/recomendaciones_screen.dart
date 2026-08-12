import 'package:flutter/material.dart';

import '../../core/datos_demo.dart';

/// Recomendaciones que el doctor le dejó al paciente.
class RecomendacionesScreen extends StatelessWidget {
  const RecomendacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recomendaciones = DatosDemo.recomendaciones;

    if (recomendaciones.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recomendaciones')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Tu doctor todavía no te dejó recomendaciones.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recomendaciones')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'De tu doctor',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          for (final r in recomendaciones)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(r.icono, size: 22, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.titulo,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(r.texto, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 10),
                          Text(
                            formatearFechaBreve(r.fecha),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
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
