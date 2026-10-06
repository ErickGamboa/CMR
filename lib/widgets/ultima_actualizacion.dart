import 'dart:async';

import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../core/local/sincronizador.dart';

/// La línea discreta del Home que dice de cuándo son los datos.
///
/// Con la copia local, lo que se ve puede ser de hace horas si no hubo señal.
/// Eso no es un error, pero el paciente tiene que poder saberlo: si el doctor
/// le cambió el plan esta mañana y el teléfono no se enteró, que no lo tome
/// por el nuevo.
class UltimaActualizacion extends StatefulWidget {
  const UltimaActualizacion({super.key, this.sincronizador});

  /// Sin definir, el de la app. En los tests no hay ninguno y la línea no se
  /// dibuja.
  final Sincronizador? sincronizador;

  @override
  State<UltimaActualizacion> createState() => _UltimaActualizacionState();
}

class _UltimaActualizacionState extends State<UltimaActualizacion> {
  /// "Hace 5 min" deja de ser cierto solo, así que se vuelve a dibujar cada
  /// tanto.
  Timer? _reloj;

  Sincronizador? get _datos => widget.sincronizador ?? Sincronizador.actual;

  @override
  void initState() {
    super.initState();
    if (_datos != null) {
      _reloj = Timer.periodic(
        const Duration(seconds: 30),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datos = _datos;
    if (datos == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: datos,
      builder: (context, _) {
        final texto = _texto(datos);
        if (texto == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final color = theme.colorScheme.onSurfaceVariant;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                datos.sinConexion
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_done_outlined,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  texto,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _texto(Sincronizador datos) {
    final ultima = datos.ultimaVez;

    if (ultima == null) {
      // Primera vez: hasta que no baje algo no hay de cuándo hablar.
      if (datos.sinConexion) return 'Sin conexión';
      return datos.ocupado ? 'Actualizando…' : null;
    }

    final cuando = 'Actualizado ${formatearHace(ultima)}';
    return datos.sinConexion ? 'Sin conexión · $cuando' : cuando;
  }
}
