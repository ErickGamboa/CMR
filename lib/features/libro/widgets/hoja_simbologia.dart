import 'package:flutter/material.dart';

import '../../../widgets/ocultar_teclado.dart';
import '../modelo_libro.dart';
import 'pildora_intercambio.dart';

/// Explica la simbología del libro.
///
/// En el papel esto es un cuadrito arriba de la primera página que nadie
/// vuelve a ver. Acá vive detrás del botón de ayuda del módulo, disponible en
/// cualquier momento, porque "1 C + ½ G" no se entiende sin ella.
class HojaSimbologia extends StatelessWidget {
  const HojaSimbologia({super.key});

  static Future<void> mostrar(BuildContext context) {
    OcultarTeclado.soltarFoco();
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const HojaSimbologia(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            // Ver la nota en HojaAlimento: sin estirar, la hoja queda angosta.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cómo leer el libro', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Cada alimento dice cuántos intercambios de cada grupo gasta '
                'la porción indicada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              for (final grupo in GrupoIntercambio.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      PildoraIntercambio(grupo: grupo, cantidad: 1),
                      const SizedBox(width: 12),
                      Text(grupo.etiqueta, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

              _Regla(
                titulo: '½',
                detalle: 'Medio intercambio, como en el libro impreso.',
              ),
              _Regla(
                titulo: 'ó',
                detalle:
                    'El alimento cuenta de una forma o de la otra, a tu '
                    'elección. El queso fresco cuenta 1 proteína ó 1 lácteo, '
                    'no las dos.',
              ),
              _Regla(
                titulo: '+ grasa*',
                detalle:
                    'La grasa depende de cómo se preparó el platillo, así '
                    'que el libro no le pone número.',
              ),
              _Regla(
                titulo: '30 g = 1 proteína',
                detalle: 'La medida base del grupo de proteínas.',
              ),
              _Regla(
                titulo: 'Alcohol',
                detalle:
                    'Se cuenta como grasa: por eso las bebidas '
                    'alcohólicas gastan intercambios de grasa.',
              ),
              _Regla(
                titulo: 'Alimentos libres',
                detalle:
                    'No gastan intercambios. Los que tienen condición la '
                    'llevan anotada.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Regla extends StatelessWidget {
  const _Regla({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
