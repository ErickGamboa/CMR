import type { Metadata } from "next";

import { Logo } from "@/components/logo";
import { Card, CardContent } from "@/components/ui/card";

import { FormularioIngreso } from "./formulario";

export const metadata: Metadata = { title: "Entrar · CMR" };

export default async function PaginaIngreso({
  searchParams,
}: {
  searchParams: Promise<{ volver?: string }>;
}) {
  const { volver } = await searchParams;

  return (
    <main className="relative flex min-h-dvh items-center justify-center overflow-hidden p-6">
      <Fondo />

      <div className="relative w-full max-w-sm space-y-8">
        <div className="flex flex-col items-center gap-3 text-center">
          <Logo variante="completo" alto={84} prioridad />
          <p className="text-sm text-muted-foreground">
            Panel de la clínica
          </p>
        </div>

        <Card>
          <CardContent className="pt-6">
            <FormularioIngreso volver={volver ?? ""} />
          </CardContent>
        </Card>

        <p className="text-center text-xs text-muted-foreground">
          Las cuentas las crea la clínica. Si no podés entrar, avisá en
          recepción.
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
