/**
 * El catálogo de lo que el doctor receta, y cómo se arma una frase con él.
 *
 * Archivo neutral —sin `"use client"` ni `"use server"`— porque la pantalla
 * arma la vista previa con estas funciones y la acción que guarda vuelve a
 * armar lo mismo del lado del servidor. El navegador nunca decide qué se
 * escribe en la base: manda la plantilla y los valores, y el servidor rearma.
 */

export type TipoIndicacion =
  | "recomendacion"
  | "suplemento"
  | "peptido"
  | "medicamento";

export type CampoPlantilla = {
  clave: string;
  etiqueta: string;
  tipo: "numero" | "texto" | "opcion";
  /** Se muestra al lado de los botones: g, mg, UI. */
  unidad?: string;
  /** Los valores sugeridos. Sin opciones, el campo se escribe. */
  opciones?: (string | number)[];
  /** Lo que viene puesto de entrada ("400-800"). */
  valor?: string | number;
};

export type Plantilla = {
  id: string;
  tipo: TipoIndicacion;
  nombre: string;
  plantilla: string;
  campos: CampoPlantilla[];
  titulo: string | null;
  icono: string | null;
  libre: boolean;
  plantillaNombre: string | null;
  plantillaDosis: string | null;
  plantillaFrecuencia: string | null;
  plantillaIndicacion: string | null;
};

/** Lo que el doctor llenó, por clave de hueco. Siempre texto. */
export type Valores = Record<string, string>;

/**
 * Lo que la pantalla le manda al servidor cuando el doctor agrega algo.
 *
 * Van la plantilla y los valores, nunca la frase ya armada: el texto que se
 * guarda lo rearma el servidor con la plantilla que lee de la base. Lo que
 * llega del navegador es qué se eligió, no qué queda escrito en la ficha del
 * paciente.
 */
export type DatosAgregar = {
  plantillaId: string;
  valores: Valores;
  /** Solo para las plantillas libres, que no tienen frase que llenar. */
  libre?: Record<string, string>;
};

/** Un campo de los que se abren en blanco cuando la plantilla es libre. */
export type CampoLibre = {
  clave: string;
  etiqueta: string;
  /** Caja de varias líneas en vez de una sola. */
  largo?: boolean;
  /** Lista desplegable en vez de campo escrito. */
  opciones?: { valor: string; etiqueta: string }[];
  opcional?: boolean;
};

/** Cómo llega una fila de `catalogo_indicaciones` desde Supabase. */
export type FilaCatalogo = {
  id: string;
  tipo: string;
  nombre: string;
  plantilla: string;
  campos: unknown;
  titulo: string | null;
  icono: string | null;
  libre: boolean;
  plantilla_nombre?: string | null;
  plantilla_dosis?: string | null;
  plantilla_frecuencia?: string | null;
  plantilla_indicacion?: string | null;
};

export const COLUMNAS_CATALOGO =
  "id, tipo, nombre, plantilla, campos, titulo, icono, libre, " +
  "plantilla_nombre, plantilla_dosis, plantilla_frecuencia, plantilla_indicacion";

/**
 * Normaliza una fila del catálogo.
 *
 * `campos` llega como jsonb; si algún día trae algo que no es una lista, se
 * trata como plantilla sin huecos en vez de reventar la pantalla entera.
 */
export function leerPlantilla(fila: FilaCatalogo): Plantilla {
  return {
    id: fila.id,
    tipo: fila.tipo as TipoIndicacion,
    nombre: fila.nombre,
    plantilla: fila.plantilla,
    campos: Array.isArray(fila.campos) ? (fila.campos as CampoPlantilla[]) : [],
    titulo: fila.titulo,
    icono: fila.icono,
    libre: fila.libre,
    plantillaNombre: fila.plantilla_nombre ?? null,
    plantillaDosis: fila.plantilla_dosis ?? null,
    plantillaFrecuencia: fila.plantilla_frecuencia ?? null,
    plantillaIndicacion: fila.plantilla_indicacion ?? null,
  };
}

// ---------------------------------------------------------------------------
// Los huecos
// ---------------------------------------------------------------------------

const HUECO = /\{([a-z_]+)\}/g;

export type Parte =
  | { tipo: "texto"; texto: string }
  | { tipo: "hueco"; clave: string; texto: string; lleno: boolean };

