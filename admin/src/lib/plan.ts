/**
 * La tabla del plan de alimentación, tal como está en el papel.
 *
 * Archivo neutral —sin `"use client"` ni `"use server"`— porque el formulario
 * y la acción que guarda necesitan las mismas listas y el mismo parser.
 */

export const GRUPOS = [
  { valor: "carbohidratos", titulo: "Carbohidratos" },
  { valor: "proteinas", titulo: "Proteínas" },
  { valor: "lacteos", titulo: "Lácteos" },
  { valor: "vegetales", titulo: "Vegetales" },
  { valor: "frutas", titulo: "Frutas" },
  { valor: "grasas", titulo: "Grasas" },
] as const;

export const TIEMPOS = [
  { valor: "desayuno", titulo: "Desayuno", corto: "Desayuno" },
  {
    valor: "merienda_manana",
    titulo: "Merienda de la mañana",
    corto: "Merienda",
  },
  { valor: "almuerzo", titulo: "Almuerzo", corto: "Almuerzo" },
  {
    valor: "merienda_tarde",
    titulo: "Merienda de la tarde",
    corto: "Merienda",
  },
  { valor: "cena", titulo: "Cena", corto: "Cena" },
] as const;

export type Grupo = (typeof GRUPOS)[number]["valor"];
export type Tiempo = (typeof TIEMPOS)[number]["valor"];

export type Celda = { cantidad: number; esMinimo: boolean };

/**
 * Lee una celda como la escribe el doctor.
 *
 * Acepta lo mismo que dice el papel: un número, un número con `+` cuando es un
 * mínimo ("2+" son dos o más), y vacío o `-` cuando ese grupo no va en ese
 * tiempo. También coma decimal y `½`, porque se escriben las dos formas.
 *
 * Devuelve `null` para "no va" y `undefined` para "no se entiende", que son
 * cosas distintas: la primera se guarda como ausencia, la segunda es un error
 * que hay que mostrarle al doctor.
 */
export function leerCelda(texto: string): Celda | null | undefined {
  const limpio = texto.trim();
  if (limpio === "" || limpio === "-" || limpio === "—") return null;

  const esMinimo = limpio.endsWith("+");
  const numero = (esMinimo ? limpio.slice(0, -1) : limpio)
    .trim()
    .replace(",", ".")
    .replace("½", ".5");

  if (numero === "") return undefined;

  // ".5" solo es válido si vino de un ½; "1.5" y "0.5" se escriben igual.
  const n = Number(numero.startsWith(".") ? `0${numero}` : numero);
  if (!Number.isFinite(n) || n < 0 || n > 99) return undefined;

  // Un cero explícito sí se guarda: en el papel aparece "0" en proteínas de
  // la merienda, que no es lo mismo que un guion.
  return { cantidad: n, esMinimo };
}

/** Cómo se muestra una celda en el formulario. */
export function escribirCelda(celda: Celda | null): string {
  if (!celda) return "";

  const numero = Number.isInteger(celda.cantidad)
    ? String(celda.cantidad)
    : String(celda.cantidad).replace(".", ",");

  return celda.esMinimo ? `${numero}+` : numero;
}

/** El nombre del campo de una celda dentro del formulario. */
export function campoCelda(grupo: Grupo, tiempo: Tiempo) {
  return `celda.${grupo}.${tiempo}`;
}

/**
 * Suma una fila de la tabla.
 *
 * El total del día no se escribe: sale de lo que el doctor repartió entre los
 * tiempos de comida. Tenerlo aparte se prestaba a que la fila y el total
 * dijeran cosas distintas, y el paciente vería un número que no le cuadra con
 * el otro.
 *
 * Si alguna celda es un mínimo, el total también lo es: cinco "al menos" no
 * suman un número exacto.
 */
export function sumarFila(celdas: (Celda | null | undefined)[]): Celda | null {
  let cantidad = 0;
  let esMinimo = false;
  let hayAlguna = false;

  for (const c of celdas) {
    // Una celda que no se entiende no suma: el total se muestra con lo que
    // haya y el error se avisa al guardar.
    if (c === undefined || c === null) continue;

    cantidad += c.cantidad;
    esMinimo = esMinimo || c.esMinimo;
    hayAlguna = true;
  }

  return hayAlguna ? { cantidad, esMinimo } : null;
}
