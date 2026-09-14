import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/servicio_auth.dart';
import '../../widgets/cmr_logo.dart';
import 'crear_cuenta_screen.dart';

/// Pantalla de ingreso.
///
/// Desde acá se puede pedir una cuenta, pero no recuperar la contraseña: eso
/// necesita correo saliente, que el proyecto todavía no tiene. Mientras tanto
/// lo resuelve el doctor asignando una desde el sitio.
///
/// Al abrir sesión, [AuthGate] cambia de pantalla solo: esta no navega.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _claveFocus = FocusNode();

  bool _claveVisible = false;
  bool _enviando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    _claveFocus.dispose();
    super.dispose();
  }

  /// Abre el registro y, si la solicitud salió, lo avisa acá.
  ///
  /// El aviso va en el login y no en la pantalla de registro porque registrarse
  /// no deja a nadie adentro: la persona vuelve justo a donde va a tener que
  /// entrar cuando la aprueben.
  Future<void> _abrirRegistro() async {
    final enviada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CrearCuentaScreen(auth: widget.auth),
      ),
    );

    if (!(enviada ?? false) || !mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 6),
          content: Text(
            'Tu solicitud se envió. La clínica la va a revisar y te va a '
            'habilitar la cuenta.',
          ),
        ),
      );
  }

  String? _validarCorreo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    // Suficiente para atajar errores de tipeo; la validación real la hace
    // el servidor de autenticación.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'El correo no tiene un formato válido';
    }
    return null;
  }

  String? _validarClave(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    return null;
  }

  Future<void> _autenticar() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorGeneral = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    try {
      await widget.auth.ingresar(
        correo: _correoCtrl.text.trim(),
        clave: _claveCtrl.text,
      );
      // No navegamos: AuthGate reacciona al cambio de sesión. Tampoco
      // apagamos _enviando, para que el spinner siga hasta que la pantalla
      // se reemplace y no haya un parpadeo del formulario.
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              // En tablet y en iPad el formulario no debe estirarse a lo ancho.
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: CmrLogo(ancho: 220)),
                      const SizedBox(height: 44),
                      Text(
                        'Inicia sesión',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accede a tu control metabólico y regenerativo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _correoCtrl,
                        enabled: !_enviando,
                        validator: _validarCorreo,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        onFieldSubmitted: (_) => _claveFocus.requestFocus(),
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'nombre@ejemplo.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _claveCtrl,
                        focusNode: _claveFocus,
                        enabled: !_enviando,
                        validator: _validarClave,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        obscureText: !_claveVisible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _autenticar(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _claveVisible = !_claveVisible),
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
                      ),
                      if (_errorGeneral != null) ...[
                        const SizedBox(height: 16),
                        _AvisoError(mensaje: _errorGeneral!),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _enviando ? null : _autenticar,
                        child: _enviando
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 16),
                      // Registrarse no entra a la app: manda una solicitud que
                      // la clínica revisa. Al volver de esa pantalla, el
                      // aviso sale acá mismo.
                      OutlinedButton(
                        onPressed: _enviando ? null : _abrirRegistro,
                        child: const Text('Crear una cuenta'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Si ya eres paciente y no puedes entrar, consulta en '
                        'recepción.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
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

/// Banda de error del formulario, para fallas que no pertenecen a un campo.
class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
