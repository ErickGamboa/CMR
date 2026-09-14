import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../../core/datos_demo.dart';
import '../../core/modulos_habilitados.dart';
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

/// Pestaña de Inicio: próxima cita, accesos rápidos y resumen de salud.
class InicioScreen extends StatefulWidget {
  const InicioScreen({
    super.key,
    required this.auth,
    required this.onIrACitas,
    this.modulos,
  });

  final ServicioAuth auth;

  /// Lleva al módulo de citas, que vive en la barra inferior.
  final VoidCallback onIrACitas;

  /// Qué módulos opcionales tiene prendidos el paciente. En la app sale de
  /// Supabase; los tests inyectan una fuente falsa.
  final FuenteModulos? modulos;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // Se pide una sola vez por sesión de pantalla: la lista de módulos no
  // cambia mientras el paciente usa la app, la cambia el doctor.
  late final Future<Set<String>> _habilitados =
      (widget.modulos ?? const RepositorioModulos()).habilitados();

  void _abrirSecundario(BuildContext context, ModuloSecundario modulo) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (modulo) {
          ModuloSecundario.laboratorios => const LaboratoriosScreen(),
          ModuloSecundario.resultados => const ResultadosScreen(),
          ModuloSecundario.mapeo => const MapeoScreen(),
          ModuloSecundario.leerEtiqueta => const LeerEtiquetaScreen(),
          ModuloSecundario.recomendaciones => const RecomendacionesScreen(),
          ModuloSecundario.videos => const VideosScreen(),
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
          if (DatosDemo.proximaCita case final cita?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TarjetaProximaCita(cita: cita, onTap: widget.onIrACitas),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ResumenSalud(mediciones: DatosDemo.mediciones),
          ),
        ],
      ),
    );
  }
}
