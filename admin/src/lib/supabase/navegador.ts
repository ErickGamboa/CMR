import { createBrowserClient } from "@supabase/ssr";

import { entornoSupabase } from "./entorno";

/**
 * Cliente de Supabase para componentes del navegador.
 *
 * Solo hace falta donde el usuario interactúa de verdad (cerrar sesión, por
 * ejemplo). Todo lo que sea leer o escribir datos va por el servidor, que es
 * donde la sesión está verificada.
 */
export function clienteNavegador() {
  const { url, llave } = entornoSupabase();
  return createBrowserClient(url, llave);
}
