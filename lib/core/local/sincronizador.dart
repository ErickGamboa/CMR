import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/recarga.dart';
import '../datos/repositorio.dart';
import 'almacen_local.dart';

/// Una consulta que se baja entera y se guarda tal cual en el teléfono.
class Conjunto {
  const Conjunto(this.clave, this.bajar, {this.publico = false, this.modulo});

  final String clave;

  /// Pide las filas a Supabase. Lo que devuelva tiene que poder pasar por
  /// JSON, que es como se guarda.
  final Future<Object?> Function(SupabaseClient db) bajar;

  /// Es igual para todos los pacientes (el libro, los videos). Se guarda una
  /// sola vez y no bajo el paciente de la sesión.
  final bool publico;

  /// Solo se baja si el paciente tiene prendido ese módulo, ej. `'mapeo'`.
  final String? modulo;
}

/// Las claves de los conjuntos. Viven acá para que el repositorio que lee y
/// el que arma la lista de qué bajar no puedan escribir la misma distinto.
abstract final class Claves {
  static const citas = 'citas';
  static const mediciones = 'mediciones';
  static const laboratorios = 'laboratorios';
  static const recomendaciones = 'recomendaciones';
  static const prescripciones = 'prescripciones';
  static const suplementos = 'suplementos';
  static const videos = 'videos';
  static const libro = 'libro';
  static const plan = 'plan';
  static const modulos = 'modulos';
  static const mapeo = 'mapeo';
}

/// Mantiene al día la copia local de lo que el paciente ve.
///
/// Las pantallas leen **siempre** de la copia local, que responde al instante
/// con o sin internet. Esto, en segundo plano, baja lo último de Supabase,
/// lo guarda y avisa por [recarga] para que lo que esté en pantalla se vuelva
/// a leer.
///
/// Todo va en un solo sentido, de la nube al teléfono, así que nunca hay nada
/// que reconciliar: lo que llega reemplaza lo que había. La única excepción es
/// el mapeo, que el paciente sí escribe; eso sube por [subidas] antes de que
/// se baje la versión nueva, para que el teléfono no pise lo que todavía no
/// subió.
class Sincronizador extends ChangeNotifier {
  Sincronizador({
    required this.almacen,
    required this.cliente,
    required List<Conjunto> conjuntos,
    this.subidas = const [],
    this.recarga,
    @visibleForTesting String? Function()? paciente,
  }) : _conjuntos = {for (final c in conjuntos) c.clave: c},
       _pacienteFijo = paciente {
    _sesion = cliente.auth.onAuthStateChange.listen(
      (estado) {
        if (estado.event == AuthChangeEvent.signedOut) unawaited(vaciar());
      },
      // Los errores de refresco del token también llegan por acá. No le
      // tocan a esto: la sesión los maneja sola.
      onError: (Object _) {},
    );
  }

  /// El de la app. Es `null` en los tests, que inyectan fuentes falsas y no
  /// tocan ni Supabase ni el disco.
  static Sincronizador? actual;

  /// Cuánto se espera cada consulta antes de darla por perdida. Sin esto, con
  /// mala señal la flechita se quedaría girando para siempre.
  static const espera = Duration(seconds: 30);

  /// Al volver a la app, cuánto tiene que haber pasado para bajar de nuevo.
  static const _vigencia = Duration(minutes: 5);

  final AlmacenLocal almacen;
  final SupabaseClient cliente;
  final Map<String, Conjunto> _conjuntos;

  /// Lo que hay que subir antes de bajar, ej. el mapeo anotado sin conexión.
  final List<Future<void> Function()> subidas;

  /// El botón de la barra: gira mientras se baja, y su generación sube cuando
  /// hay datos nuevos para que las pantallas los vuelvan a leer.
  final ControlRecarga? recarga;

  /// En los tests, quién es el paciente sin tener que abrir una sesión.
  final String? Function()? _pacienteFijo;

  late final StreamSubscription<AuthState> _sesion;

  final _enVuelo = <String, Future<void>>{};
  Future<void>? _enCurso;

  /// Sube cada vez que se vacía el almacén. Una descarga que arrancó antes y
  /// termina después no guarda nada: los datos serían de una sesión que ya
  /// se cerró.
  int _epoca = 0;

  DateTime? _ultimaVez;
  bool _sinConexion = false;

  /// Cuándo se bajó todo por última vez sin problemas de conexión.
  DateTime? get ultimaVez => _ultimaVez;

  /// El último intento no pudo hablar con el servidor. Lo que se ve es lo
  /// guardado en [ultimaVez].
  bool get sinConexion => _sinConexion;

  bool get ocupado => _enCurso != null;

  /// El id del paciente de la sesión, o `null` si no hay.
  String? get paciente =>
      _pacienteFijo != null ? _pacienteFijo() : cliente.auth.currentUser?.id;

  /// La llave con que se guarda algo del paciente de la sesión.
  ///
  /// Todo lo del paciente lleva su id adelante. Al cerrar sesión se borra
  /// igual, pero así, aunque el borrado fallara, una cuenta nunca puede leer
  /// lo que se guardó para otra en el mismo teléfono.
  String llaveDelPaciente(String sufijo) {
    final id = paciente;
    if (id == null) {
      throw const FallaDatos('Tu sesión venció. Vuelve a ingresar.');
    }
    return '$id/$sufijo';
  }

  String llaveDe(String clave) {
    final conjunto = _conjunto(clave);
    return conjunto.publico ? 'publico/$clave' : llaveDelPaciente(clave);
  }

  Conjunto _conjunto(String clave) =>
      _conjuntos[clave] ?? (throw ArgumentError.value(clave, 'clave'));

