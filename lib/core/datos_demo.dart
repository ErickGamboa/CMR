/// DATOS DE DEMOSTRACIÓN.
///
/// Todo lo de este archivo es inventado y existe solo para poder ver las
/// pantallas armadas. Se borra completo cuando conectemos las tablas de
/// Supabase.
///
/// Las marcas de suplementos son NOMBRES INVENTADOS a propósito: poner marcas
/// reales presentadas como "recomendadas por el doctor" sería atribuirle un
/// respaldo que nadie dio.
library;

import 'package:flutter/material.dart';

class Cita {
  const Cita({
    required this.fecha,
    required this.profesional,
    required this.especialidad,
    required this.lugar,
  });

  final DateTime fecha;
  final String profesional;
  final String especialidad;
  final String lugar;
}

/// Una medición de composición corporal.
///
/// Ambos valores son acumulados desde el inicio del plan, no el delta contra
/// la medición anterior.
class Medicion {
  const Medicion({
    required this.fecha,
    required this.grasaPerdida,
    required this.musculoGanado,
    required this.peso,
    required this.porcentajeGrasa,
    required this.grasaVisceral,
  });

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

  final String nombre;
  final String valor;
  final String unidad;
  final String referencia;
  final bool fueraDeRango;
}

/// Indicación escrita que el doctor le dejó al paciente.
class Recomendacion {
  const Recomendacion({
    required this.fecha,
    required this.titulo,
    required this.texto,
    required this.icono,
  });

  final DateTime fecha;
  final String titulo;
  final String texto;
  final IconData icono;
}

abstract final class DatosDemo {
  /// Fecha relativa a hoy pero con hora de consultorio.
  ///
  /// Si solo se desplazara desde `now()`, el demo mostraría citas a las 4 a.m.
  static DateTime _enDias(int dias, int hora, [int minuto = 0]) {
    final d = DateTime.now().add(Duration(days: dias));
    return DateTime(d.year, d.month, d.day, hora, minuto);
  }

  /// Citas ordenadas de la más vieja a la más reciente. Las anteriores a hoy
  /// se consideran cumplidas.
  static final citas = [
    Cita(
      fecha: _enDias(-96, 9),
      profesional: 'Dr. Roy Jiménez',
      especialidad: 'Valoración inicial',
      lugar: 'Clínica CMR · Consultorio 3',
    ),
    Cita(
      fecha: _enDias(-61, 10, 30),
      profesional: 'Dr. Roy Jiménez',
      especialidad: 'Control metabólico',
      lugar: 'Clínica CMR · Consultorio 3',
    ),
    Cita(
      fecha: _enDias(-28, 14),
      profesional: 'Dr. Roy Jiménez',
      especialidad: 'Control metabólico',
      lugar: 'Clínica CMR · Consultorio 3',
    ),
    Cita(
      fecha: _enDias(4, 10, 30),
      profesional: 'Dr. Roy Jiménez',
      especialidad: 'Control metabólico',
      lugar: 'Clínica CMR · Consultorio 3',
    ),
    Cita(
      fecha: _enDias(39, 15),
      profesional: 'Dr. Roy Jiménez',
      especialidad: 'Revisión de composición corporal',
      lugar: 'Clínica CMR · Consultorio 1',
    ),
  ];

  /// La próxima cita pendiente. Nula si no hay ninguna agendada.
  static Cita? get proximaCita {
    final ahora = DateTime.now();
    for (final c in citas) {
      if (c.fecha.isAfter(ahora)) return c;
    }
    return null;
  }

  /// Mediciones ordenadas de la más vieja a la más reciente.
  static final mediciones = [
    Medicion(
      fecha: DateTime(2026, 3, 14),
      grasaPerdida: 0,
      musculoGanado: 0,
      peso: 92.4,
      porcentajeGrasa: 32.1,
      grasaVisceral: 14,
    ),
    Medicion(
      fecha: DateTime(2026, 4, 11),
      grasaPerdida: 1.8,
      musculoGanado: 0.4,
      peso: 91.0,
      porcentajeGrasa: 30.6,
      grasaVisceral: 13,
    ),
    Medicion(
      fecha: DateTime(2026, 5, 16),
      grasaPerdida: 3.4,
      musculoGanado: 0.9,
      peso: 89.9,
      porcentajeGrasa: 29.0,
      grasaVisceral: 12,
    ),
    Medicion(
      fecha: DateTime(2026, 6, 13),
      grasaPerdida: 5.1,
      musculoGanado: 1.3,
      peso: 88.6,
      porcentajeGrasa: 27.2,
      grasaVisceral: 11,
    ),
    Medicion(
      fecha: DateTime(2026, 7, 18),
      grasaPerdida: 6.2,
      musculoGanado: 1.8,
      peso: 88.0,
      porcentajeGrasa: 26.0,
      grasaVisceral: 10,
    ),
    Medicion(
      fecha: DateTime(2026, 8, 8),
      grasaPerdida: 7.5,
      musculoGanado: 2.2,
      peso: 87.1,
      porcentajeGrasa: 24.7,
      grasaVisceral: 9,
    ),
  ];

