import 'package:flutter/material.dart';

import '../modelo_libro.dart';
import 'pildora_intercambio.dart';

/// Una fila de la lista del libro: qué es, cuánto es y cuánto cuenta.
///
/// El nombre y la porción van a la izquierda y el conteo a la derecha, en la
/// misma posición en todas las filas, para que se pueda barrer la columna de
/// conteos con la vista sin leer los nombres.
class FilaAlimento extends StatelessWidget {
  const FilaAlimento({
    super.key,
    required this.alimento,
    required this.onTap,
    this.contexto,
  });

  final AlimentoLibro alimento;
  final VoidCallback onTap;

  /// "Lácteos · Yogurt". Se muestra solo cuando hay búsqueda, porque ahí la
  /// lista sale sin los encabezados de sección.
  final String? contexto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final detalle = [
      if (alimento.porcion != null) alimento.porcion!,
      if (alimento.marcas.isNotEmpty) alimento.marcas.join(', '),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contexto != null) ...[
                    Text(
                      contexto!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    alimento.nombre,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (detalle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      detalle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (alimento.nota != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alimento.nota!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 116,
              child: Align(
                alignment: Alignment.topRight,
                child: PildorasDeAlimento(alimento: alimento),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
