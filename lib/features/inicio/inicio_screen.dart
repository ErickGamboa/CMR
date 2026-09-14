import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../../core/datos/modelos.dart';
import '../../core/datos/repositorio.dart';
import '../../core/modulos_habilitados.dart';
import '../../widgets/carga_de_datos.dart';
import '../../widgets/cmr_logo.dart';
import '../etiqueta/leer_etiqueta_screen.dart';
import '../laboratorios/laboratorios_screen.dart';
import '../mapeo/mapeo_screen.dart';
import '../recomendaciones/recomendaciones_screen.dart';
import '../resultados/resultados_screen.dart';
import '../videos/videos_screen.dart';
import 'modulos.dart';
import 'widgets/fila_modulos_secundarios.dart';
import 'widgets/resumen_salud.dart';
import 'widgets/tarjeta_proxima_cita.dart';

/// Lo que el Home necesita de la base: la cita que sigue y las mediciones.
typedef _Portada = ({Cita? proxima, List<Medicion> mediciones});

/// Pestaña de Inicio: próxima cita, accesos rápidos y resumen de salud.
class InicioScreen extends StatefulWidget {
  const InicioScreen({
    super.key,
    required this.auth,
    required this.onIrACitas,
    this.modulos,
    this.paciente,
    this.catalogo,
  });

  final ServicioAuth auth;

  /// Lleva al módulo de citas, que vive en la barra inferior.
  final VoidCallback onIrACitas;

  /// Qué módulos opcionales tiene prendidos el paciente. En la app sale de
  /// Supabase; los tests inyectan una fuente falsa.
  final FuenteModulos? modulos;

  /// Los datos del paciente. Se pasa también a los módulos secundarios que se
  /// abren desde acá, para que los tests puedan recorrerlos sin red.
  final FuentePaciente? paciente;

  /// El catálogo público (marcas de suplementos, videos).
  final FuenteCatalogo? catalogo;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // Se piden una sola vez por sesión de pantalla: la lista de módulos no
  // cambia mientras el paciente usa la app, la cambia el doctor.
  late final Future<Set<String>> _habilitados =
      (widget.modulos ?? const RepositorioModulos()).habilitados();

  FuentePaciente get _datos => widget.paciente ?? RepositorioPaciente();

  /// Se pide una sola vez y la usan los dos bloques del Home, que están
  /// separados por la fila de accesos.
  late final Future<_Portada> _portada = _cargarPortada();

  /// Las dos consultas salen juntas: son independientes y esperar una tras
  /// otra dejaría el Home a medio dibujar el doble de tiempo.
  Future<_Portada> _cargarPortada() async {
    final (citas, mediciones) = await (
      _datos.citas(),
      _datos.mediciones(),
    ).wait;

    final ahora = DateTime.now();
    // Las citas vienen de la más vieja a la más reciente, así que la primera
    // que todavía no pasó es la que sigue.
    final proxima = citas.where((c) => c.fecha.isAfter(ahora)).firstOrNull;

    return (proxima: proxima, mediciones: mediciones);
  }

  void _abrirSecundario(BuildContext context, ModuloSecundario modulo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (modulo) {
          ModuloSecundario.laboratorios => LaboratoriosScreen(
            fuente: widget.paciente,
          ),
          ModuloSecundario.resultados => ResultadosScreen(
            fuente: widget.paciente,
          ),
          ModuloSecundario.mapeo => const MapeoScreen(),
          ModuloSecundario.leerEtiqueta => const LeerEtiquetaScreen(),
          ModuloSecundario.recomendaciones => RecomendacionesScreen(
            fuente: widget.paciente,
          ),
          ModuloSecundario.videos => VideosScreen(fuente: widget.catalogo),
        },
      ),
    );
  }

  Future<void> _salir(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Vas a tener que volver a ingresar tus datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado ?? false) await widget.auth.salir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CmrLogo(variante: CmrLogoVariante.marca, alto: 24),
        actions: [
          IconButton(
            onPressed: () => _salir(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: ListView(
        // Padding horizontal cero: la fila de accesos rápidos maneja el suyo
        // para que pueda desbordar hasta el borde al hacer scroll.
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          CargaDeDatos<_Portada>(
            cargar: () => _portada,
            alCargar: const SizedBox.shrink(),
            alFallar: const SizedBox.shrink(),
            constructor: (context, datos) => switch (datos.proxima) {
              final cita? => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TarjetaProximaCita(cita: cita, onTap: widget.onIrACitas),
              ),
              null => const SizedBox.shrink(),
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<Set<String>>(
            future: _habilitados,
            builder: (context, snapshot) {
              // Mientras no se sepa, se reserva el alto y no se dibuja nada:
              // mostrar la fila corta y que después le brote una ficha se ve
              // peor que esperar los milisegundos que tarda la consulta.
              if (!snapshot.hasData && !snapshot.hasError) {
                return const SizedBox(height: FilaModulosSecundarios.alto);
              }

              final modulos = snapshot.hasData
                  ? ModuloSecundario.visibles(snapshot.data!)
                  : ModuloSecundario.abiertos;

              return FilaModulosSecundarios(
                modulos: modulos,
                onSeleccion: (m) => _abrirSecundario(context, m),
              );
            },
          ),
          const SizedBox(height: 20),
          CargaDeDatos<_Portada>(
            cargar: () => _portada,
            alCargar: const SizedBox.shrink(),
            alFallar: const SizedBox.shrink(),
            constructor: (context, datos) => datos.mediciones.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ResumenSalud(mediciones: datos.mediciones),
                  ),
          ),
        ],
      ),
    );
  }
}
