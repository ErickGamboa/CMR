import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'modelo_mapeo.dart';

/// De dónde salen y a dónde van los registros del mapeo.
///
/// Igual que el libro y el plan, la pantalla depende de esta interfaz y no de
/// Supabase, así que los tests corren sin red.
abstract interface class FuenteMapeo {
  /// Todo lo anotado de ese tipo, del día más nuevo al más viejo.
  Future<List<RegistroMapeo>> historial(TipoMapeo tipo);

  /// Crea o corrige el registro de ese día. Si viene vacío, lo borra.
  Future<void> guardar(TipoMapeo tipo, RegistroMapeo registro);
}

/// Lee y escribe `mapeo_registros` en Supabase.
///
/// RLS ya limita la tabla al paciente de la sesión, así que las consultas no
/// filtran por paciente. El `upsert` sí manda `paciente_id`: es parte de la
/// llave única contra la que se resuelve el conflicto.
class RepositorioMapeo implements FuenteMapeo {
  RepositorioMapeo(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RegistroMapeo>> historial(TipoMapeo tipo) async {
    try {
      final filas = await _client
          .from('mapeo_registros')
          .select('fecha, ayunas, libre, antes_de_dormir')
          .eq('tipo', tipo.valor)
          .order('fecha', ascending: false);

      return filas.map(RegistroMapeo.desdeFila).toList();
    } on PostgrestException catch (e) {
      throw FallaMapeo(_mensaje(e));
    } on SocketException {
      throw const FallaMapeo(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaMapeo('El servidor tardó demasiado. Intenta de nuevo.');
    }
  }

  @override
  Future<void> guardar(TipoMapeo tipo, RegistroMapeo registro) async {
    final paciente = _client.auth.currentUser?.id;
    if (paciente == null) {
      throw const FallaMapeo('Tu sesión venció. Vuelve a ingresar.');
    }

    try {
      if (registro.vacio) {
        await _client
            .from('mapeo_registros')
            .delete()
            .eq('tipo', tipo.valor)
            .eq('fecha', registro.fechaIso);
        return;
      }

      await _client.from('mapeo_registros').upsert({
        'paciente_id': paciente,
        'tipo': tipo.valor,
        'fecha': registro.fechaIso,
        for (final m in MomentoMapeo.values)
          m.columna: registro.valores[m], // null borra lo que hubiera
      }, onConflict: 'paciente_id,tipo,fecha');
    } on PostgrestException catch (e) {
      throw FallaMapeo(_mensaje(e, guardando: true));
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

/// Error con mensaje listo para mostrarle al paciente.
class FallaMapeo implements Exception {
  const FallaMapeo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
