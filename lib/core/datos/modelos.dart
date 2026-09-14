import 'package:flutter/material.dart';

import '../iconos.dart';

/// Modelos de todo lo que el doctor le registra o le receta al paciente.
///
/// Cada uno sabe leerse de la fila que devuelve Supabase (`desdeFila`). Ese es
/// el único lugar donde los nombres de columna aparecen fuera del repositorio.

// ---------------------------------------------------------------------------
// Citas
// ---------------------------------------------------------------------------

/// De qué es la cita.
///
/// Las dos van por aparte porque no se preparan igual: a la médica se llega
/// con los laboratorios listos, y la de enfermería es la aplicación o la toma
/// de muestras.
enum TipoCita {
  medica(
    valor: 'medica',
    etiqueta: 'Cita médica',
    vacio: 'Todavía no tienes citas médicas.',
  ),
  enfermeria(
    valor: 'enfermeria',
    etiqueta: 'Cita enfermería',
    vacio: 'Todavía no tienes citas de enfermería.',
  );

  const TipoCita({
    required this.valor,
    required this.etiqueta,
    required this.vacio,
  });

  /// Como se guarda en la columna `tipo`.
  final String valor;

  final String etiqueta;

  /// Qué decir cuando el paciente no tiene ninguna de este tipo.
  final String vacio;

  static TipoCita? porValor(String? valor) {
    for (final t in values) {
      if (t.valor == valor) return t;
    }
    return null;
  }
}

class Cita {
  const Cita({
    required this.fecha,
    required this.tipo,
    required this.profesional,
    required this.especialidad,
    required this.lugar,
  });

  static Cita? desdeFila(Map<String, dynamic> fila) {
    final tipo = TipoCita.porValor(fila['tipo'] as String?);
    if (tipo == null) return null;

    return Cita(
      fecha: DateTime.parse(fila['fecha'] as String),
      tipo: tipo,
      profesional: fila['profesional'] as String? ?? '',
      especialidad: fila['especialidad'] as String? ?? '',
      lugar: fila['lugar'] as String? ?? '',
    );
  }

  final DateTime fecha;
  final TipoCita tipo;
  final String profesional;
  final String especialidad;
  final String lugar;
}

// ---------------------------------------------------------------------------
// Mediciones
// ---------------------------------------------------------------------------

/// Una medición de composición corporal.
///
/// [grasaPerdida] y [musculoGanado] son acumulados desde el inicio del plan,
/// no el delta contra la medición anterior.
class Medicion {
  const Medicion({
    required this.fecha,
    required this.grasaPerdida,
    required this.musculoGanado,
    required this.peso,
    required this.porcentajeGrasa,
    required this.grasaVisceral,
  });

  factory Medicion.desdeFila(Map<String, dynamic> fila) => Medicion(
    fecha: DateTime.parse(fila['fecha'] as String),
    grasaPerdida: aDouble(fila['grasa_perdida']),
    musculoGanado: aDouble(fila['musculo_ganado']),
    peso: aDouble(fila['peso']),
    porcentajeGrasa: aDouble(fila['porcentaje_grasa']),
    grasaVisceral: aDouble(fila['grasa_visceral']),
  );

  /// Kilos de grasa perdidos desde el inicio del plan.
  final double grasaPerdida;

  /// Kilos de músculo ganados desde el inicio del plan.
  final double musculoGanado;

  /// Peso corporal en kilos al momento de la medición.
  final double peso;

  final double porcentajeGrasa;

  /// Índice de grasa visceral (escala del equipo de bioimpedancia).
  final double grasaVisceral;

  final DateTime fecha;
}

// ---------------------------------------------------------------------------
// Laboratorios
// ---------------------------------------------------------------------------

/// Un examen de laboratorio con todos sus analitos.
class Laboratorio {
  const Laboratorio({
    required this.fecha,
    required this.nombre,
    required this.analisis,
  });

  final DateTime fecha;

  /// Panel solicitado. Ej.: "Perfil metabólico completo".
  final String nombre;

  final List<AnalisisLab> analisis;

  /// Cuántos valores salieron del rango de referencia.
  int get fueraDeRango => analisis.where((a) => a.fueraDeRango).length;
}

