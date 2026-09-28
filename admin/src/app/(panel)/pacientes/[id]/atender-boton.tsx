"use client";

import { useFormStatus } from "react-dom";

import { Button } from "@/components/ui/button";

/**
 * El botón con el que empieza una consulta.
 *
 * Es un formulario y no un enlace porque entrar a atender cierra lo que haya
 * quedado abierto: el indicador de pasos tiene que arrancar sin ningún
 * palomeo, aunque sea la tercera vez que el doctor entra al mismo paciente en
 * el mismo día.
 */
export function AtenderBoton({ accion }: { accion: () => Promise<void> }) {
  return (
    <form action={accion} className="w-full sm:w-auto">
      <Boton />
    </form>
  );
}

function Boton() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending} className="w-full sm:w-auto">
      {pending ? "Abriendo…" : "Atender"}
    </Button>
  );
}