  /// Lo guardado de ese conjunto.
  ///
  /// Si nunca se bajó (la primera vez que se abre la app), lo baja en ese
  /// momento; si ya viene en camino, espera esa misma descarga en vez de
  /// pedirlo dos veces. Solo en ese caso puede fallar por falta de internet.
  Future<Object?> leer(String clave) async {
    final llave = llaveDe(clave);
    final foto = await almacen.leer(llave);
    if (foto != null) return foto.datos;

    await _bajar(_conjunto(clave));
    return (await almacen.leer(llave))?.datos;
  }

  /// Igual que [leer], para los conjuntos que son una lista de filas.
  Future<List<Map<String, dynamic>>> filas(String clave) async {
    final datos = await leer(clave);
    return [
      for (final fila in datos as List<dynamic>? ?? const [])
        fila as Map<String, dynamic>,
    ];
  }

  Future<void> _bajar(Conjunto conjunto) {
    if (_enVuelo[conjunto.clave] case final enCamino?) return enCamino;

    final descarga = _bajarYa(conjunto);
    _enVuelo[conjunto.clave] = descarga;
    descarga.whenComplete(() => _enVuelo.remove(conjunto.clave)).ignore();
    return descarga;
  }

  Future<void> _bajarYa(Conjunto conjunto) async {
    final epoca = _epoca;
    final llave = llaveDe(conjunto.clave);
    final datos = await conjunto.bajar(cliente).timeout(espera);
    if (epoca != _epoca) return;

    await almacen.guardar(llave, datos);
  }

  /// Al entrar al Home: lee cuándo fue la última vez y baja lo nuevo.
  Future<void> entrar() async {
    try {
      final foto = await almacen.leer(llaveDelPaciente('meta:ultima'));
      _ultimaVez = foto?.bajada;
      notifyListeners();
    } on Object catch (e) {
      debugPrint('No se pudo leer la última sincronización: $e');
    }

    await sincronizar();
  }

  /// Al volver a la app desde segundo plano. No baja si se bajó hace poco,
  /// salvo que la última vez no haya habido conexión: puede haber mapeo
  /// esperando para subir.
  Future<void> alVolver() async {
    final ultima = _ultimaVez;
    final reciente =
        ultima != null && DateTime.now().difference(ultima) < _vigencia;
    if (reciente && !_sinConexion) return;

    await sincronizar();
  }

  /// Sube lo pendiente y baja todo. Si ya hay una sincronización en curso,
  /// devuelve esa: tocar el botón dos veces no duplica las consultas.
  ///
  /// Nunca falla. Si no hay conexión, lo guardado se queda como estaba y
  /// [sinConexion] lo dice.
  Future<void> sincronizar() {
    if (_enCurso case final enCurso?) return enCurso;

    final nueva = _sincronizar();
    _enCurso = nueva;
    nueva.whenComplete(() => _enCurso = null).ignore();
    return nueva;
  }

  Future<void> _sincronizar() async {
    if (paciente == null) return;

    final epoca = _epoca;
    var sinRed = false;

    // Cada pieza falla por su cuenta: que no esté la tabla de videos no es
    // razón para no bajar las citas.
    Future<void> intentar(Future<void> Function() paso) async {
      try {
        await paso();
      } on PostgrestException catch (e) {
        // El servidor respondió: hay conexión, aunque esa tabla no.
        debugPrint('Sincronización: ${e.message}');
      } on Object catch (e) {
        sinRed = true;
        debugPrint('Sincronización sin conexión: $e');
      }
    }

    recarga?.iniciar();
    notifyListeners();

    try {
      await Future.wait([
        for (final subir in subidas) intentar(subir),
        for (final c in _conjuntos.values)
          if (c.modulo == null) intentar(() => _bajar(c)),
      ]);

      // Los módulos opcionales van después: hasta no tener la lista nueva no
      // se sabe si al paciente le toca bajarlos.
      final habilitados = await _modulosHabilitados();
      await Future.wait([
        for (final c in _conjuntos.values)
          if (c.modulo case final m? when habilitados.contains(m))
            intentar(() => _bajar(c)),
      ]);

      if (epoca != _epoca) return;

      _sinConexion = sinRed;
      if (!sinRed) {
        await almacen.guardar(llaveDelPaciente('meta:ultima'), true);
        _ultimaVez = DateTime.now();
      }
    } on Object catch (e) {
      debugPrint('Sincronización: $e');
    } finally {
      recarga?.terminar();
      recarga?.refrescar();
      notifyListeners();
    }
  }

  Future<Set<String>> _modulosHabilitados() async {
    try {
      final foto = await almacen.leer(llaveDe(Claves.modulos));
      return {...?(foto?.datos as List<dynamic>?)?.cast<String>()};
    } on Object {
      return const {};
    }
  }

  /// Antes de cerrar sesión: intenta subir lo pendiente, sin hacer esperar
  /// más de unos segundos. Lo que no alcance a subir se pierde con el resto
  /// al vaciar.
  Future<void> antesDeSalir() async {
    try {
      await Future.wait([
        for (final subir in subidas) subir(),
      ]).timeout(const Duration(seconds: 5));
    } on Object catch (e) {
      debugPrint('No se pudo subir lo pendiente antes de salir: $e');
    }
  }

  /// Borra todo lo guardado. Corre solo al cerrar sesión.
  Future<void> vaciar() async {
    _epoca++;
    _ultimaVez = null;
    _sinConexion = false;
    notifyListeners();

    try {
      await almacen.vaciar();
    } on Object catch (e) {
      debugPrint('No se pudo vaciar el almacén local: $e');
    }
  }

  @override
  void dispose() {
    _sesion.cancel();
    super.dispose();
  }
}
