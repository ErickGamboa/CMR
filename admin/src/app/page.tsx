import Link from "next/link";

import { FormularioIngreso } from "@/components/formulario-ingreso";
import { Logo } from "@/components/logo";
import { Card, CardContent } from "@/components/ui/card";

/**
 * La portada del sitio es el login.
 *
 * No hay página de bienvenida de por medio: el panel es una herramienta de
 * trabajo, y quien llega acá viene a entrar. Entrar tampoco distingue tipos de
 * cuenta; el que no sea doctor pasa esta puerta y se topa con la siguiente.
 */
export default async function Portada({
  searchParams,
}: {
  searchParams: Promise<{ volver?: string }>;
}) {
  const { volver } = await searchParams;

  return (
    <main className="relative flex min-h-dvh flex-col items-center justify-center overflow-hidden bg-muted/30 p-4 sm:p-6">
      <Fondo />

      {/* La misma navegación que llevan privacidad y soporte, para que las
          tres se sientan un solo sitio. Arriba y no en el pie porque en un
          teléfono el pie de esta pantalla queda debajo del teclado. */}
      <nav className="absolute inset-x-0 top-0 flex justify-end gap-5 px-5 py-4 text-sm text-muted-foreground sm:px-7">
        <Link
          href="/privacidad"
          className="underline-offset-4 transition-colors hover:text-foreground hover:underline"
        >
          Privacidad
        </Link>
        <Link
          href="/soporte"
          className="underline-offset-4 transition-colors hover:text-foreground hover:underline"
        >
          Soporte
        </Link>
      </nav>

      <div className="animate-in fade-in slide-in-from-bottom-2 duration-500 relative w-full max-w-sm space-y-8">
        <div className="flex flex-col items-center gap-4 text-center">
          <Logo variante="completo" alto={80} prioridad />
          <p className="text-sm font-medium tracking-wide text-muted-foreground">
            Panel de la clínica
          </p>
        </div>

        <Card className="shadow-sm">
          <CardContent className="pt-2">
            <FormularioIngreso volver={volver ?? ""} />
          </CardContent>
        </Card>

        <p className="text-center text-xs leading-relaxed text-muted-foreground">
          Este panel es para el equipo de la clínica.
          <br />
          Si sos paciente, tu seguimiento está en la app CMR.
        </p>
      </div>

    </main>
  );
}

/**
 * Dos manchas muy tenues en los colores de marca.
 *
 * Se quedan en el 10–14% de opacidad a propósito: el logo y el formulario van
 * encima y el contraste del texto no puede depender de dónde caiga la mancha.
 */
function Fondo() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0">
      <div className="absolute -left-32 -top-32 size-96 rounded-full bg-[#86dbfb] opacity-[0.14] blur-3xl" />
      <div className="absolute -bottom-40 -right-24 size-[28rem] rounded-full bg-[#62a1a6] opacity-10 blur-3xl" />
    </div>
  );
}