  /// Laboratorios ordenados del más reciente al más viejo.
  static final laboratorios = [
    Laboratorio(
      fecha: DateTime(2026, 8, 6),
      nombre: 'Perfil metabólico completo',
      analisis: const [
        AnalisisLab(
          nombre: 'Glucosa en ayunas',
          valor: '94',
          unidad: 'mg/dL',
          referencia: '70 – 99',
        ),
        AnalisisLab(
          nombre: 'Hemoglobina glicosilada',
          valor: '5.4',
          unidad: '%',
          referencia: '< 5.7',
        ),
        AnalisisLab(
          nombre: 'Insulina basal',
          valor: '11.2',
          unidad: 'µU/mL',
          referencia: '2.6 – 24.9',
        ),
        AnalisisLab(
          nombre: 'Colesterol total',
          valor: '212',
          unidad: 'mg/dL',
          referencia: '< 200',
          fueraDeRango: true,
        ),
        AnalisisLab(
          nombre: 'Triglicéridos',
          valor: '138',
          unidad: 'mg/dL',
          referencia: '< 150',
        ),
        AnalisisLab(
          nombre: 'HDL',
          valor: '48',
          unidad: 'mg/dL',
          referencia: '> 40',
        ),
      ],
    ),
    Laboratorio(
      fecha: DateTime(2026, 5, 14),
      nombre: 'Perfil metabólico completo',
      analisis: const [
        AnalisisLab(
          nombre: 'Glucosa en ayunas',
          valor: '103',
          unidad: 'mg/dL',
          referencia: '70 – 99',
          fueraDeRango: true,
        ),
        AnalisisLab(
          nombre: 'Hemoglobina glicosilada',
          valor: '5.8',
          unidad: '%',
          referencia: '< 5.7',
          fueraDeRango: true,
        ),
        AnalisisLab(
          nombre: 'Colesterol total',
          valor: '231',
          unidad: 'mg/dL',
          referencia: '< 200',
          fueraDeRango: true,
        ),
        AnalisisLab(
          nombre: 'Triglicéridos',
          valor: '164',
          unidad: 'mg/dL',
          referencia: '< 150',
          fueraDeRango: true,
        ),
      ],
    ),
    Laboratorio(
      fecha: DateTime(2026, 3, 12),
      nombre: 'Tamizaje inicial',
      analisis: const [
        AnalisisLab(
          nombre: 'Glucosa en ayunas',
          valor: '108',
          unidad: 'mg/dL',
          referencia: '70 – 99',
          fueraDeRango: true,
        ),
        AnalisisLab(
          nombre: 'TSH',
          valor: '2.1',
          unidad: 'µU/mL',
          referencia: '0.4 – 4.0',
        ),
        AnalisisLab(
          nombre: 'Vitamina D',
          valor: '21',
          unidad: 'ng/mL',
          referencia: '30 – 100',
          fueraDeRango: true,
        ),
      ],
    ),
  ];

  /// Recomendaciones ordenadas de la más reciente a la más vieja.
  static final recomendaciones = [
    Recomendacion(
      fecha: DateTime(2026, 8, 8),
      titulo: 'Subí la proteína en el desayuno',
      texto: 'Apuntá a 30 g de proteína antes de las 10 a.m. Ayuda a sostener '
          'la masa muscular que venís ganando y baja el antojo de la tarde.',
      icono: Icons.egg_alt_outlined,
    ),
    Recomendacion(
      fecha: DateTime(2026, 8, 8),
      titulo: 'Caminá 20 minutos después de almorzar',
      texto: 'No hace falta que sea intenso. El objetivo es amortiguar el pico '
          'de glucosa posterior a la comida más grande del día.',
      icono: Icons.directions_walk_outlined,
    ),
    Recomendacion(
      fecha: DateTime(2026, 7, 18),
      titulo: 'Ordená el horario de sueño',
      texto: 'Acostate y levantate a la misma hora, incluso el fin de semana. '
          'El descanso irregular frena la pérdida de grasa visceral.',
      icono: Icons.bedtime_outlined,
    ),
    Recomendacion(
      fecha: DateTime(2026, 6, 13),
      titulo: 'Tomá 2.5 litros de agua al día',
      texto: 'Repartilos a lo largo del día. Si entrenás, sumá medio litro '
          'extra por cada hora de ejercicio.',
      icono: Icons.water_drop_outlined,
    ),
  ];

  static const suplementosRecetados = [
    Prescripcion(
      nombre: 'Proteína de suero',
      dosis: '30 g',
      frecuencia: '1 vez al día',
      indicacion: 'Después del entrenamiento',
    ),
    Prescripcion(
      nombre: 'Creatina monohidratada',
      dosis: '5 g',
      frecuencia: 'Diario',
      indicacion: 'A cualquier hora, con agua',
    ),
    Prescripcion(
      nombre: 'Vitamina D3',
      dosis: '2000 UI',
      frecuencia: 'Diario',
      indicacion: 'Con el desayuno',
    ),
    Prescripcion(
      nombre: 'Omega 3',
      dosis: '1 g',
      frecuencia: '2 veces al día',
      indicacion: 'Con las comidas',
    ),
  ];

