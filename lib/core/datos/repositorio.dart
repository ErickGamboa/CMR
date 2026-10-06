import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../iconos.dart';
import '../local/sincronizador.dart';
import 'modelos.dart';

/// De dónde salen los datos del paciente de la sesión.
///
/// Las pantallas dependen de esta interfaz y no de Supabase, así que los tests
/// corren sin red ni credenciales.
abstract interface class FuentePaciente {
  Future<List<Cita>> citas();

  /// De la más vieja a la más reciente: las pantallas asumen ese orden para
  /// que "la última" sea la del final.
  Future<List<Medicion>> mediciones();

  /// Del más reciente al más viejo.
  Future<List<Laboratorio>> laboratorios();

  /// De la más reciente a la más vieja.
  Future<List<Recomendacion>> recomendaciones();

  Future<List<Prescripcion>> prescripciones(TipoPrescripcion tipo);
}

/// De dónde sale lo que es igual para todos los pacientes.
abstract interface class FuenteCatalogo {
  Future<List<CategoriaSuplemento>> categoriasDeSuplemento();

  Future<List<Video>> videos();
}

/// Lo que se baja de Supabase para cada conjunto del paciente.
///
/// Las políticas de RLS ya limitan cada tabla a `auth.uid()`, así que las
/// consultas no filtran por paciente: pedir "las citas" devuelve las propias y
/// ninguna otra.
///
/// Ojo con `order`: en postgrest-dart `ascending` es **false** por defecto, así
/// que un `.order('fecha')` pelado devuelve al revés de lo que parece. Acá va
/// explícito siempre, en las dos direcciones.
abstract final class DescargasPaciente {
  static Future<Object?> citas(SupabaseClient db) => db
      .from('citas')
      .select('fecha, tipo, profesional, especialidad, lugar')
      .order('fecha', ascending: true);

  static Future<Object?> mediciones(SupabaseClient db) => db
      .from('mediciones')
      .select(
        'fecha, peso, porcentaje_grasa, grasa_visceral, '
        'grasa_perdida, musculo_ganado',
      )
      .order('fecha', ascending: true);

  /// Un solo viaje: PostgREST trae los analitos anidados en cada examen.
  static Future<Object?> laboratorios(SupabaseClient db) => db
      .from('laboratorios')
      .select(
        'fecha, nombre, '
        'laboratorio_analisis(nombre, valor, unidad, referencia, '
        'fuera_de_rango, orden)',
      )
      .order('fecha', ascending: false);

  static Future<Object?> recomendaciones(SupabaseClient db) => db
      .from('recomendaciones')
      .select('fecha, titulo, texto, icono')
      .order('fecha', ascending: false);

  /// Los tres tipos de una vez: cada pantalla filtra el suyo de la copia
  /// local, y así es una consulta en vez de tres.
  static Future<Object?> prescripciones(SupabaseClient db) => db
      .from('prescripciones')
      .select('tipo, nombre, dosis, frecuencia, indicacion')
      .eq('activo', true)
      .order('orden', ascending: true);
}

/// Lo que se baja de Supabase del catálogo público.
abstract final class DescargasCatalogo {
  static Future<Object?> suplementos(SupabaseClient db) => db
      .from('suplemento_categorias')
      .select(
        'nombre, icono, orden, '
        'suplemento_marcas(nombre, presentacion, orden)',
      )
      .order('orden', ascending: true);

  static Future<Object?> videos(SupabaseClient db) => db
      .from('videos')
      .select('titulo, descripcion, url')
      .eq('publicado', true)
      .order('orden', ascending: true);
}

/// Lee los datos del paciente de la copia local.
///
/// Responde al instante con o sin internet. Lo que muestra es lo último que
/// bajó el [Sincronizador]; la primera vez, que no hay nada guardado, espera a
/// que se baje.
class RepositorioPaciente implements FuentePaciente {
  RepositorioPaciente([Sincronizador? datos]) : _datos = datos;

  final Sincronizador? _datos;

  Future<List<Map<String, dynamic>>> _filas(String clave) =>
      (_datos ?? _sincronizador).filas(clave);

