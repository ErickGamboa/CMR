import 'package:flutter/material.dart';

import '../../../core/datos_demo.dart';

/// Banner superior del Home con la cita más próxima.
class TarjetaProximaCita extends StatelessWidget {
  const TarjetaProximaCita({
    super.key,
    required this.cita,
    required this.onTap,
  });

  final Cita cita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.primary,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 20,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRÓXIMA CITA',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.tertiary,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                formatearFechaLarga(cita.fecha),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _Detalle(
                icono: Icons.person_outline,
                texto: '${cita.profesional} · ${cita.especialidad}',
              ),
              const SizedBox(height: 4),
              _Detalle(icono: Icons.place_outlined, texto: cita.lugar),
            ],
          ),
        ),
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimary.withValues(alpha: 0.85);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
