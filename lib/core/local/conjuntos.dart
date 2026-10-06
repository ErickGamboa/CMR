import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/libro/repositorio_libro.dart';
import '../../features/mapeo/repositorio_mapeo.dart';
import '../../features/plan/repositorio_plan.dart';
import '../../widgets/recarga.dart';
import '../datos/repositorio.dart';
import '../modulos_habilitados.dart';
import 'almacen_local.dart';
import 'sincronizador.dart';

/// Todo lo que la app guarda en el teléfono.
///
/// Es la lista completa en un solo lugar: una pantalla nueva que lea de
/// Supabase y no esté acá no se va a ver sin internet.
const conjuntos = [
  Conjunto(Claves.citas, DescargasPaciente.citas),
  Conjunto(Claves.mediciones, DescargasPaciente.mediciones),
  Conjunto(Claves.laboratorios, DescargasPaciente.laboratorios),
  Conjunto(Claves.recomendaciones, DescargasPaciente.recomendaciones),
  Conjunto(Claves.prescripciones, DescargasPaciente.prescripciones),
  Conjunto(Claves.plan, bajarPlan),
  Conjunto(Claves.modulos, bajarModulos),
  Conjunto(Claves.mapeo, bajarMapeo, modulo: 'mapeo'),
  Conjunto(Claves.suplementos, DescargasCatalogo.suplementos, publico: true),
  Conjunto(Claves.videos, DescargasCatalogo.videos, publico: true),
  Conjunto(Claves.libro, bajarLibro, publico: true),
];

/// Abre la copia local y deja listo el sincronizador de la app.
///
/// Si SQLite no abre, sigue con una copia en memoria: la app funciona igual
/// con internet, y lo único que se pierde es verla sin conexión después de
/// cerrarla.
Future<Sincronizador> arrancarDatosLocales(SupabaseClient cliente) async {
  AlmacenLocal almacen;
  try {
    almacen = await AlmacenSqlite.abrir();
  } on Object catch (e) {
    debugPrint('No se pudo abrir la base local, sigue en memoria: $e');
    almacen = AlmacenEnMemoria();
  }

  late final Sincronizador sincronizador;
  sincronizador = Sincronizador(
    almacen: almacen,
    cliente: cliente,
    conjuntos: conjuntos,
    subidas: [() => ColaMapeo(sincronizador).subir()],
    recarga: recargaGlobal,
  );

  Sincronizador.actual = sincronizador;
  recargaGlobal.sincronizar = sincronizador.sincronizar;
  return sincronizador;
}
