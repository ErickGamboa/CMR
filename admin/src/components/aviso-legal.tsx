import { Building2 } from "lucide-react";

import { AVISO_LEGAL } from "@/lib/empresa";
import { cn } from "@/lib/utils";

/**
 * La razón social, a la vista.
 *
 * Por ahora va grande a propósito: la revisión de Apple busca el nombre legal
 * en el HTML y no tiene que costar encontrarlo. Es un componente de servidor
 * (sin "use client") para que el texto salga en el HTML crudo. Cuando pase la
 * revisión, se achica acá y queda achicado en todo el sitio.
 *
 * - `banda`: la franja del pie de página.
 * - `parrafo`: un bloque destacado dentro del contenido de una página.
 */
export function AvisoLegal({
  variante = "banda",
  className,
}: {
  variante?: "banda" | "parrafo";
  className?: string;
}) {
  if (variante === "parrafo") {
    return (
      <p
        className={cn(
          "flex items-start gap-3 rounded-xl border border-[#090972]/15 bg-[#f4f7fa] p-4 text-base font-medium leading-relaxed text-[#10102e]",
          className,
        )}
      >
        <Building2 aria-hidden className="mt-1 size-5 shrink-0 text-[#090972]" />
        <span>{AVISO_LEGAL}</span>
      </p>
    );
  }

  return (
    <div
      className={cn("border-t border-[#e1e6ee] bg-[#f4f7fa]", className)}
    >
      <p className="mx-auto flex max-w-7xl items-center justify-center gap-2.5 px-4 py-5 text-center text-sm font-semibold leading-relaxed text-[#10102e] sm:px-6 sm:text-base">
        <Building2 aria-hidden className="hidden size-5 shrink-0 text-[#090972] sm:block" />
        <span>{AVISO_LEGAL}</span>
      </p>
    </div>
  );
}
