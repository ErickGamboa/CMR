import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/datos_demo.dart';
import '../../../theme/app_colors.dart';

/// Composición corporal de la última medición.
///
/// Sobre la forma: son dos magnitudes en la misma unidad y en un solo momento,
/// que además apuntan en sentidos opuestos —una baja, la otra sube—. Eso es un
/// gráfico divergente: un cero al centro y cada barra saliendo hacia su lado.
/// Una línea implicaría continuidad entre puntos que ya no se muestran.
///
/// Las barras comparten escala, así que sus largos se pueden comparar entre sí
/// directamente.
///
/// Sobre color: turquesa biocelular queda en 2.85:1 contra el fondo, por debajo
/// del mínimo de 3:1 para objetos gráficos. La paleta de marca es fija, así que
/// cada barra lleva su nombre y su valor escritos al lado y la identidad nunca
/// depende solo del color.
class ResumenSalud extends StatelessWidget {
  const ResumenSalud({super.key, required this.mediciones});

  final List<Medicion> mediciones;

  static const _colorGrasa = AppColors.azulAbisal;
  static const _colorMusculo = AppColors.turquesaBiocelular;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (mediciones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen de salud', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Todavía no hay mediciones registradas.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ultima = mediciones.last;
    // Un 12% de aire para que la barra más larga no toque el borde.
    final escala = math.max(ultima.grasaPerdida, ultima.musculoGanado) * 1.12;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de salud', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Última medición · ${formatearFechaBreve(ultima.fecha)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 26),
            _Metrica(
              nombre: 'Grasa perdida',
              valor: ultima.grasaPerdida,
              escala: escala,
              color: _colorGrasa,
              haciaLaIzquierda: true,
            ),
            const SizedBox(height: 28),
            _Metrica(
              nombre: 'Músculo ganado',
              valor: ultima.musculoGanado,
              escala: escala,
              color: _colorMusculo,
              haciaLaIzquierda: false,
            ),
            const SizedBox(height: 16),
            const _Eje(),
          ],
        ),
      ),
    );
  }
}

/// Una barra que sale del cero central hacia su lado, con el nombre y el valor
/// del mismo lado que la barra.
class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.nombre,
    required this.valor,
    required this.escala,
    required this.color,
    required this.haciaLaIzquierda,
  });

  static const _altoBarra = 40.0;

  final String nombre;
  final double valor;
  final double escala;
  final Color color;
  final bool haciaLaIzquierda;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final proporcion = escala == 0 ? 0.0 : (valor / escala).clamp(0.0, 1.0);

    final encabezado = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        // Flexible para que en pantallas angostas —o con la letra del sistema
        // en grande— el nombre ceda antes que desbordarse.
        Flexible(
          child: Text(
            nombre,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            text: valor.toStringAsFixed(1),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(
                text: ' kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // La barra crece al aparecer: hace evidente de qué lado del cero sale.
    final barra = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: proporcion),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, factor, _) => FractionallySizedBox(
        widthFactor: factor,
        alignment: haciaLaIzquierda
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          // La llave va acá y no en el FractionallySizedBox: ese ocupa todo el
          // ancho disponible, el que mide el valor es este.
          key: ValueKey('barra-$nombre'),
          height: _altoBarra,
          decoration: BoxDecoration(
            color: color,
            // Solo se redondea la punta exterior: el lado del cero queda recto
            // para que se lea que ahí arranca.
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(haciaLaIzquierda ? _altoBarra / 2 : 0),
              right: Radius.circular(haciaLaIzquierda ? 0 : _altoBarra / 2),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: haciaLaIzquierda
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        encabezado,
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: haciaLaIzquierda ? barra : const SizedBox(height: 1),
            ),
            Container(width: 2, height: _altoBarra + 8, color: scheme.outline),
            Expanded(
              child: haciaLaIzquierda ? const SizedBox(height: 1) : barra,
            ),
          ],
        ),
      ],
    );
  }
}

/// Rótulos de los extremos y el cero, para que quede claro qué significa cada
/// dirección sin tener que deducirlo.
class _Eje extends StatelessWidget {
  const _Eje();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(child: Text('Perdido', style: estilo)),
        Text('0', style: estilo),
        Expanded(
          child: Text('Ganado', style: estilo, textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