  @override
  Future<List<Cita>> citas() => _protegido('tus citas', () async {
    final filas = await _filas(Claves.citas);
    return filas.map(Cita.desdeFila).nonNulls.toList();
  });

  @override
  Future<List<Medicion>> mediciones() => _protegido('tus mediciones', () async {
    final filas = await _filas(Claves.mediciones);
    return filas.map(Medicion.desdeFila).toList();
  });

  @override
  Future<List<Laboratorio>> laboratorios() =>
      _protegido('tus laboratorios', () async {
        final filas = await _filas(Claves.laboratorios);

        return filas.map((fila) {
          final analitos =
              (fila['laboratorio_analisis'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>()
                  .toList()
                ..sort(
                  (a, b) => (a['orden'] as int? ?? 0).compareTo(
                    b['orden'] as int? ?? 0,
                  ),
                );

          return Laboratorio(
            fecha: DateTime.parse(fila['fecha'] as String),
            nombre: fila['nombre'] as String? ?? '',
            analisis: analitos.map(AnalisisLab.desdeFila).toList(),
          );
        }).toList();
      });

  @override
  Future<List<Recomendacion>> recomendaciones() =>
      _protegido('tus recomendaciones', () async {
        final filas = await _filas(Claves.recomendaciones);
        return filas.map(Recomendacion.desdeFila).toList();
      });

  @override
  Future<List<Prescripcion>> prescripciones(TipoPrescripcion tipo) =>
      _protegido('lo que te recetaron', () async {
        final filas = await _filas(Claves.prescripciones);
        return filas
            .where((f) => f['tipo'] == tipo.valor)
            .map(Prescripcion.desdeFila)
            .toList();
      });
}

/// Lee el catálogo público de la copia local.
class RepositorioCatalogo implements FuenteCatalogo {
  RepositorioCatalogo([Sincronizador? datos]) : _datos = datos;

  final Sincronizador? _datos;

  Future<List<Map<String, dynamic>>> _filas(String clave) =>
      (_datos ?? _sincronizador).filas(clave);

  @override
  Future<List<CategoriaSuplemento>> categoriasDeSuplemento() =>
      _protegido('el catálogo de suplementos', () async {
        final filas = await _filas(Claves.suplementos);

        return filas.map((fila) {
          final marcas =
              (fila['suplemento_marcas'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>()
                  .toList()
                ..sort(
                  (a, b) => (a['orden'] as int? ?? 0).compareTo(
                    b['orden'] as int? ?? 0,
                  ),
                );

          return CategoriaSuplemento(
            nombre: fila['nombre'] as String? ?? '',
            icono: iconoPorNombre(fila['icono'] as String?),
            marcas: marcas.map(MarcaSuplemento.desdeFila).toList(),
          );
        }).toList();
      });

  @override
  Future<List<Video>> videos() => _protegido('los videos', () async {
    final filas = await _filas(Claves.videos);
    return filas.map(Video.desdeFila).toList();
  });
}

/// El sincronizador de la app, o una falla legible si todavía no arrancó.
Sincronizador get _sincronizador =>
    Sincronizador.actual ??
    (throw const FallaDatos('No pudimos abrir los datos guardados.'));

/// Corre la consulta y traduce cualquier falla a un mensaje que el paciente
/// pueda entender.
///
/// Está aparte porque los seis repositorios de la app fallan igual y el
/// paciente no tiene por qué leer seis redacciones distintas del mismo
/// problema. Con la copia local, esto solo pasa cuando no hay nada guardado
/// todavía y tampoco se pudo bajar.
Future<T> _protegido<T>(String que, Future<T> Function() consulta) async {
  try {
    return await consulta();
  } on PostgrestException catch (e) {
    throw FallaDatos(
      e.code == '42P01'
          ? 'Esta sección todavía no está habilitada en el servidor.'
          : 'No pudimos cargar $que. Intenta de nuevo en unos minutos.',
    );
  } on SocketException {
    throw const FallaDatos(
      'No pudimos conectar. Revisa tu conexión a internet.',
    );
  } on TimeoutException {
    throw const FallaDatos('El servidor tardó demasiado. Intenta de nuevo.');
  }
}

/// Error con mensaje listo para mostrarle al paciente.
class FallaDatos implements Exception {
  const FallaDatos(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
