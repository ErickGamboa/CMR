"use server";

import { revalidatePath } from "next/cache";

import { crearPaciente } from "@/lib/supabase/admin";

export type EstadoAlta = {
  error: string | null;
  /** Solo viene una vez, justo después de crear la cuenta. */
  creado: { id: string; nombre: string; correo: string; clave: string } | null;
};

// Ojo: un archivo "use server" solo puede exportar funciones async. El
// estado inicial es un objeto, así que vive en el componente que lo usa; si se
// exporta desde acá, la página revienta en tiempo de ejecución (y `next build`
// no lo detecta).

function limpio(valor: FormDataEntryValue | null) {
  return String(valor ?? "").trim();
}

export async function darDeAlta(
  _anterior: EstadoAlta,
  datos: FormData,
): Promise<EstadoAlta> {
  const correo = limpio(datos.get("correo")).toLowerCase();
  const nombre = limpio(datos.get("nombre"));
  const apellidos = limpio(datos.get("apellidos"));
  const cedula = limpio(datos.get("cedula"));
  const telefono = limpio(datos.get("telefono"));

  if (!nombre) return { error: "Escribe el nombre.", creado: null };
  if (!correo) return { error: "Escribe el correo.", creado: null };

  // El correo es de quien se olvida la contraseña: si está mal escrito, el
  // paciente no puede recuperarla y hay que volver a crearle la cuenta.
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) {
    return { error: "Ese correo no parece válido.", creado: null };
  }

  const r = await crearPaciente({
    correo,
    nombre,
    apellidos: apellidos || null,
    cedula: cedula || null,
    telefono: telefono || null,
  });

  if (!r.ok) return { error: r.error, creado: null };

  revalidatePath("/pacientes");

  return {
    error: null,
    creado: {
      id: r.id,
      nombre: [nombre, apellidos].filter(Boolean).join(" "),
      correo,
      clave: r.clave,
    },
  };
}
