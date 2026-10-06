import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/datos/repositorio.dart';
import '../../core/local/sincronizador.dart';
import 'modelo_mapeo.dart';

/// De dónde salen y a dónde van los registros del mapeo.
///
/// Igual que el libro y el plan, la pantalla depende de esta interfaz y no de
/// Supabase, así que los tests corren sin red.
abstract interface class FuenteMapeo {
  /// Todo lo anotado de ese tipo, del día más nuevo al más viejo.
  Future<List<RegistroMapeo>> historial(TipoMapeo tipo);

  /// Crea o corrige el registro de ese día. Si viene vacío, lo borra.
  ///
  /// Queda guardado en el teléfono al instante, haya señal o no. Devuelve si
  /// además ya llegó a la nube; si no, se sube solo cuando vuelva la conexión.
  Future<bool> guardar(TipoMapeo tipo, RegistroMapeo registro);
}

/// Baja de Supabase todo el mapeo del paciente, los dos tipos juntos.
///
/// Espera a que no haya nada subiendo: si bajara mientras sube un registro, la
/// respuesta podría no traerlo y pisar la copia local justo después de que la
/// subida lo puso ahí.
Future<Object?> bajarMapeo(SupabaseClient db) => ColaMapeo._red.correr(
  () => db
      .from('mapeo_registros')
      .select('tipo, fecha, ayunas, libre, antes_de_dormir')
      .order('fecha', ascending: false),
);

/// Lee el mapeo de la copia local y anota en la cola de subida.
///
/// RLS ya limita la tabla al paciente de la sesión, así que las consultas no
/// filtran por paciente. El `upsert` sí manda `paciente_id`: es parte de la
/// llave única contra la que se resuelve el conflicto.
class RepositorioMapeo implements FuenteMapeo {
  RepositorioMapeo([this._datos]);

  final Sincronizador? _datos;

  Sincronizador get _sincronizador =>
      _datos ??
      Sincronizador.actual ??
      (throw const FallaMapeo('No pudimos abrir los datos guardados.'));

  @override
  Future<List<RegistroMapeo>> historial(TipoMapeo tipo) => _protegido(() async {
    final datos = _sincronizador;
    final pendientes = await ColaMapeo(datos).pendientes();

    List<Map<String, dynamic>> bajadas;
    try {
      bajadas = await datos.filas(Claves.mapeo);
    } on Object {
      // Nunca se bajó y no hay señal. Si anotó algo sin conexión, eso sí
      // se puede mostrar.
      if (pendientes.isEmpty) rethrow;
      bajadas = const [];
    }

    final porDia = {
      for (final fila in bajadas)
        if (fila['tipo'] == tipo.valor) fila['fecha'] as String: fila,
    };

    // Lo que todavía no subió manda sobre lo que vino de la nube: es más
    // nuevo, y el doctor no escribe mapeo, así que no hay nada que pisar.
    for (final pendiente in pendientes.values) {
      if (pendiente['tipo'] != tipo.valor) continue;
      final fecha = pendiente['fecha'] as String;
      if (ColaMapeo._esBorrado(pendiente)) {
        porDia.remove(fecha);
      } else {
        porDia[fecha] = pendiente;
      }
    }

    return porDia.values.map(RegistroMapeo.desdeFila).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  });

  @override
  Future<bool> guardar(TipoMapeo tipo, RegistroMapeo registro) =>
      _protegido(() async {
        final cola = ColaMapeo(_sincronizador);
        await cola.encolar(tipo, registro);

        // Unos segundos y no más: con mala señal, el paciente no se queda
        // mirando el botón girar. La subida sigue sola por detrás.
        try {
          await cola.subir().timeout(const Duration(seconds: 4));
        } on Object {
          // Queda en la cola; la próxima sincronización lo vuelve a intentar.
        }

        return !await cola.estaPendiente(tipo, registro.fechaIso);
      }, guardando: true);