class AnalisisLab {
  const AnalisisLab({
    required this.nombre,
    required this.valor,
    required this.unidad,
    required this.referencia,
    this.fueraDeRango = false,
  });

  factory AnalisisLab.desdeFila(Map<String, dynamic> fila) => AnalisisLab(
    nombre: fila['nombre'] as String? ?? '',
    valor: fila['valor'] as String? ?? '',
    unidad: fila['unidad'] as String? ?? '',
    referencia: fila['referencia'] as String? ?? '',
    fueraDeRango: fila['fuera_de_rango'] as bool? ?? false,
  );

  final String nombre;
  final String valor;
  final String unidad;
  final String referencia;

  /// Lo marca el doctor al cargar el examen; la app no lo deduce del rango,
  /// que viene como texto libre.
  final bool fueraDeRango;
}

// ---------------------------------------------------------------------------
// Recomendaciones
// ---------------------------------------------------------------------------

/// Indicación escrita que el doctor le dejó al paciente.
class Recomendacion {
  const Recomendacion({
    required this.fecha,
    required this.titulo,
    required this.texto,
    required this.icono,
  });

  factory Recomendacion.desdeFila(Map<String, dynamic> fila) => Recomendacion(
    fecha: DateTime.parse(fila['fecha'] as String),
    titulo: fila['titulo'] as String? ?? '',
    texto: fila['texto'] as String? ?? '',
    icono: iconoPorNombre(
      fila['icono'] as String?,
      fallback: Icons.lightbulb_outline,
    ),
  );

  final DateTime fecha;
  final String titulo;
  final String texto;
  final IconData icono;
}

// ---------------------------------------------------------------------------
// Prescripciones
// ---------------------------------------------------------------------------

/// Qué clase de indicación es. Las tres se muestran igual, así que comparten
/// tabla y modelo; el tipo es lo único que las separa.
enum TipoPrescripcion {
  suplemento('suplemento'),
  peptido('peptido'),
  medicamento('medicamento');

  const TipoPrescripcion(this.valor);

  final String valor;
}

/// Algo que el doctor le indicó al paciente: un suplemento, un péptido o un
/// medicamento.
class Prescripcion {
  const Prescripcion({
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    this.indicacion,
  });

  factory Prescripcion.desdeFila(Map<String, dynamic> fila) => Prescripcion(
    nombre: fila['nombre'] as String? ?? '',
    dosis: fila['dosis'] as String? ?? '',
    frecuencia: fila['frecuencia'] as String? ?? '',
    indicacion: fila['indicacion'] as String?,
  );

  final String nombre;
  final String dosis;
  final String frecuencia;

  /// Cómo o cuándo tomarlo. Ej.: "con el desayuno", "subcutánea".
  final String? indicacion;
}

// ---------------------------------------------------------------------------
// Catálogo: suplementos y videos
// ---------------------------------------------------------------------------

/// Un tipo de suplemento con las marcas que el doctor recomienda. Es catálogo
/// público: el mismo para todos los pacientes.
class CategoriaSuplemento {
  const CategoriaSuplemento({
    required this.nombre,
    required this.icono,
    required this.marcas,
  });

  final String nombre;
  final IconData icono;
  final List<MarcaSuplemento> marcas;
}

class MarcaSuplemento {
  const MarcaSuplemento({required this.nombre, required this.presentacion});

  factory MarcaSuplemento.desdeFila(Map<String, dynamic> fila) =>
      MarcaSuplemento(
        nombre: fila['nombre'] as String? ?? '',
        presentacion: fila['presentacion'] as String? ?? '',
      );

  final String nombre;
  final String presentacion;
}

class Video {
  const Video({required this.titulo, required this.url, this.descripcion});

  factory Video.desdeFila(Map<String, dynamic> fila) => Video(
    titulo: fila['titulo'] as String? ?? '',
    url: fila['url'] as String? ?? '',
    descripcion: fila['descripcion'] as String?,
  );

  final String titulo;

  /// A dónde lleva: YouTube, Vimeo o un archivo en Supabase Storage.
  final String url;

  final String? descripcion;
}

/// Postgres devuelve los `numeric` como `String` y los `int` como `int`.
double aDouble(Object? valor) => switch (valor) {
  num v => v.toDouble(),
  String v => double.tryParse(v) ?? 0,
  _ => 0,
};
