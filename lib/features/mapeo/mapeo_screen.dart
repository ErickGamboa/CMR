import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/fechas.dart';
import '../../widgets/ocultar_teclado.dart';
import 'modelo_mapeo.dart';
import 'repositorio_mapeo.dart';

/// Módulo Mapeo: lo que el paciente se mide en casa, día por día.
///
/// El doctor lo prende paciente por paciente, así que no todos lo ven en el
/// Home. Los valores van como texto libre: la gente escribe "120/80",
/// "120 - 80" o "95 en ayunas", y lo que importa es que el doctor lea
/// exactamente lo que el aparato dijo.
class MapeoScreen extends StatefulWidget {
  const MapeoScreen({super.key, this.fuente});

  /// De dónde se lee y dónde se guarda. En la app va sin definir y sale de
  /// Supabase; los tests inyectan una fuente falsa.
  final FuenteMapeo? fuente;

  @override
  State<MapeoScreen> createState() => _MapeoScreenState();
}

class _MapeoScreenState extends State<MapeoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(
    length: TipoMapeo.values.length,
    vsync: this,
  )..addListener(OcultarTeclado.soltarFoco);

  @override
  void dispose() {
    _pestanas.removeListener(OcultarTeclado.soltarFoco);
    _pestanas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapeo'),
        bottom: TabBar(
          controller: _pestanas,
          tabs: [for (final t in TipoMapeo.values) Tab(text: t.etiqueta)],
        ),
      ),
      body: TabBarView(
        controller: _pestanas,
        children: [
          for (final t in TipoMapeo.values)
            _Pestana(tipo: t, fuente: widget.fuente),
        ],
      ),
    );
  }
}

/// Una de las dos mediciones, con su propio historial y su día seleccionado.
class _Pestana extends StatefulWidget {
  const _Pestana({required this.tipo, required this.fuente});

  final TipoMapeo tipo;
  final FuenteMapeo? fuente;

  @override
  State<_Pestana> createState() => _PestanaState();
}

class _PestanaState extends State<_Pestana> with AutomaticKeepAliveClientMixin {
  FuenteMapeo? _fuente;
  late Future<List<RegistroMapeo>> _carga = _cargar();

  /// El historial ya cargado, indexado por día, para cambiar de fecha sin
  /// volver a pedirle nada al servidor.
  final Map<String, RegistroMapeo> _porDia = {};

  late DateTime _dia = RegistroMapeo.soloDia(DateTime.now());

  final _campos = {
    for (final m in MomentoMapeo.values) m: TextEditingController(),
  };

  bool _sucio = false;
  bool _guardando = false;

  @override
  bool get wantKeepAlive => true;

  /// La fuente se resuelve dentro del `async` a propósito: si Supabase no
  /// está inicializado, el error cae en el [FutureBuilder] y la pantalla
  /// ofrece reintentar en vez de reventar el árbol de widgets.
  Future<List<RegistroMapeo>> _cargar() async {
    final fuente = _fuente ??=
        widget.fuente ?? RepositorioMapeo(Supabase.instance.client);
    final historial = await fuente.historial(widget.tipo);

    _porDia
      ..clear()
      ..addEntries(historial.map((r) => MapEntry(r.fechaIso, r)));
    _mostrar(_dia);

    return historial;
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  RegistroMapeo get _enPantalla => RegistroMapeo(
    fecha: _dia,
    valores: {for (final e in _campos.entries) e.key: e.value.text},
  );

  /// Carga en los campos lo guardado de ese día, o los deja vacíos.
  void _mostrar(DateTime dia) {
    final guardado = _porDia[RegistroMapeo.claveDe(dia)];

    for (final e in _campos.entries) {
      e.value.text = guardado?.valorDe(e.key) ?? '';
    }
    _sucio = false;
  }

  Future<void> _irA(DateTime dia) async {
    if (RegistroMapeo.mismoDia(dia, _dia)) return;
    if (!await _resolverPendientes()) return;
    if (!mounted) return;

    OcultarTeclado.soltarFoco();
    setState(() {
      _dia = RegistroMapeo.soloDia(dia);
      _mostrar(_dia);
    });
  }

  /// Antes de cambiar de día, qué hacer con lo que quedó escrito. Devuelve
  /// `false` si el paciente decidió quedarse donde estaba.
  Future<bool> _resolverPendientes() async {
    if (!_sucio) return true;

    final decision = await showDialog<_Pendiente>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tienes cambios sin guardar'),
        content: Text(
          'Lo que escribiste en ${formatearFechaCorta(_dia)} todavía no se '
          'guardó.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _Pendiente.quedarse),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _Pendiente.descartar),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _Pendiente.guardar),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (decision == _Pendiente.guardar) return _guardar();
    return decision == _Pendiente.descartar;
  }

  Future<bool> _guardar() async {
    OcultarTeclado.soltarFoco();
    final registro = _enPantalla;

    setState(() => _guardando = true);
    try {
      await _fuente!.guardar(widget.tipo, registro);

      if (registro.vacio) {
        _porDia.remove(registro.fechaIso);
      } else {
        _porDia[registro.fechaIso] = registro;
      }

      if (!mounted) return true;
      setState(() {
        _sucio = false;
        _guardando = false;
      });
      _avisar(registro.vacio ? 'Registro borrado' : 'Guardado');
      return true;
    } on FallaMapeo catch (e) {
      if (!mounted) return false;
      setState(() => _guardando = false);
      _avisar(e.mensaje, error: true);
      return false;
    }
  }

  void _avisar(String mensaje, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: error ? scheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<RegistroMapeo>>(
      future: _carga,
      builder: (context, snapshot) {
        // El estado se mira antes que el error: al reintentar, FutureBuilder
        // arrastra el error viejo hasta que el futuro nuevo responde, y sin
        // esto la pantalla se quedaría pegada en la falla.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Falla(
            mensaje: snapshot.error is FallaMapeo
                ? (snapshot.error! as FallaMapeo).mensaje
                : 'No pudimos cargar tu mapeo.',
            onReintentar: () => setState(() {
              _carga = _cargar();
            }),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final historial = _porDia.values.toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));

        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _SelectorDeDia(dia: _dia, onCambio: _irA),
            const SizedBox(height: 20),
            for (final momento in MomentoMapeo.values) ...[
              _Campo(
                controlador: _campos[momento]!,
                momento: momento,
                tipo: widget.tipo,
                onCambio: () {
                  if (!_sucio) setState(() => _sucio = true);
                },
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _guardando || !_sucio ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
            const SizedBox(height: 28),
            _Historial(registros: historial, diaActual: _dia, onAbrir: _irA),
          ],
        );
      },
    );
  }
}

