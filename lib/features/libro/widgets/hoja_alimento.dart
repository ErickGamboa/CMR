import 'package:flutter/material.dart';

import '../modelo_libro.dart';
import 'pildora_intercambio.dart';

/// Detalle de un alimento.
///
/// Existe porque la fila de la lista tiene que ser corta y ahí el conteo va
/// abreviado ("1 C + 1 G"). Acá se dice con palabras —"1 carbohidrato +
/// 1 grasa"— y se muestra la porción en grande, que es el dato que la gente
/// viene a buscar: no "cuánto cuenta", sino "cuánto puedo comer".
class HojaAlimento extends StatelessWidget {
  const HojaAlimento({
    super.key,
    required this.alimento,
    required this.seccion,
  });

  final AlimentoLibro alimento;
  final SeccionLibro seccion;

  /// Abre la hoja desde la lista.
  static Future<void> mostrar(
    BuildContext context, {
    required AlimentoLibro alimento,
    required SeccionLibro seccion,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => HojaAlimento(alimento: alimento, seccion: seccion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ubicacion = [
      seccion.nombre,
      if (alimento.subseccion != null) alimento.subseccion!,
    ].join(' · ');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            // Estirado, no alineado al inicio: la hoja se abre con
            // `isScrollControlled`, así que toma el ancho de su contenido y sin
            // esto quedaría angosta, del ancho del texto más largo.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ubicacion,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(alimento.nombre, style: theme.textTheme.headlineSmall),

              if (alimento.marcas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final marca in alimento.marcas)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(marca, style: theme.textTheme.bodySmall),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              _Bloque(
                titulo: 'Porción',
                child: Text(
                  alimento.porcion ?? 'El libro no anota la porción',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: alimento.porcion == null
                        ? scheme.onSurfaceVariant
                        : null,
                    fontStyle:
                        alimento.porcion == null ? FontStyle.italic : null,
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _Bloque(
                titulo: alimento.alternativa == null
                    ? 'Te cuenta como'
                    : 'Te cuenta como (a elección)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alimento.libre && alimento.vale.vacio)
                      Text(
                        'Nada: es un alimento libre',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: scheme.secondary),
                      )
                    else ...[
                      _Conteo(intercambios: alimento.vale),
                      if (alimento.alternativa != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'o bien',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        _Conteo(intercambios: alimento.alternativa!),
                      ],
                    ],
                    if (alimento.grasaVariable) ...[
                      const SizedBox(height: 10),
                      Text(
                        '+ la grasa con que se preparó, que el libro no fija '
                        'porque depende de la receta',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),

              if (alimento.nota != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alimento.nota!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (seccion.nota != null) ...[
                const SizedBox(height: 14),
                Text(
                  seccion.nota!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Conteo extends StatelessWidget {
  const _Conteo({required this.intercambios});

  final Intercambios intercambios;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (grupo, cantidad) in intercambios.presentes)
          PildoraIntercambio(
            grupo: grupo,
            cantidad: cantidad,
            compacta: false,
          ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