  Future<T> _protegido<T>(
    Future<T> Function() paso, {
    bool guardando = false,
  }) async {
    try {
      return await paso();
    } on FallaDatos catch (e) {
      throw FallaMapeo(e.mensaje);
    } on PostgrestException catch (e) {
      throw FallaMapeo(_mensaje(e, guardando: guardando));
    } on SocketException {
      throw const FallaMapeo(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaMapeo('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  String _mensaje(PostgrestException e, {bool guardando = false}) {
    if (e.code == '42P01') {
      return 'El mapeo todavía no está habilitado en el servidor.';
    }
    return guardando
        ? 'No pudimos guardar. Intenta de nuevo en unos minutos.'
        : 'No pudimos cargar tu mapeo. Intenta de nuevo en unos minutos.';
  }
}

/// Lo anotado en el mapeo que todavía no llegó a la nube.
///
/// Vive en el almacén local, bajo el paciente, como un registro por tipo y
/// día: si corrige el mismo día dos veces sin señal, se sube solo la última
/// versión.
class ColaMapeo {
  ColaMapeo(this._datos);

  final Sincronizador _datos;

  /// Ordena las lecturas y escrituras de la cola, para que dos cambios
  /// seguidos no se pisen al guardarla.
  static final _cola = _Turno();

  /// Que una subida y una bajada del mapeo no se crucen. Ver [bajarMapeo].
  static final _red = _Turno();

  static Future<void>? _subiendo;

  String get _llave => _datos.llaveDelPaciente('mapeo:pendientes');

  static String _id(String tipo, String fecha) => '$tipo|$fecha';

  static bool _esBorrado(Map<String, dynamic> fila) =>
      MomentoMapeo.values.every((m) => fila[m.columna] == null);

  Future<Map<String, Map<String, dynamic>>> pendientes() async {
    final foto = await _datos.almacen.leer(_llave);
    final guardados = foto?.datos as Map<String, dynamic>? ?? const {};
    return {
      for (final e in guardados.entries) e.key: e.value as Map<String, dynamic>,
    };
  }

  Future<bool> estaPendiente(TipoMapeo tipo, String fecha) async =>
      (await pendientes()).containsKey(_id(tipo.valor, fecha));

  Future<void> encolar(TipoMapeo tipo, RegistroMapeo registro) =>
      _cola.correr(() async {
        final llave = _llave;
        final cola = await pendientes();
        cola[_id(tipo.valor, registro.fechaIso)] = {
          'tipo': tipo.valor,
          'fecha': registro.fechaIso,
          for (final m in MomentoMapeo.values)
            m.columna: registro.valores[m], // null borra lo que hubiera
        };
        await _datos.almacen.guardar(llave, cola);
      });

  /// Sube todo lo pendiente. Si ya hay una subida en curso, devuelve esa, que
  /// igual va a recoger lo que se haya anotado mientras tanto.
  ///
  /// Falla si no hay conexión; lo que no subió se queda en la cola.
  Future<void> subir() {
    if (_subiendo case final enCurso?) return enCurso;

    final nueva = _subir();
    _subiendo = nueva;
    nueva.whenComplete(() => _subiendo = null).ignore();
    return nueva;
  }

  Future<void> _subir() async {
    final paciente = _datos.paciente;
    if (paciente == null) return;

    // Lo que ya se mandó, con el valor con que se mandó. Si mientras subía
    // corrigieron ese día otra vez, el valor no coincide y se vuelve a subir.
    final enviados = <String, String>{};

    while (true) {
      final cola = await pendientes();
      final siguiente = cola.entries
          .where((e) => enviados[e.key] != jsonEncode(e.value))
          .firstOrNull;
      if (siguiente == null) return;

      final version = jsonEncode(siguiente.value);
      enviados[siguiente.key] = version;

      await _red.correr(() async {
        await _enviar(paciente, siguiente.value).timeout(Sincronizador.espera);

        await _cola.correr(() async {
          final ahora = await pendientes();
          if (jsonEncode(ahora[siguiente.key]) == version) {
            ahora.remove(siguiente.key);
            await _datos.almacen.guardar(_llave, ahora);
          }
          await _aplicarALaCopia(siguiente.value);
        });
      });
    }
  }

  Future<void> _enviar(String paciente, Map<String, dynamic> fila) async {
    final tabla = _datos.cliente.from('mapeo_registros');

    if (_esBorrado(fila)) {
      await tabla
          .delete()
          .eq('tipo', fila['tipo'] as String)
          .eq('fecha', fila['fecha'] as String);
      return;
    }

    await tabla.upsert({
      'paciente_id': paciente,
      ...fila,
    }, onConflict: 'paciente_id,tipo,fecha');
  }

  /// Pone lo recién subido en la copia de lo bajado. Sin esto, al salir de la
  /// cola el registro desaparecería del historial hasta la próxima bajada.
  Future<void> _aplicarALaCopia(Map<String, dynamic> fila) async {
    final llave = _datos.llaveDe(Claves.mapeo);
    final foto = await _datos.almacen.leer(llave);
    if (foto == null) return;

    final filas =
        [
          for (final f in foto.datos as List<dynamic>? ?? const [])
            f as Map<String, dynamic>,
        ]..removeWhere(
          (f) => f['tipo'] == fila['tipo'] && f['fecha'] == fila['fecha'],
        );
    if (!_esBorrado(fila)) filas.add(fila);

    await _datos.almacen.guardar(llave, filas);
  }
}

/// Corre los pasos de a uno, en el orden en que llegan.
class _Turno {
  Future<void> _ultimo = Future.value();

  Future<T> correr<T>(Future<T> Function() paso) {
    final resultado = _ultimo.then((_) => paso());
    _ultimo = resultado.then<void>((_) {}, onError: (Object _) {});
    return resultado;
  }
}

/// Error con mensaje listo para mostrarle al paciente.
class FallaMapeo implements Exception {
  const FallaMapeo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
