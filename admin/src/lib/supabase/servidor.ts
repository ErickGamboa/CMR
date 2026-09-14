import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

import { entornoSupabase } from "./entorno";

/**
 * Cliente de Supabase para Server Components y Server Actions.
 *
 * Se crea uno por petición y nunca se guarda en una variable de módulo: en el
 * servidor, un cliente compartido mezclaría las sesiones de dos doctores
 * distintos atendidos al mismo tiempo.
 */
export async function clienteServidor() {
  const almacen = await cookies();
  const { url, llave } = entornoSupabase();

  return createServerClient(url, llave, {
    cookies: {
      getAll() {
        return almacen.getAll();
      },
      setAll(porEscribir) {
        try {
          for (const { name, value, options } of porEscribir) {
            almacen.set(name, value, options);
          }
        } catch {
          // Un Server Component no puede escribir cookies. No es un problema:
          // el middleware ya refrescó la sesión antes de llegar acá.
        }
      },
    },
  });
}

/**
 * El usuario de la sesión, o `null`.
 *
 * Siempre `getUser()` y nunca `getSession()`: `getSession()` lee la cookie sin
 * verificarla contra Supabase, así que confiar en ella del lado del servidor
 * es confiar en algo que el navegador podría haber inventado.
 */
export async function usuarioActual() {
  const supabase = await clienteServidor();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return user;
}
