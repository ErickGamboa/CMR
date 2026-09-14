import { ChevronLeft, ChevronRight } from "lucide-react";
import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { buscarPaso, type ClavePaso } from "@/lib/pasos";

/**
 * El cuerpo de un paso: título, contenido, y avanzar o retroceder.
 *
 * Todos los pasos comparten esta forma para que el doctor no tenga que volver
 * a aprender dónde están las cosas en cada uno.
 */
export function Paso({
  clave,
  id,
  children,
}: {
  clave: ClavePaso;
  id: string;
  children: React.ReactNode;
}) {
  const encontrado = buscarPaso(clave);
  if (!encontrado) return null;

  const { paso, numero, anterior, siguiente } = encontrado;
  const base = `/pacientes/${id}/atender`;

  return (
    // La llave hace que React remonte al cambiar de paso, y con eso la
    // animación de entrada se dispara en cada uno.
    <section
      key={clave}
      className="animate-in fade-in slide-in-from-bottom-1 duration-300 space-y-6"
    >
      <div className="space-y-1">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Paso {numero}
        </p>
        <h2 className="text-xl font-semibold tracking-tight">{paso.titulo}</h2>
        <p className="max-w-prose text-sm leading-relaxed text-muted-foreground">
          {paso.detalle}
        </p>
      </div>

      {children}

      <nav
        aria-label="Navegación entre pasos"
        className="flex items-center justify-between gap-3 border-t pt-6"
      >
        {anterior ? (
          <Link
            href={`${base}/${anterior.clave}`}
            className={buttonVariants({
              variant: "ghost",
              className: "group gap-1.5",
            })}
          >
            <ChevronLeft
              aria-hidden
              className="size-4 transition-transform duration-200 group-hover:-translate-x-0.5"
            />
            <span className="hidden sm:inline">{anterior.titulo}</span>
            <span className="sm:hidden">Anterior</span>
          </Link>
        ) : (
          <span />
        )}

        {siguiente ? (
          <Link
            href={`${base}/${siguiente.clave}`}
            className={buttonVariants({ className: "group gap-1.5" })}
          >
            <span className="hidden sm:inline">{siguiente.titulo}</span>
            <span className="sm:hidden">Siguiente</span>
            <ChevronRight
              aria-hidden
              className="size-4 transition-transform duration-200 group-hover:translate-x-0.5"
            />
          </Link>
        ) : (
          <Link
            href={`/pacientes/${id}`}
            className={buttonVariants({ variant: "outline" })}
          >
            Terminar consulta
          </Link>
        )}
      </nav>
    </section>
  );
}

/** Lo que se muestra en un paso que todavía no tiene pantalla. */
export function PasoPendiente({ detalle }: { detalle: string }) {
  return (
    <div className="flex min-h-[28vh] items-center justify-center rounded-xl border border-dashed">
      <div className="max-w-sm space-y-2 px-6 py-10 text-center">
        <p className="text-sm font-medium">Pantalla pendiente</p>
        <p className="text-sm leading-relaxed text-muted-foreground">
          {detalle}
        </p>
      </div>
    </div>
  );
}
