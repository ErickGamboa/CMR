"use client";

import { ChevronRight } from "lucide-react";
import { useFormStatus } from "react-dom";

import { Button } from "@/components/ui/button";

/**
 * Pasar al siguiente paso.
 *
 * Es un botón de formulario y no un enlace porque acá pasa algo además de
 * navegar: este paso queda dado por visto. El palomeo del indicador sale de
 * apretar esto y de nada más — guardar no palomea, y saltar de paso tocando
 * un número del indicador tampoco. Así "hecho" quiere decir lo que el doctor
 * dijo que quiere decir, y no lo que la base alcanzó a deducir.
 */
export function Siguiente({
  titulo,
  accion,
}: {
  titulo: string;
  accion: () => Promise<void>;
}) {
  return (
    <form action={accion}>
      <Boton titulo={titulo} />
    </form>
  );
}

function Boton({ titulo }: { titulo: string }) {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending} className="group gap-1.5">
      <span className="hidden sm:inline">{titulo}</span>
      <span className="sm:hidden">Siguiente</span>
      <ChevronRight
        aria-hidden
        className="size-4 transition-transform duration-200 group-hover:translate-x-0.5"
      />
    </Button>
  );
}

/**
 * Cierra la consulta y vuelve a la ficha del paciente.
 *
 * Con eso los palomeos quedan en blanco para la próxima visita.
 */
export function TerminarConsulta({ accion }: { accion: () => Promise<void> }) {
  return (
    <form action={accion}>
      <BotonTerminar />
    </form>
  );
}

function BotonTerminar() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" variant="outline" disabled={pending}>
      {pending ? "Cerrando…" : "Terminar consulta"}
    </Button>
  );
}
