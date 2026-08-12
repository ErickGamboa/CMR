import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Marca el lugar donde va una foto real que todavía no tenemos.
///
/// Es deliberadamente evidente: si fuera un gris neutro se confundiría con una
/// imagen que no cargó, y nadie sabría que falta subirla.
class FotoPendiente extends StatelessWidget {
  const FotoPendiente({super.key, this.icono, this.alto});

  /// Ícono del contenido que irá acá. Sin él se usa el de imagen genérica.
  final IconData? icono;

  /// Alto fijo. Si es nulo, ocupa el que le den (p. ej. dentro de un Expanded).
  final double? alto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: alto,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        // El tamaño del ícono sale del espacio que realmente ocupa la caja, no
        // del alto pedido: dentro de un Expanded ese alto no se respeta y el
        // ícono se desbordaría.
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final lado = math.min(
              restricciones.maxWidth,
              restricciones.maxHeight,
            );
            return Center(
              child: Icon(
                icono ?? Icons.image_outlined,
                size: lado.isFinite ? (lado * 0.34).clamp(20.0, 56.0) : 40.0,
                color: scheme.primary.withValues(alpha: 0.55),
              ),
            );
          },
        ),
      ),
    );
  }
}
