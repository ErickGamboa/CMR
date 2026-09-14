"use server";

import { redirect } from "next/navigation";

import { clienteServidor } from "@/lib/supabase/servidor";

export type EstadoIngreso = { error: string | null };

/**
 * Inicia sesión con correo y contraseña.
 *
 * Las cuentas las crea el doctor desde el panel de Supabase: acá no hay
 * registro ni recuperación de contraseña, igual que en la app del paciente.
 */
export async function ingresar(
  _anterior: EstadoIngreso,
  datos: FormData,
): Promise<EstadoIngreso> {
  const correo = String(datos.get("correo") ?? "").trim();
  const clave = String(datos.get("clave") ?? "");

  if (!correo) return { error: "Escribe tu correo." };
  if (!clave) return { error: "Escribe tu contraseña." };

  const supabase = await clienteServidor();
  const { error } = await supabase.auth.signInWithPassword({
    email: correo,
    password: clave,
  });

  if (error) {
    // No se distingue "correo que no existe" de "contraseña incorrecta": decir
    // cuál de las dos falló le confirmaría a un extraño qué correos tienen
    // cuenta en la clínica.
    return { error: "Correo o contraseña incorrectos." };
  }

  const volver = String(datos.get("volver") ?? "");
  // Solo rutas internas: un `volver` con dominio ajeno convertiría el login en
  // un trampolín para mandar gente a otro sitio.
  const destino = volver.startsWith("/") && !volver.startsWith("//")
    ? volver
    : "/pacientes";

  redirect(destino);
}

export async function salir() {
  const supabase = await clienteServidor();
  await supabase.auth.signOut();
  redirect("/ingresar");
}
