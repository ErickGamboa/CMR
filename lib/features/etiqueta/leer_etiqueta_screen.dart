import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/calculo_etiqueta.dart';
import '../../theme/app_colors.dart';

/// Explica cómo leer una etiqueta nutricional y calcula las equivalencias.
class LeerEtiquetaScreen extends StatefulWidget {
  const LeerEtiquetaScreen({super.key});

  @override
  State<LeerEtiquetaScreen> createState() => _LeerEtiquetaScreenState();
}

class _LeerEtiquetaScreenState extends State<LeerEtiquetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _grasa = TextEditingController();
  final _carbos = TextEditingController();
  final _fibra = TextEditingController();
  final _proteina = TextEditingController();

  PorcionesEtiqueta? _resultado;

  @override
  void dispose() {
    _grasa.dispose();
    _carbos.dispose();
    _fibra.dispose();
    _proteina.dispose();
    super.dispose();
  }

  /// Acepta coma o punto como separador decimal: en Costa Rica se escriben
  /// las dos formas y una etiqueta puede traer cualquiera.
  double _leer(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  void _calcular() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _resultado = calcularPorciones(
        grasaTotal: _leer(_grasa),
        carbohidratosTotales: _leer(_carbos),
        fibra: _leer(_fibra),
        proteina: _leer(_proteina),
      );
    });
  }

  void _limpiar() {
    FocusScope.of(context).unfocus();
    _grasa.clear();
    _carbos.clear();
    _fibra.clear();
    _proteina.clear();
    setState(() => _resultado = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Leer etiqueta')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Cómo leer una etiqueta', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const _Paso(
            numero: 1,
            texto:
                'Busca el tamaño de la porción y cuántas porciones trae el '
                'paquete. Todo lo demás está calculado sobre una sola porción.',
          ),
          const _Paso(
            numero: 2,
            texto:
                'Anota la grasa total, los carbohidratos totales, la fibra '
                'y la proteína. Son los cuatro números que ocupas.',
          ),
          const _Paso(
            numero: 3,
            texto:
                'La fibra no cuenta como carbohidrato: se resta de los '
                'carbohidratos totales antes de convertir.',
          ),
          const _Paso(
            numero: 4,
            texto:
                'Convierte los gramos a equivalencias con la calculadora de '
                'abajo y compáralos contra tu plan.',
          ),
          const SizedBox(height: 18),
          const _NotaPorcion(),
          const SizedBox(height: 28),
          Text('Calculadora', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Ingresa los gramos que dice la etiqueta por porción.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _CampoGramos(controlador: _grasa, etiqueta: 'Grasa total'),
                const SizedBox(height: 12),
                _CampoGramos(
                  controlador: _carbos,
                  etiqueta: 'Total de carbohidratos',
                ),
                const SizedBox(height: 12),
                _CampoGramos(controlador: _fibra, etiqueta: 'Fibra'),
                const SizedBox(height: 12),
                _CampoGramos(
                  controlador: _proteina,
                  etiqueta: 'Proteína',
                  ultimo: true,
                  onEnviar: _calcular,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _calcular, child: const Text('Calcular')),
          if (_resultado != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _limpiar, child: const Text('Limpiar')),
            const SizedBox(height: 24),
            _Resultado(porciones: _resultado!),
          ],
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Aviso de que todos los valores son por porción, no por paquete.
///
/// Va en turquesa y no en el azul del resto para que salte del texto corrido:
/// es el error más común al leer una etiqueta.
class _NotaPorcion extends StatelessWidget {
  const _NotaPorcion();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.turquesaBiocelular.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: AppColors.turquesaBiocelular, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.turquesaBiocelular,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todo es por porción',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Los valores de la etiqueta son de UNA porción, no del '
                  'paquete completo. Si el paquete trae 3 porciones y te lo '
                  'comes entero, multiplica todo por 3.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoGramos extends StatelessWidget {
  const _CampoGramos({
    required this.controlador,
    required this.etiqueta,
    this.ultimo = false,
    this.onEnviar,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final bool ultimo;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) => onEnviar?.call(),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: (v) {
        final texto = (v ?? '').trim();
        if (texto.isEmpty) return null; // vacío se toma como 0
        final n = double.tryParse(texto.replaceAll(',', '.'));
        if (n == null) return 'Escribe solo números';
        if (n < 0) return 'No puede ser negativo';
        return null;
      },
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: '0',
        suffixText: 'g',
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.porciones});

  final PorcionesEtiqueta porciones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EQUIVALENCIAS POR PORCIÓN',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.tertiary,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _Linea(
              etiqueta: 'Grasas',
              cantidad: porciones.grasas,
              regla: '5 g = 1',
            ),
            const SizedBox(height: 14),
            _Linea(
              etiqueta: 'Carbohidratos',
              cantidad: porciones.carbohidratos,
              regla:
                  '15 g = 1 · '
                  '${porciones.carbohidratosNetos.toStringAsFixed(porciones.carbohidratosNetos % 1 == 0 ? 0 : 1)} g netos',
            ),
            const SizedBox(height: 14),
            _Linea(
              etiqueta: 'Proteínas',
              cantidad: porciones.proteinas,
              regla: '7 g = 1',
            ),
          ],
        ),
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({
    required this.etiqueta,
    required this.cantidad,
    required this.regla,
  });

  final String etiqueta;
  final int cantidad;
  final String regla;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                regla,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Text(
          '$cantidad',
          key: ValueKey('equivalencias-$etiqueta'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: scheme.tertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
