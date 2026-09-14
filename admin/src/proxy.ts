import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

import { entornoSupabase } from "@/lib/supabase/entorno";

/**
 * Refresca la sesión en cada petición y manda al login a quien no la tenga.
 *
 * Los tokens de Supabase vencen; sin este refresco, el doctor quedaría
 * deslogueado a media jornada. El proxy es el único lugar donde se pueden
 * escribir las cookies nuevas antes de que cualquier página las lea.
 *
 * Ojo con la mecánica de abajo: hay que escribir las cookies en la petición
 * *y* en la respuesta. En la petición para que lo que se renderice después vea
 * la sesión fresca; en la respuesta para que el navegador se la guarde.
 */
export async function proxy(peticion: NextRequest) {
  let respuesta = NextResponse.next({ request: peticion });
  const { url, llave } = entornoSupabase();

  const supabase = createServerClient(url, llave, {
    cookies: {
      getAll() {
        return peticion.cookies.getAll();
      },
      setAll(porEscribir) {
        for (const { name, value } of porEscribir) {
          peticion.cookies.set(name, value);
        }
        respuesta = NextResponse.next({ request: peticion });
        for (const { name, value, options } of porEscribir) {
          respuesta.cookies.set(name, value, options);
        }
      },
    },
  });

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const ruta = peticion.nextUrl.pathname;
  const enLogin = ruta.startsWith("/ingresar");

  if (!user && !enLogin) {
    const destino = peticion.nextUrl.clone();
    destino.pathname = "/ingresar";
    // Para devolverlo a donde iba después de entrar.
    destino.searchParams.set("volver", ruta);
    return NextResponse.redirect(destino);
  }

  if (user && enLogin) {
    const destino = peticion.nextUrl.clone();
    destino.pathname = "/pacientes";
    destino.search = "";
    return NextResponse.redirect(destino);
  }

  return respuesta;
}

export const config = {
  // Todo menos los archivos estáticos y el favicon: no tiene sentido pedirle
  // la sesión a Supabase para servir una imagen.
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
