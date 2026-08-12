import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/servicio_auth.dart';
import '../../widgets/cmr_logo.dart';

/// Pantalla de ingreso.
///
/// Las cuentas las administra el admin desde el sitio web, así que acá no hay
/// registro ni recuperación de contraseña. Al abrir sesión, [AuthGate] cambia
/// de pantalla solo: esta no navega.
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

  String? _validarCorreo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresá tu correo';
    // Suficiente para atajar errores de tipeo; la validación real la hace
    // el servidor de autenticación.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'El correo no tiene un formato válido';
    }
    return null;
  }

  String? _validarClave(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresá tu contraseña';
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
                        'Iniciá sesión',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accedé a tu control metabólico y regenerativo.',
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
                      const SizedBox(height: 24),
                      // Las cuentas las crea y administra el admin desde el
                      // sitio web: acá no hay registro ni recuperación de
                      // contraseña, así que el usuario necesita saber a dónde ir.
                      Text(
                        'Las credenciales las entrega tu administrador. '
                        'Si no podés ingresar, contactalo.',
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
