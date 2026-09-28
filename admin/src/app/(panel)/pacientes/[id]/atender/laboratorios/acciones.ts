"use server";

import { revalidatePath } from "next/cache";

import { clienteServidor } from "@/lib/supabase/servidor";

export type Resultado = { error: string | null; guardado: boolean };

type Analito = { id: string; nombre: string; unidad: string; orden: number };

/**
 * Carga un examen con los analitos que trae.
 *
 * El doctor no llena 21 casillas: escribe las que el laboratorio reportó y el
 * resto se ignora. Los nombres y las unidades salen de `catalogo_analitos`,
 * así que lo único que se escribe es el número.
 *
 * Sin rango de referencia, por decisión de la clínica: la app ya no dibuja la
 * línea "Ref." cuando viene vacía.
 */
export async function guardarLaboratorio(
  _anterior: Resultado,
  datos: FormData,
): Promise<Resultado> {
  const paciente = String(datos.get("paciente") ?? "");
  const fecha = String(datos.get("fecha") ?? "").trim();
  const nombre = String(datos.get("nombre") ?? "").trim();

  if (!paciente) return { error: "Falta el paciente.", guardado: false };
  if (!fecha) return { error: "Poné la fecha del examen.", guardado: false };
  if (!nombre) return { error: "Escribí de qué examen es.", guardado: false };

  const supabase = await clienteServidor();

  // El catálogo se relee acá: del formulario llega el valor, nunca el nombre
  // ni la unidad del analito.
  const { data: catalogo } = await supabase
    .from("catalogo_analitos")
    .select("id, nombre, unidad, orden")
    .eq("activo", true)
    .order("orden", { ascending: true });

  const analisis: {
    nombre: string;
    valor: string;
    unidad: string;
    orden: number;
  }[] = [];

  for (const a of (catalogo ?? []) as Analito[]) {
    const valor = String(datos.get(`valor.${a.id}`) ?? "").trim();
    if (!valor) continue;

    analisis.push({
      nombre: a.nombre,
      valor,
      unidad: a.unidad,
      orden: a.orden,
    });
  }

  // Las filas en blanco, para lo que el laboratorio reportó y no está en el
  // catálogo. Van al final, en el orden en que se escribieron.
  for (const [i, sufijo] of ["1", "2", "3"].entries()) {
    const nombreLibre = String(datos.get(`libre.nombre.${sufijo}`) ?? "").trim();
    const valorLibre = String(datos.get(`libre.valor.${sufijo}`) ?? "").trim();
    if (!nombreLibre || !valorLibre) continue;

    analisis.push({
      nombre: nombreLibre,
      valor: valorLibre,
      unidad: String(datos.get(`libre.unidad.${sufijo}`) ?? "").trim(),
      orden: 100 + i,
    });
  }

  if (analisis.length === 0) {
    return { error: "No escribiste ningún resultado.", guardado: false };
  }

  const { data: creado, error: errorLab } = await supabase
    .from("laboratorios")
    .insert({ paciente_id: paciente, fecha, nombre })
    .select("id")
    .single();

  if (errorLab || !creado) {
    return { error: "No pudimos guardarlo. Intentá de nuevo.", guardado: false };
  }

  const { error: errorAnalisis } = await supabase
    .from("laboratorio_analisis")
    .insert(
      analisis.map((a) => ({ ...a, laboratorio_id: creado.id, referencia: "" })),
    );

  if (errorAnalisis) {
    // Un examen sin resultados no le sirve a nadie y quedaría como una fecha
    // vacía en la app: se deshace.
    await supabase.from("laboratorios").delete().eq("id", creado.id);
    return {
      error: "Guardamos el examen pero no los resultados. Intentá de nuevo.",
      guardado: false,
    };
  }

  revalidatePath(`/pacientes/${paciente}/atender/laboratorios`);
  return { error: null, guardado: true };
}

export async function borrarLaboratorio(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase.from("laboratorios").delete().eq("id", id);

  if (error) return { error: "No pudimos borrarlo." };

  revalidatePath(`/pacientes/${paciente}/atender/laboratorios`);
  return { error: null };
}

/**
 * Vacía todos los exámenes del paciente.
 *
 * Los resultados de cada uno se van con él: `laboratorio_analisis` cuelga de
 * `laboratorios` con `on delete cascade`.
 */
export async function limpiarLaboratorios(paciente: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("laboratorios")
    .delete()
    .eq("paciente_id", paciente);

  if (error) return { error: "No pudimos limpiarlos." };

  revalidatePath(`/pacientes/${paciente}/atender/laboratorios`);
  return { error: null };
}
