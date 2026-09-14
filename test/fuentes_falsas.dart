/// Datos de prueba y fuentes falsas.
///
/// Antes esto vivía en `lib/core/datos_demo.dart` y se compilaba dentro de la
/// app, con el riesgo de que un paciente real viera recetas inventadas. Ahora
/// solo existe acá: los tests lo inyectan y la app siempre lee de Supabase.
library;

import 'package:flutter/material.dart';

import 'package:cmr_app/core/datos/modelos.dart';
import 'package:cmr_app/core/datos/repositorio.dart';
import 'package:cmr_app/core/modulos_habilitados.dart';

DateTime _enDias(int dias, [int hora = 9, int minuto = 0]) {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day + dias, hora, minuto);
}

DateTime _fecha(int diasAtras) {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day - diasAtras);
}

/// Citas de las dos clases, unas cumplidas y otras pendientes, de la más
/// vieja a la más reciente como las devuelve el repositorio.
final citasDePrueba = <Cita>[
  Cita(
    fecha: _enDias(-96, 9),
    tipo: TipoCita.medica,
    profesional: 'Dra. Prueba',
    especialidad: 'Valoración inicial',
    lugar: 'Clínica COSME - CMR',
  ),
  Cita(
    fecha: _enDias(-90, 8),
    tipo: TipoCita.enfermeria,
    profesional: 'Enfermería',
    especialidad: 'Toma de laboratorios',
    lugar: 'Clínica COSME - CMR',
  ),
  Cita(
    fecha: _enDias(-28, 14),
    tipo: TipoCita.medica,
    profesional: 'Dra. Prueba',
    especialidad: 'Control metabólico',
    lugar: 'Clínica COSME - CMR',
  ),
  Cita(
    fecha: _enDias(4, 10, 30),
    tipo: TipoCita.medica,
    profesional: 'Dra. Prueba',
    especialidad: 'Control metabólico',
    lugar: 'Clínica COSME - CMR',
  ),
  Cita(
    fecha: _enDias(11, 9),
    tipo: TipoCita.enfermeria,
    profesional: 'Enfermería',
    especialidad: 'Aplicación de péptidos',
    lugar: 'Clínica COSME - CMR',
  ),
];

/// De la más vieja a la más reciente, como las devuelve el repositorio.
final medicionesDePrueba = <Medicion>[
  Medicion(
    fecha: _fecha(96),
    grasaPerdida: 0,
    musculoGanado: 0,
    peso: 94.2,
    porcentajeGrasa: 34.1,
    grasaVisceral: 13,
  ),
  Medicion(
    fecha: _fecha(61),
    grasaPerdida: 3.4,
    musculoGanado: 0.9,
    peso: 91.7,
    porcentajeGrasa: 31.8,
    grasaVisceral: 11,
  ),
  Medicion(
    fecha: _fecha(30),
    grasaPerdida: 7.5,
    musculoGanado: 2.2,
    peso: 88.9,
    porcentajeGrasa: 28.4,
    grasaVisceral: 9,
  ),
];

/// Del más reciente al más viejo. El más viejo es el único con TSH, y el más
/// reciente tiene exactamente un valor fuera de rango.
final laboratoriosDePrueba = <Laboratorio>[
  Laboratorio(
    fecha: _fecha(30),
    nombre: 'Perfil metabólico completo',
    analisis: const [
      AnalisisLab(
        nombre: 'Glucosa en ayunas',
        valor: '92',
        unidad: 'mg/dL',
        referencia: '70 – 99',
      ),
      AnalisisLab(
        nombre: 'Emoglobina glicada',
        valor: '5.8',
        unidad: '%',
        referencia: '< 5.7',
        fueraDeRango: true,
      ),
      AnalisisLab(
        nombre: 'Colesterol total',
        valor: '178',
        unidad: 'mg/dL',
        referencia: '< 200',
      ),
    ],
  ),
  Laboratorio(
    fecha: _fecha(96),
    nombre: 'Perfil tiroideo',
    analisis: const [
      AnalisisLab(
        nombre: 'TSH',
        valor: '2.4',
        unidad: 'µUI/mL',
        referencia: '0.4 – 4.0',
      ),
      AnalisisLab(
        nombre: 'T4 libre',
        valor: '1.1',
        unidad: 'ng/dL',
        referencia: '0.8 – 1.8',
      ),
    ],
  ),
];

final recomendacionesDePrueba = <Recomendacion>[
  Recomendacion(
    fecha: _fecha(28),
    titulo: 'Sube la proteína en el desayuno',
    texto: 'Apunta a 30 g de proteína antes de las 10 a.m.',
    icono: Icons.egg_outlined,
  ),
  Recomendacion(
    fecha: _fecha(61),
    titulo: 'Camina 20 minutos después de almorzar',
    texto: 'Ayuda a bajar el pico de glucosa de la tarde.',
    icono: Icons.directions_walk,
  ),
  Recomendacion(
    fecha: _fecha(96),
    titulo: 'Toma 2.5 litros de agua al día',
    texto: 'Repártelos a lo largo del día.',
    icono: Icons.water_drop_outlined,
  ),
];

const suplementosDePrueba = <Prescripcion>[
  Prescripcion(
    nombre: 'Proteína de suero',
    dosis: '30 g',
    frecuencia: '1 vez al día',
    indicacion: 'Después del entrenamiento',
  ),
  Prescripcion(
    nombre: 'Vitamina D3',
    dosis: '2000 UI',
    frecuencia: 'Diario',
    indicacion: 'Con el desayuno',
  ),
];

