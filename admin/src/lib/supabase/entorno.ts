/**
 * Las dos variables que el sitio necesita para hablar con Supabase.
 *
 * La llave publicable es pública por diseño: va dentro del navegador y lo que
 * protege los datos es RLS, no el secreto de la llave. Aun así se mantiene
 * fuera del repo para poder rotarla sin tocar el código.
 *
 * Acá NO va `service_role`. Se salta RLS por completo, y todo el sitio está
 * construido sobre la idea contraria: el doctor escribe con su propia sesión y
 * es la base la que decide qué puede tocar.
 */
export function entornoSupabase() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const llave = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !llave) {
    // Sin esto el error real sería un "fetch failed" contra `undefined`, que
    // no dice qué falta ni dónde ponerlo.
    throw new Error(
      "Faltan NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY. " +
        "Copiá admin/.env.example a admin/.env.local y llenálas.",
    );
  }

  return { url, llave };
}
