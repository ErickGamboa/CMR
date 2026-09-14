import { ChevronLeft } from "lucide-react";
import Link from "next/link";

/**
 * El "volver" de la esquina superior izquierda.
 *
 * Dice a dónde vuelve, no solo "atrás": en un panel con tres niveles —lista,
 * ficha, consulta— una flecha sola obliga a acordarse de dónde venías. El
 * ícono se corre un poco al pasar el mouse, que es toda la animación que hace
 * falta para que se sienta vivo.
 */
export function Volver({ href, children }: { href: string; children: string }) {
  return (
    <Link
      href={href}
      className="group inline-flex items-center gap-1 rounded-md py-1 pr-2 text-sm font-medium text-muted-foreground outline-none transition-colors hover:text-foreground focus-visible:ring-2 focus-visible:ring-ring"
    >
      <ChevronLeft
        aria-hidden
        className="size-4 transition-transform duration-200 group-hover:-translate-x-0.5"
      />
      <span className="truncate">{children}</span>
    </Link>
  );
}
