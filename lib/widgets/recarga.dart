import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Coordina "volver a bajar los datos" entre el botón y quien los carga.
///
/// El botón vive en la barra de la pantalla y los datos los pide un widget más
/// abajo, así que hacen falta dos cosas que viajen entre ellos: el aviso de
/// recargar y si hay algo en curso, para que el botón pueda girar mientras
/// tanto.
class ControlRecarga extends ChangeNotifier {
  int _generacion = 0;
  int _enCurso = 0;
  bool _vivo = true;

  /// Sube en cada recarga. Quien carga los datos la mira para saber que le
  /// toca volver a pedirlos.
  int get generacion => _generacion;

  bool get cargando => _enCurso > 0;

  void recargar() {
    if (!_vivo) return;
    _generacion++;
    notifyListeners();
  }

  void iniciar() {
    _enCurso++;
    _avisarDespues();
  }

  void terminar() {
    if (_enCurso > 0) _enCurso--;
    _avisarDespues();
  }

  /// Avisa, aplazando solo si hay un cuadro dibujándose.
  ///
  /// `iniciar` se llama desde el `initState` del widget que carga, y notificar
  /// en ese momento reconstruiría a un padre que todavía se está construyendo.
  /// Pero aplazar **siempre** haría que el botón tarde un cuadro de más en
  /// reaccionar cuando la carga arranca fuera de un build.
  void _avisarDespues() {
    if (!_vivo) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_vivo) notifyListeners();
      });
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    // El global no se libera: vive lo que vive la app. Si una pantalla lo
    // soltara al salir, el botón quedaría muerto en todas las demás y no se
    // notaría hasta que alguien lo tocara.
    assert(
      !identical(this, recargaGlobal),
      'El control global de recarga no se libera.',
    );

    _vivo = false;
    super.dispose();
  }
}

/// El control que comparte toda la app.
///
/// Recargar es una sola cosa. El paciente aprieta "actualizar" porque quiere
/// ver lo que el doctor le acaba de cargar, no porque quiera refrescar la
/// pantalla en la que está parado; si vuelve al inicio y sigue viendo el peso
/// viejo, el botón no hizo lo que decía.
///
/// Así que el control es uno solo y todas las pantallas montadas lo escuchan:
/// tocarlo en Laboratorios también vuelve a pedir el resumen del Home y lo que
/// haya detrás en la pila.
final recargaGlobal = ControlRecarga();

/// El botón de recargar que va en la barra superior.
///
/// Gira mientras baja los datos, porque un botón que no responde a simple
/// vista se lee como que no funcionó y la gente lo vuelve a tocar.
class BotonRecargar extends StatelessWidget {
  const BotonRecargar({super.key, required this.control});

  final ControlRecarga control;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: control,
      builder: (context, _) {
        final cargando = control.cargando;

        return IconButton(
          // Deshabilitado mientras carga: tocarlo de nuevo solo dispararía
          // otra consulta encima de la que ya viene en camino.
          onPressed: cargando ? null : control.recargar,
          tooltip: 'Actualizar',
          icon: _Girando(girando: cargando, child: const Icon(Icons.refresh)),
        );
      },
    );
  }
}

class _Girando extends StatefulWidget {
  const _Girando({required this.girando, required this.child});

  final bool girando;
  final Widget child;

  @override
  State<_Girando> createState() => _GirandoState();
}

class _GirandoState extends State<_Girando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.girando) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_Girando anterior) {
    super.didUpdateWidget(anterior);
    if (widget.girando && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.girando && _ctrl.isAnimating) {
      // Termina la vuelta en vez de cortarla a la mitad: un ícono que se
      // congela torcido parece un error.
      _ctrl.forward().whenComplete(_ctrl.reset);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _ctrl, child: widget.child);
  }
}
