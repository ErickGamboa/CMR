import 'package:flutter/material.dart';

import '../../core/auth/servicio_auth.dart';
import '../../widgets/cmr_logo.dart';
import '../../widgets/ocultar_teclado.dart';

/// Registro del paciente.
///
/// Crear la cuenta **no** abre la app: queda esperando que la clínica la
/// apruebe. La pantalla lo dice desde el principio para que nadie se registre
/// creyendo que va a entrar de una y piense que algo falló.
class CrearCuentaScreen extends StatefulWidget {
  const CrearCuentaScreen({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _cedula = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _cedula.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    OcultarTeclado.soltarFoco();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await widget.auth.registrar(
        correo: _correo.text.trim(),
        clave: _clave.text,
        nombre: _nombre.text.trim(),
        apellidos: _apellidos.text.trim().isEmpty
            ? null
            : _apellidos.text.trim(),
        cedula: _cedula.text.trim().isEmpty ? null : _cedula.text.trim(),
      );
      if (!mounted) return;
      setState(() => _enviando = false);
      // Vuelve al login con el aviso. No queda sesión abierta: la solicitud
      // está enviada y todavía no la aprueba nadie.
      Navigator.of(context).pop(true);
    } on FallaAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(child: CmrLogo(alto: 56)),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'La clínica tiene que aprobar tu cuenta antes '
                                'de que puedas usar la app. Usá los mismos '
                                'datos con que te atienden.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _Campo(
                        controlador: _nombre,
                        etiqueta: 'Nombre',
                        autofill: const [AutofillHints.givenName],
                        validar: (v) => v.isEmpty ? 'Escribe tu nombre' : null,
                      ),
                      const SizedBox(height: 14),
                      _Campo(
                        controlador: _apellidos,
                        etiqueta: 'Apellidos',
                        autofill: const [AutofillHints.familyName],
                      ),
                      const SizedBox(height: 14),
                      _Campo(
                        controlador: _cedula,
                        etiqueta: 'Cédula',
                        ayuda: 'Con esto la clínica te reconoce.',
                      ),
                      const SizedBox(height: 14),
                      _Campo(
                        controlador: _correo,
                        etiqueta: 'Correo',
                        tipo: TextInputType.emailAddress,
                        autofill: const [AutofillHints.email],
                        ayuda:
                            'Por acá recuperás tu contraseña si se te '
                            'olvida.',
                        validar: (v) {
                          if (v.isEmpty) return 'Escribe tu correo';
                          final ok = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(v);
                          return ok ? null : 'Ese correo no parece válido';
                        },
                      ),
                      const SizedBox(height: 14),
                      _Campo(
                        controlador: _clave,
                        etiqueta: 'Contraseña',
                        oculto: true,
                        autofill: const [AutofillHints.newPassword],
                        ayuda: 'Al menos 6 caracteres.',
                        validar: (v) =>
                            v.length < 6 ? 'Usa al menos 6 caracteres' : null,
                        onEnviar: _registrar,
                      ),

                      if (_error case final error?) ...[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _enviando ? null : _registrar,
                        child: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.controlador,
    required this.etiqueta,
    this.tipo,
    this.oculto = false,
    this.ayuda,
    this.autofill,
    this.validar,
    this.onEnviar,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final TextInputType? tipo;
  final bool oculto;
  final String? ayuda;
  final List<String>? autofill;
  final String? Function(String)? validar;
  final VoidCallback? onEnviar;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipo,
      obscureText: oculto,
      autofillHints: autofill,
      textInputAction: onEnviar != null
          ? TextInputAction.done
          : TextInputAction.next,
      textCapitalization: oculto || tipo == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      onFieldSubmitted: (_) => onEnviar?.call(),
      validator: validar == null ? null : (v) => validar!((v ?? '').trim()),
      decoration: InputDecoration(labelText: etiqueta, helperText: ayuda),
    );
  }
}
