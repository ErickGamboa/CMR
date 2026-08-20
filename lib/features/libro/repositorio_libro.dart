import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'modelo_libro.dart';

/// De dónde salen los datos del libro.
///
/// La pantalla depende de esta interfaz y no de Supabase directamente, igual
/// que el resto de la app depende de `ServicioAuth`: así los tests corren sin
/// red ni credenciales.
abstract interface class FuenteLibro {
  Future<Libro> cargar();

  Future<Libro> recargar();
}

/// Lee el libro de intercambios de Supabase.
///
/// El libro es el mismo para todos los pacientes y cambia una o dos veces al
/// año, así que se baja completo de una sola vez (son menos de 300 filas) y se
/// guarda en memoria. Con eso el buscador y los filtros trabajan sin red: el
/// paciente escribe y la lista responde de inmediato, que es lo que uno espera
/// de algo que reemplaza a un PDF.
class RepositorioLibro implements FuenteLibro {
  RepositorioLibro(this._client);

  final SupabaseClient _client;

  Future<Libro>? _enVuelo;

  /// Devuelve el libro. La primera llamada lo baja; las siguientes reciben lo
  /// que ya está en memoria.
  @override
  Future<Libro> cargar() => _enVuelo ??= _bajar();

  /// Vuelve a bajarlo. Se usa cuando la primera carga falló y el paciente
  /// toca "Intentar de nuevo".
  @override
  Future<Libro> recargar() => _enVuelo = _bajar();

  Future<Libro> _bajar() async {
    try {
      // `ascending: true` va explícito: el cliente de Supabase ordena
      // descendente por defecto, y acá el orden es el del libro impreso.
      final secciones = await _client
          .from('libro_secciones')
          .select('id, nombre, tipo, grupo, nota')
          .order('orden', ascending: true);

      final alimentos = await _client
          .from('libro_alimentos')
          .select(
            'id, seccion_id, subseccion, nombre, marcas, porcion, '
            'c, f, p, v, l, g, alternativa, grasa_variable, libre, nota',
          )
          .order('orden', ascending: true);

      // Agrupar por sección de una pasada, respetando el orden que ya trae la
      // consulta.
      final porSeccion = <String, List<AlimentoLibro>>{};
      for (final fila in alimentos) {
        final alimento = AlimentoLibro.desdeFila(fila);
        porSeccion.putIfAbsent(alimento.seccionId, () => []).add(alimento);
      }

      return Libro([
        for (final fila in secciones)
          SeccionLibro.desdeFila(
            fila,
            porSeccion[fila['id'] as String] ?? const [],
          ),
      ]);
    } on PostgrestException catch (e) {
      // El caso típico acá es que las migraciones del libro no se aplicaron
      // todavía: mejor decirlo que mostrar un error de Postgres.
      throw FallaLibro(
        e.code == '42P01'
            ? 'El libro todavía no está cargado en el servidor.'
            : 'No pudimos cargar el libro. Intentá de nuevo en unos minutos.',
      );
    } on SocketException {
      throw const FallaLibro(
        'No pudimos conectar. Revisá tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaLibro('El servidor tardó demasiado. Intentá de nuevo.');
    }
  }
}

/// Error con mensaje listo para mostrarle al paciente.
class FallaLibro implements Exception {
  const FallaLibro(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
