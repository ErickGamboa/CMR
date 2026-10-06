import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/datos/repositorio.dart';
import '../../core/local/sincronizador.dart';
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

/// Baja el libro de intercambios de Supabase.
///
/// El libro es el mismo para todos los pacientes y cambia una o dos veces al
/// año, así que se baja completo de una sola vez (son menos de 300 filas) y se
/// guarda en el teléfono. Con eso el buscador y los filtros trabajan sin red:
/// el paciente escribe y la lista responde de inmediato, que es lo que uno
/// espera de algo que reemplaza a un PDF.
Future<Object?> bajarLibro(SupabaseClient db) async {
  // `ascending: true` va explícito: el cliente de Supabase ordena descendente
  // por defecto, y acá el orden es el del libro impreso.
  final (secciones, alimentos) = await (
    db
        .from('libro_secciones')
        .select('id, nombre, tipo, grupo, nota')
        .order('orden', ascending: true),
    db
        .from('libro_alimentos')
        .select(
          'id, seccion_id, subseccion, nombre, marcas, porcion, '
          'c, f, p, v, l, g, alternativa, grasa_variable, libre, nota',
        )
        .order('orden', ascending: true),
  ).wait;

  return {'secciones': secciones, 'alimentos': alimentos};
}

/// Lee el libro de la copia local.
class RepositorioLibro implements FuenteLibro {
  RepositorioLibro([this._datos]);

  final Sincronizador? _datos;

  @override
  Future<Libro> cargar() => _leer();

  /// Es lo mismo que [cargar]: la copia local siempre tiene lo último que se
  /// bajó.
  @override
  Future<Libro> recargar() => _leer();

  Future<Libro> _leer() async {
    try {
      final datos = _datos ?? Sincronizador.actual;
      if (datos == null) {
        throw const FallaLibro('No pudimos abrir los datos guardados.');
      }

      final guardado = await datos.leer(Claves.libro) as Map<String, dynamic>;
      final secciones = (guardado['secciones'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final alimentos = (guardado['alimentos'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

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
    } on FallaDatos catch (e) {
      throw FallaLibro(e.mensaje);
    } on PostgrestException catch (e) {
      // El caso típico acá es que las migraciones del libro no se aplicaron
      // todavía: mejor decirlo que mostrar un error de Postgres.
      throw FallaLibro(
        e.code == '42P01'
            ? 'El libro todavía no está cargado en el servidor.'
            : 'No pudimos cargar el libro. Intenta de nuevo en unos minutos.',
      );
    } on SocketException {
      throw const FallaLibro(
        'No pudimos conectar. Revisa tu conexión a internet.',
      );
    } on TimeoutException {
      throw const FallaLibro('El servidor tardó demasiado. Intenta de nuevo.');
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