const peptidosDePrueba = <Prescripcion>[
  Prescripcion(
    nombre: 'Péptido de prueba A',
    dosis: '0.5 mg',
    frecuencia: '1 vez por semana',
    indicacion: 'Vía subcutánea',
  ),
  Prescripcion(
    nombre: 'Péptido de prueba B',
    dosis: '200 mcg',
    frecuencia: 'Diario',
    indicacion: 'Antes de dormir',
  ),
];

const medicamentosDePrueba = <Prescripcion>[
  Prescripcion(
    nombre: 'Medicamento de prueba',
    dosis: '1 tableta',
    frecuencia: '2 veces al día',
    indicacion: 'Con el desayuno y la cena',
  ),
];

/// Marcas inventadas a propósito: poner marcas reales presentadas como
/// "recomendadas por el doctor" sería atribuirle un respaldo que nadie dio.
const categoriasDePrueba = <CategoriaSuplemento>[
  CategoriaSuplemento(
    nombre: 'Proteína',
    icono: Icons.fitness_center,
    marcas: [
      MarcaSuplemento(nombre: 'Vitalpro Whey', presentacion: 'Bote 900 g'),
      MarcaSuplemento(nombre: 'Isolatum Zero', presentacion: 'Bote 750 g'),
    ],
  ),
  CategoriaSuplemento(
    nombre: 'Omega 3',
    icono: Icons.set_meal_outlined,
    marcas: [
      MarcaSuplemento(nombre: 'MarOmega Ultra', presentacion: '90 cápsulas'),
    ],
  ),
];

const videosDePrueba = <Video>[
  Video(
    titulo: 'Cómo armar tu plato',
    url: 'https://example.test/video-1',
    descripcion: 'Cinco minutos sobre porciones.',
  ),
  Video(titulo: 'Qué es un intercambio', url: 'https://example.test/video-2'),
];

/// Fuente falsa de los datos del paciente.
class PacienteFalso implements FuentePaciente {
  PacienteFalso({
    List<Cita>? citas,
    List<Medicion>? mediciones,
    List<Laboratorio>? laboratorios,
    List<Recomendacion>? recomendaciones,
    Map<TipoPrescripcion, List<Prescripcion>>? prescripciones,
    this.falla,
  }) : _citas = citas ?? citasDePrueba,
       _mediciones = mediciones ?? medicionesDePrueba,
       _laboratorios = laboratorios ?? laboratoriosDePrueba,
       _recomendaciones = recomendaciones ?? recomendacionesDePrueba,
       _prescripciones =
           prescripciones ??
           const {
             TipoPrescripcion.suplemento: suplementosDePrueba,
             TipoPrescripcion.peptido: peptidosDePrueba,
             TipoPrescripcion.medicamento: medicamentosDePrueba,
           };

  /// Una fuente sin nada cargado, para probar los estados vacíos.
  factory PacienteFalso.vacia() => PacienteFalso(
    citas: const [],
    mediciones: const [],
    laboratorios: const [],
    recomendaciones: const [],
    prescripciones: const {},
  );

  final List<Cita> _citas;
  final List<Medicion> _mediciones;
  final List<Laboratorio> _laboratorios;
  final List<Recomendacion> _recomendaciones;
  final Map<TipoPrescripcion, List<Prescripcion>> _prescripciones;

  /// Si está puesta, toda consulta falla con ella.
  FallaDatos? falla;

  Future<T> _responder<T>(T valor) async {
    if (falla case final f?) throw f;
    return valor;
  }

  @override
  Future<List<Cita>> citas() => _responder(_citas);

  @override
  Future<List<Medicion>> mediciones() => _responder(_mediciones);

  @override
  Future<List<Laboratorio>> laboratorios() => _responder(_laboratorios);

  @override
  Future<List<Recomendacion>> recomendaciones() => _responder(_recomendaciones);

  @override
  Future<List<Prescripcion>> prescripciones(TipoPrescripcion tipo) =>
      _responder(_prescripciones[tipo] ?? const []);

  List<Cita> citasDe(TipoCita tipo) =>
      _citas.where((c) => c.tipo == tipo).toList();
}

/// Fuente falsa del catálogo público.
class CatalogoFalso implements FuenteCatalogo {
  CatalogoFalso({
    List<CategoriaSuplemento>? categorias,
    List<Video>? videos,
    this.falla,
  }) : _categorias = categorias ?? categoriasDePrueba,
       _videos = videos ?? videosDePrueba;

  factory CatalogoFalso.vacio() =>
      CatalogoFalso(categorias: const [], videos: const []);

  final List<CategoriaSuplemento> _categorias;
  final List<Video> _videos;

  FallaDatos? falla;

  @override
  Future<List<CategoriaSuplemento>> categoriasDeSuplemento() async {
    if (falla case final f?) throw f;
    return _categorias;
  }

  @override
  Future<List<Video>> videos() async {
    if (falla case final f?) throw f;
    return _videos;
  }
}

/// Fuente falsa de módulos opcionales habilitados.
class ModulosFalsos implements FuenteModulos {
  const ModulosFalsos([this.claves = const {}]);

  final Set<String> claves;

  @override
  Future<Set<String>> habilitados() async => claves;
}