/**
 * Parte una plantilla en pedazos de texto y huecos, ya resueltos.
 *
 * Sirve para dibujar la vista previa con los huecos sin llenar resaltados: el
 * doctor ve la frase que va a quedar mientras la arma, y ve exactamente qué
 * le falta.
 */
export function partir(plantilla: string, valores: Valores): Parte[] {
  const partes: Parte[] = [];
  let desde = 0;

  for (const m of plantilla.matchAll(HUECO)) {
    const i = m.index;
    if (i > desde) partes.push({ tipo: "texto", texto: plantilla.slice(desde, i) });

    const valor = (valores[m[1]] ?? "").trim();
    partes.push({
      tipo: "hueco",
      clave: m[1],
      texto: valor || "____",
      lleno: valor !== "",
    });

    desde = i + m[0].length;
  }

  if (desde < plantilla.length) {
    partes.push({ tipo: "texto", texto: plantilla.slice(desde) });
  }

  return partes;
}

/** La plantilla con los huecos puestos. Un hueco vacío queda como `____`. */
export function armar(plantilla: string, valores: Valores): string {
  return partir(plantilla, valores)
    .map((p) => p.texto)
    .join("")
    .replace(/\s+/g, " ")
    .trim();
}

/** Los huecos de una plantilla, en orden y sin repetir. */
export function huecos(plantilla: string): string[] {
  return [...new Set([...plantilla.matchAll(HUECO)].map((m) => m[1]))];
}

/**
 * Qué campos le faltan por llenar.
 *
 * Se mira contra `campos` y no contra los huecos del texto porque una
 * plantilla puede repetir el mismo hueco en la frase larga y en el pedazo de
 * la dosis, y eso es un solo dato.
 */
export function faltantes(p: Plantilla, valores: Valores): CampoPlantilla[] {
  return p.campos.filter((c) => !(valores[c.clave] ?? "").trim());
}

/** Los valores con los que abre una ficha: solo lo que trae valor propio. */
export function valoresIniciales(p: Plantilla): Valores {
  const v: Valores = {};
  for (const c of p.campos) {
    if (c.valor !== undefined && c.valor !== null) v[c.clave] = String(c.valor);
  }
  return v;
}

// ---------------------------------------------------------------------------
// De plantilla a fila
// ---------------------------------------------------------------------------

export type Prescripcion = {
  nombre: string;
  dosis: string;
  frecuencia: string;
  indicacion: string | null;
};

/**
 * Arma los cuatro pedazos que muestra la tarjeta de la app.
 *
 * Si la plantilla no declara el corte —una que alguien agregue después sin
 * llenar esas columnas— la frase entera cae en la indicación, que es el campo
 * en prosa. Queda feo pero no pierde nada de lo que el doctor indicó.
 */
export function armarPrescripcion(
  p: Plantilla,
  valores: Valores,
): Prescripcion {
  const nombre = p.plantillaNombre
    ? armar(p.plantillaNombre, valores)
    : p.nombre;

  if (p.plantillaDosis === null) {
    return {
      nombre,
      dosis: "Según indicación",
      frecuencia: "",
      indicacion: armar(p.plantilla, valores) || null,
    };
  }

  const indicacion = armar(p.plantillaIndicacion ?? "", valores);

  return {
    nombre,
    dosis: armar(p.plantillaDosis, valores),
    frecuencia: armar(p.plantillaFrecuencia ?? "", valores),
    indicacion: indicacion || null,
  };
}

export type Recomendacion = {
  titulo: string;
  texto: string;
  icono: string;
};

export function armarRecomendacion(
  p: Plantilla,
  valores: Valores,
): Recomendacion {
  return {
    titulo: p.titulo?.trim() || p.nombre,
    texto: armar(p.plantilla, valores),
    icono: p.icono?.trim() || "consejo",
  };
}

// ---------------------------------------------------------------------------
// Buscar
// ---------------------------------------------------------------------------

/** Sin tildes y en minúscula, para que "cafeina" encuentre "Cafeína". */
export function normalizar(texto: string) {
  return texto
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .trim();
}

export function filtrar(plantillas: Plantilla[], busqueda: string) {
  const q = normalizar(busqueda);
  if (!q) return plantillas;

  // Las libres ("Otro suplemento") siempre quedan: son la salida cuando lo que
  // se busca no está en la lista, que es justo cuando se busca y no aparece.
  return plantillas.filter(
    (p) => p.libre || normalizar(`${p.nombre} ${p.plantilla}`).includes(q),
  );
}