  static const categoriasSuplementos = [
    CategoriaSuplemento(
      nombre: 'Proteína',
      icono: Icons.fitness_center,
      marcas: [
        MarcaSuplemento(nombre: 'Vitalpro Whey', presentacion: 'Bote 900 g'),
        MarcaSuplemento(nombre: 'Isolatum Zero', presentacion: 'Bote 750 g'),
        MarcaSuplemento(nombre: 'Nativa Protein', presentacion: 'Bote 1 kg'),
      ],
    ),
    CategoriaSuplemento(
      nombre: 'Creatina',
      icono: Icons.bolt_outlined,
      marcas: [
        MarcaSuplemento(nombre: 'PureCreat Mono', presentacion: 'Bote 300 g'),
        MarcaSuplemento(nombre: 'Creatia Micron', presentacion: 'Bote 500 g'),
      ],
    ),
    CategoriaSuplemento(
      nombre: 'Omega 3',
      icono: Icons.set_meal_outlined,
      marcas: [
        MarcaSuplemento(nombre: 'MarOmega Ultra', presentacion: '90 cápsulas'),
        MarcaSuplemento(nombre: 'Nordvital EPA', presentacion: '120 cápsulas'),
      ],
    ),
    CategoriaSuplemento(
      nombre: 'Vitamina D3',
      icono: Icons.wb_sunny_outlined,
      marcas: [
        MarcaSuplemento(nombre: 'Solaris D3', presentacion: '60 cápsulas'),
        MarcaSuplemento(nombre: 'Vitaluz 2000', presentacion: '100 cápsulas'),
      ],
    ),
    CategoriaSuplemento(
      nombre: 'Magnesio',
      icono: Icons.spa_outlined,
      marcas: [
        MarcaSuplemento(nombre: 'Magnelax Glicinato', presentacion: '120 cáps'),
        MarcaSuplemento(nombre: 'Puremag Citrato', presentacion: 'Polvo 250 g'),
      ],
    ),
  ];

  static const peptidos = [
    Prescripcion(
      nombre: 'Semaglutida',
      dosis: '0.5 mg',
      frecuencia: '1 vez por semana',
      indicacion: 'Vía subcutánea, mismo día cada semana',
    ),
    Prescripcion(
      nombre: 'Ipamorelina',
      dosis: '200 mcg',
      frecuencia: 'Diario',
      indicacion: 'Vía subcutánea, antes de dormir',
    ),
    Prescripcion(
      nombre: 'BPC-157',
      dosis: '250 mcg',
      frecuencia: 'Diario',
      indicacion: 'Vía subcutánea, en ayunas',
    ),
  ];

  static const medicamentos = [
    Prescripcion(
      nombre: 'Metformina 850 mg',
      dosis: '1 tableta',
      frecuencia: '2 veces al día',
      indicacion: 'Con el desayuno y la cena',
    ),
    Prescripcion(
      nombre: 'Atorvastatina 20 mg',
      dosis: '1 tableta',
      frecuencia: '1 vez al día',
      indicacion: 'En la noche',
    ),
    Prescripcion(
      nombre: 'Levotiroxina 50 mcg',
      dosis: '1 tableta',
      frecuencia: '1 vez al día',
      indicacion: 'En ayunas, 30 min antes del desayuno',
    ),
  ];
}

/// Algo que el doctor le indicó al paciente: un suplemento, un péptido o un
/// medicamento. Los tres se muestran igual, así que comparten modelo.
class Prescripcion {
  const Prescripcion({
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    this.indicacion,
  });

  final String nombre;
  final String dosis;
  final String frecuencia;

  /// Cómo o cuándo tomarlo. Ej.: "con el desayuno", "subcutánea".
  final String? indicacion;
}

/// Un tipo de suplemento con las marcas que el doctor recomienda.
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

  final String nombre;
  final String presentacion;
}

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'setiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Ej.: "8 de agosto, 2026".
String formatearFechaCorta(DateTime f) =>
    '${f.day} de ${_meses[f.month - 1]}, ${f.year}';

/// Ej.: "8 ago 2026". Para filtros y listas donde el espacio es poco.
String formatearFechaBreve(DateTime f) =>
    '${f.day} ${_meses[f.month - 1].substring(0, 3)} ${f.year}';

/// Abreviatura de tres letras con mayúscula inicial. Ej.: "Ago".
String mesCorto(DateTime f) {
  final m = _meses[f.month - 1];
  return m[0].toUpperCase() + m.substring(1, 3);
}

/// Formato de fecha en español sin depender de `intl`, que exigiría
/// inicializar locales solo para esto.
String formatearFechaLarga(DateTime f) {
  const meses = _meses;
  const dias = [
    'lunes', 'martes', 'miércoles', 'jueves',
    'viernes', 'sábado', 'domingo',
  ];

  final dia = dias[f.weekday - 1];
  final hora = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final minuto = f.minute.toString().padLeft(2, '0');
  final periodo = f.hour < 12 ? 'a.m.' : 'p.m.';

  return '$dia ${f.day} de ${meses[f.month - 1]} · $hora:$minuto $periodo';
}
