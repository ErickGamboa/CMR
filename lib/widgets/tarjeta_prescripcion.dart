import 'package:flutter/material.dart';

import '../core/datos/modelos.dart';

/// Muestra algo indicado por el doctor: suplemento, péptido o medicamento.
///
/// La dosis y la frecuencia van juntas y destacadas porque son el dato que el
/// paciente viene a consultar; el resto es contexto.
class TarjetaPrescripcion extends StatelessWidget {
  const TarjetaPrescripcion({
    super.key,
    required this.prescripcion,
    required this.icono,
  });

  final Prescripcion prescripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
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
              child: Icon(icono, size: 22, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescripcion.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Etiqueta(texto: prescripcion.dosis, destacada: true),
                      _Etiqueta(texto: prescripcion.frecuencia),
                    ],
                  ),
                  if (prescripcion.indicacion != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      prescripcion.indicacion!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, this.destacada = false});

  final String texto;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: destacada ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: destacada ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Text(
        texto,
        style: theme.textTheme.labelSmall?.copyWith(
          color: destacada ? scheme.onPrimary : scheme.onSurfaceVariant,
          fontWeight: destacada ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
