import 'package:flutter/material.dart';

/// Bloque para un contenido que todavía no existe y depende de alguien más.
///
/// A diferencia de un "próximamente" genérico, dice qué falta exactamente,
/// para que al verlo se sepa a quién hay que pedírselo.
class AvisoPendiente extends StatelessWidget {
  const AvisoPendiente({
    super.key,
    required this.icono,
    required this.mensaje,
  });

  final IconData icono;
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              mensaje,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Pendiente',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
