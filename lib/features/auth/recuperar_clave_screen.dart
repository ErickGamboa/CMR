import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/servicio_auth.dart';

/// Recuperar la contraseña desde la app, sin pasar por la clínica.
///
/// **Todavía no está enlazada.** Mandar el código necesita un proveedor de
/// correo saliente en Supabase, y sin eso el servidor de cortesía entrega dos
/// mensajes por hora y solo a direcciones del equipo del proyecto: a un
/// paciente no le llega nunca. Queda acá, con sus tests, para enlazarla desde
/// [LoginScreen] el día que el correo salga; hace falta además que la
/// plantilla «Reset Password» de Supabase incluya `{{ .Token }}`, que es
/// `supabase/plantillas/correo_recuperar_clave.html`.
///
/// Va con un código de seis dígitos y no con un enlace del correo. Un enlace
/// tendría que volver a abrir la app desde el navegador, y eso depende de que
/// el sistema operativo asocie bien el dominio: cuando falla, la persona
/// termina en una página en blanco sin entender por qué. Un código se escribe
/// donde ya está parada.
///
/// Devuelve `true` al cerrarse si la contraseña quedó cambiada.
class RecuperarClaveScreen extends StatefulWidget {
  const RecuperarClaveScreen({super.key, required this.auth, this.correo});

  final ServicioAuth auth;

  /// Lo que la persona ya había escrito en el login, para no pedírselo dos
  /// veces.
  final String? correo;

  @override
  State<RecuperarClaveScreen> createState() => _RecuperarClaveScreenState();
}

class _RecuperarClaveScreenState extends State<RecuperarClaveScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _correoCtrl = TextEditingController(text: widget.correo ?? '');
  final _codigoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();

  /// Falso mientras se pide el código; verdadero cuando ya se mandó.
  bool _codigoPedido = false;
  bool _claveVisible = false;
  bool _enviando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  String? _validarCorreo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'El correo no tiene un formato válido';
    }
    return null;
  }

  Future<void> _pedirCodigo() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorGeneral = null);

    if (_validarCorreo(_correoCtrl.text) != null) {
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _enviando = true);

    try {
      await widget.auth.pedirCodigoDeRecuperacion(_correoCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _codigoPedido = true;
      });
    } on FallaAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorGeneral = e.mensaje;
      });
    }
  }

  Future<void> _cambiar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorGeneral = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      await widget.auth.cambiarClaveConCodigo(
        correo: _correoCtrl.text.trim(),
        codigo: _codigoCtrl.text.trim(),
        clave: _claveCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FallaAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorGeneral = e.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _codigoPedido
                          ? 'Si ese correo tiene una cuenta, te mandamos un '
                                'código de 6 dígitos. Escribilo acá junto con '
                                'la contraseña nueva.'
                          : 'Escribí el correo de tu cuenta y te mandamos un '
                                'código para poner una contraseña nueva.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _correoCtrl,
                      // Después de pedir el código el correo se queda quieto:
                      // cambiarlo acá dejaría el código de un correo con la
                      // dirección de otro.
                      enabled: !_codigoPedido,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: _validarCorreo,
                    ),

                    if (_codigoPedido) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codigoCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Código del correo',
                          hintText: '000000',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        validator: (valor) {
                          final v = valor?.trim() ?? '';
                          if (v.isEmpty) return 'Escribe el código';
                          if (v.length < 6) return 'Son 6 dígitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _claveCtrl,
                        obscureText: !_claveVisible,
                        decoration: InputDecoration(
                          labelText: 'Contraseña nueva',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _claveVisible = !_claveVisible,
                            ),
                            icon: Icon(
                              _claveVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            tooltip: _claveVisible
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                          ),
                        ),
                        validator: (valor) {
                          final v = valor ?? '';
                          if (v.isEmpty) return 'Ingresa la contraseña nueva';
                          if (v.length < 8) {
                            return 'Debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_errorGeneral != null) ...[
                      const SizedBox(height: 16),
                      _Aviso(mensaje: _errorGeneral!),
                    ],

                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _enviando
                          ? null
                          : (_codigoPedido ? _cambiar : _pedirCodigo),
                      child: _enviando
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _codigoPedido
                                  ? 'Cambiar contraseña'
                                  : 'Enviar código',
                            ),
                    ),

                    if (_codigoPedido) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _enviando ? null : _pedirCodigo,
                        child: const Text('No me llegó, mandalo de nuevo'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