/// Qué hacer con lo escrito al salirse del día sin guardar.
enum _Pendiente { quedarse, descartar, guardar }

/// El día que se está editando, con un paso atrás y adelante.
///
/// Los días sueltos se eligen del calendario, pero lo que se hace casi
/// siempre es "ayer" y "antier", y eso tiene que ser un solo toque.
class _SelectorDeDia extends StatelessWidget {
  const _SelectorDeDia({required this.dia, required this.onCambio});

  final DateTime dia;
  final ValueChanged<DateTime> onCambio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hoy = RegistroMapeo.soloDia(DateTime.now());
    // No se mide hacia adelante: una medición del futuro no existe todavía.
    final haySiguiente = dia.isBefore(hoy);

    Future<void> abrirCalendario() async {
      OcultarTeclado.soltarFoco();
      final elegido = await showDatePicker(
        context: context,
        initialDate: dia,
        firstDate: DateTime(hoy.year - 5),
        lastDate: hoy,
        helpText: 'Elegir el día',
        cancelText: 'Cancelar',
        confirmText: 'Listo',
      );
      if (elegido != null) onCambio(elegido);
    }

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          IconButton(
            onPressed: () => onCambio(dia.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Día anterior',
          ),
          Expanded(
            child: InkWell(
              onTap: abrirCalendario,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Text(
                      RegistroMapeo.mismoDia(dia, hoy)
                          ? 'Hoy'
                          : formatearFechaCorta(dia),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatearDiaConSemana(dia),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: haySiguiente
                ? () => onCambio(dia.add(const Duration(days: 1)))
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Día siguiente',
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.controlador,
    required this.momento,
    required this.tipo,
    required this.onCambio,
  });

  final TextEditingController controlador;
  final MomentoMapeo momento;
  final TipoMapeo tipo;
  final VoidCallback onCambio;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      onChanged: (_) => onCambio(),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: momento.etiqueta,
        hintText: tipo.ejemplo,
        helperText: momento.ayuda,
      ),
    );
  }
}

/// Los días ya anotados. Sin esto el módulo sería de solo escritura y el
/// paciente no podría ver de un vistazo cómo viene la semana.
class _Historial extends StatelessWidget {
  const _Historial({
    required this.registros,
    required this.diaActual,
    required this.onAbrir,
  });

  final List<RegistroMapeo> registros;
  final DateTime diaActual;
  final ValueChanged<DateTime> onAbrir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (registros.isEmpty) {
      return Text(
        'Todavía no has anotado nada. Lo que registres queda acá, por día.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registros anteriores', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final r in registros)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: RegistroMapeo.mismoDia(r.fecha, diaActual)
                ? scheme.tertiaryContainer
                : null,
            child: InkWell(
              onTap: () => onAbrir(r.fecha),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatearFechaCorta(r.fecha),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final m in MomentoMapeo.values)
                      if (r.valorDe(m).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 108,
                                child: Text(
                                  m.etiqueta,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  r.valorDe(m),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Falla extends StatelessWidget {
  const _Falla({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onReintentar,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
