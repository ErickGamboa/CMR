"use client";

import { useState, useTransition } from "react";

import { Button } from "@/components/ui/button";
import type { EstadoPaciente } from "@/lib/pacientes";

import { cambiarEstado, rechazarPaciente } from "./acciones";

/**
 * Aprobar / dar de baja / reactivar.
 *
 * Son botones y no un desplegable guardado con el resto de la ficha a
 * propósito: aprobar es la decisión que le abre a alguien su expediente, y no
 * debería poder pasar de refilón mientras se corrige un teléfono.
 */
export function BotonesEstado({
  id,
  estado,
}: {
  id: string;
  estado: EstadoPaciente;
}) {
  const [enCurso, empezar] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [confirmandoRechazo, setConfirmandoRechazo] = useState(false);

  function cambiar(nuevo: EstadoPaciente) {
    setError(null);
    empezar(async () => {
      const r = await cambiarEstado(id, nuevo);
      if (r.error) setError(r.error);
    });
  }

  function rechazar() {
    setError(null);
    empezar(async () => {
      // Si sale bien no vuelve: la accion redirige a la lista, porque esta
      // pagina es de un paciente que dejo de existir.
      const r = await rechazarPaciente(id);
      if (r?.error) {
        setError(r.error);
        setConfirmandoRechazo(false);
      }
    });
  }

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-2">
        {estado === "pendiente" && (
          <Button onClick={() => cambiar("activo")} disabled={enCurso}>
            {enCurso ? "Aprobando…" : "Aprobar paciente"}
          </Button>
        )}

        {estado === "activo" && (
          <Button
            variant="outline"
            onClick={() => cambiar("inactivo")}
            disabled={enCurso}
          >
            Dar de baja
          </Button>
        )}

        {estado === "inactivo" && (
          <Button
            variant="outline"
            onClick={() => cambiar("activo")}
            disabled={enCurso}
          >
            Reactivar
          </Button>
        )}

        {estado === "pendiente" &&
          (confirmandoRechazo ? (
            <>
              <Button
                variant="outline"
                onClick={rechazar}
                disabled={enCurso}
                className="border-destructive text-destructive"
              >
                {enCurso ? "Eliminando…" : "Sí, eliminar la cuenta"}
              </Button>
              <Button
                variant="ghost"
                onClick={() => setConfirmandoRechazo(false)}
                disabled={enCurso}
              >
                Cancelar
              </Button>
            </>
          ) : (
            <Button
              variant="outline"
              onClick={() => setConfirmandoRechazo(true)}
              disabled={enCurso}
            >
              Rechazar
            </Button>
          ))}
      </div>

      {confirmandoRechazo && (
        <p className="max-w-prose text-sm text-muted-foreground">
          Rechazar <strong>borra la cuenta</strong> y todo lo que tenga, sin
          vuelta atrás. No se guarda ni el nombre ni la cédula. Si fue un
          error, la persona se puede volver a registrar.
        </p>
      )}

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
