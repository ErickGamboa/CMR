"use server";

import { revalidatePath } from "next/cache";

import { cargarPlantilla } from "@/lib/catalogo";
import {
  armarPrescripcion,
  faltantes,
  type DatosAgregar,
} from "@/lib/indicaciones";
import { clienteServidor } from "@/lib/supabase/servidor";

export type Resultado = { error: string | null };

/**
 * Indica un suplemento, un péptido o un medicamento.
 *
 * Igual que con las recomendaciones: del navegador llegan el id de la
 * plantilla y los valores escogidos, y los cuatro pedazos que ve el paciente
 * se arman acá con la plantilla leída de la base.
 */
export async function agregarPrescripcion(
  paciente: string,
  datos: DatosAgregar,
): Promise<Resultado> {
  if (!paciente) return { error: "Falta el paciente." };

  const plantilla = await cargarPlantilla(datos.plantillaId);
  if (!plantilla || plantilla.tipo === "recomendacion") {
    return { error: "Eso ya no está en el catálogo." };
  }

  let fila;

  if (plantilla.libre) {
    const nombre = (datos.libre?.nombre ?? "").trim();
    const dosis = (datos.libre?.dosis ?? "").trim();
    const frecuencia = (datos.libre?.frecuencia ?? "").trim();

    if (!nombre) return { error: "Escribí el nombre." };
    if (!dosis) return { error: "Escribí la dosis." };
    if (!frecuencia) return { error: "Escribí la frecuencia." };

    fila = {
      nombre,
      dosis,
      frecuencia,
      indicacion: (datos.libre?.indicacion ?? "").trim() || null,
    };
  } else {
    const faltan = faltantes(plantilla, datos.valores);
    if (faltan.length > 0) {
      return {
        error: `Falta ${faltan.map((c) => c.etiqueta).join(", ").toLowerCase()}.`,
      };
    }

    fila = armarPrescripcion(plantilla, datos.valores);
  }

  const supabase = await clienteServidor();
  const { error } = await supabase.from("prescripciones").insert({
    paciente_id: paciente,
    tipo: plantilla.tipo,
    ...fila,
    plantilla_id: plantilla.id,
    valores: plantilla.libre ? null : datos.valores,
  });

  if (error) return { error: "No pudimos guardarla. Intentá de nuevo." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}

/**
 * Suspender no es borrar: el historial se conserva y la app deja de mostrarlo.
 * Borrar de verdad se deja para lo que se cargó por error.
 */
export async function cambiarActivo(
  paciente: string,
  id: string,
  activo: boolean,
) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("prescripciones")
    .update({ activo })
    .eq("id", id);

  if (error) return { error: "No pudimos cambiarla." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}

export async function borrarPrescripcion(paciente: string, id: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase.from("prescripciones").delete().eq("id", id);

  if (error) return { error: "No pudimos borrarla." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}

/**
 * Vacía un tipo entero: todos los suplementos, todos los péptidos o todos los
 * medicamentos.
 *
 * Va por tipo y no todo junto porque replantear la suplementación no tiene por
 * qué llevarse los medicamentos que el paciente toma por otra cosa.
 *
 * Acá sí se borra en vez de suspender: suspender conserva el historial de lo
 * que tomó, y quien aprieta "limpiar todo" está diciendo que esa lista se
 * rehace desde cero.
 */
export async function limpiarPrescripciones(paciente: string, tipo: string) {
  const supabase = await clienteServidor();
  const { error } = await supabase
    .from("prescripciones")
    .delete()
    .eq("paciente_id", paciente)
    .eq("tipo", tipo);

  if (error) return { error: "No pudimos limpiarlos." };

  revalidatePath(`/pacientes/${paciente}/atender/prescripciones`);
  return { error: null };
}
