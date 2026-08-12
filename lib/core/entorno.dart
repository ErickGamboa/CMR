/// Configuración inyectada en tiempo de compilación.
///
/// Se pasa con `--dart-define-from-file=config/supabase.json`. La clave
/// publicable de Supabase es pública por diseño (va en el cliente y está
/// limitada por RLS), pero igual se mantiene fuera del repo para poder rotarla
/// sin tocar el código.
abstract final class Entorno {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ofghnznmipwbjmpeyacg.supabase.co',
  );

  /// Acepta tanto la clave publicable moderna (`sb_publishable_...`) como la
  /// clave anon legacy en formato JWT.
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Falso si falta la clave: la app lo muestra en pantalla en vez de
  /// reventar en el arranque con un error ilegible.
  static bool get configurado =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
