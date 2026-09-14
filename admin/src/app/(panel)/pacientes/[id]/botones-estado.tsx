"use client";

import { useState, useTransition } from "react";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import type { EstadoPaciente } from "@/lib/pacientes";

import { cambiarEstado, rechazarPaciente } from "./acciones";

/**
 * Aprobar / rechazar / dar de baja / reactivar.
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
      // Si sale bien no vuelve: la acción redirige a la lista, porque esta
      // página es de un paciente que dejó de existir.
      const r = await rechazarPaciente(id);
      if (r?.error) setError(r.error);
    });
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-col gap-2">
        {estado === "pendiente" && (
          <>
            <Button onClick={() => cambiar("activo")} disabled={enCurso}>
              {enCurso ? "Guardando…" : "Aprobar paciente"}
            </Button>

            {/* AlertDialog y no un diálogo cualquiera: esto borra una cuenta
                y no se puede deshacer. */}
            <AlertDialog>
              <AlertDialogTrigger
                render={<Button variant="ghost" disabled={enCurso} />}
              >
                Rechazar
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>
                    ¿Rechazar esta solicitud?
                  </AlertDialogTitle>
                  <AlertDialogDescription className="leading-relaxed">
                    Rechazar <strong>borra la cuenta</strong> y todo lo que
                    tenga, sin vuelta atrás. No se guarda ni el nombre ni la
                    cédula. Si fue un error, la persona se puede volver a
                    registrar desde la app.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancelar</AlertDialogCancel>
                  <AlertDialogAction
                    onClick={rechazar}
                    className="bg-destructive text-white hover:bg-destructive/90"
                  >
                    Eliminar la cuenta
                  </AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          </>
        )}

        {estado === "activo" && (
          <AlertDialog>
            <AlertDialogTrigger
              render={<Button variant="outline" disabled={enCurso} />}
            >
              Dar de baja
            </AlertDialogTrigger>
            <AlertDialogContent>
              <AlertDialogHeader>
                <AlertDialogTitle>¿Dar de baja al paciente?</AlertDialogTitle>
                <AlertDialogDescription className="leading-relaxed">
                  Deja de ver la app, pero{" "}
                  <strong>no se borra nada</strong>: su expediente se conserva
                  y lo podés reactivar cuando quieras.
                </AlertDialogDescription>
              </AlertDialogHeader>
              <AlertDialogFooter>
                <AlertDialogCancel>Cancelar</AlertDialogCancel>
                <AlertDialogAction onClick={() => cambiar("inactivo")}>
                  Dar de baja
                </AlertDialogAction>
              </AlertDialogFooter>
            </AlertDialogContent>
          </AlertDialog>
        )}

        {estado === "inactivo" && (
          <Button
            variant="outline"
            onClick={() => cambiar("activo")}
            disabled={enCurso}
          >
            {enCurso ? "Guardando…" : "Reactivar"}
          </Button>
        )}
      </div>

      <p className="text-xs leading-relaxed text-muted-foreground">
        {estado === "pendiente" &&
          "Hasta que lo apruebes, la app no le muestra nada."}
        {estado === "activo" && "Ve su plan, sus citas y el libro."}
        {estado === "inactivo" &&
          "No ve la app. Su expediente sigue guardado."}
      </p>

      {error && (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
