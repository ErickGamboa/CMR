"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Paciente } from "@/lib/pacientes";

import { guardarPaciente, type EstadoFicha } from "./acciones";

const inicial: EstadoFicha = { error: null, guardado: false };

export function FormularioFicha({ paciente }: { paciente: Paciente }) {
  const [estado, enviar] = useActionState(guardarPaciente, inicial);

  return (
    <form action={enviar} className="space-y-6">
      <input type="hidden" name="id" value={paciente.user_id} />

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="nombre"
          etiqueta="Nombre"
          valor={paciente.nombre}
          requerido
        />
        <Campo
          id="apellidos"
          etiqueta="Apellidos"
          valor={paciente.apellidos ?? ""}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo
          id="cedula"
          etiqueta="Cédula"
          valor={paciente.cedula ?? ""}
          ayuda="No se puede repetir entre pacientes."
        />
        <Campo
          id="telefono"
          etiqueta="Teléfono"
          valor={paciente.telefono ?? ""}
          tipo="tel"
        />
      </div>

      <Campo
        id="fecha_nacimiento"
        etiqueta="Fecha de nacimiento"
        valor={paciente.fecha_nacimiento ?? ""}
        tipo="date"
      />

      {estado.error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{estado.error}</AlertDescription>
        </Alert>
      )}
      {estado.guardado && !estado.error && (
        <p
          role="status"
          className="animate-in fade-in text-sm text-muted-foreground"
        >
          Guardado.
        </p>
      )}

      <Guardar />
    </form>
  );
}

function Campo({
  id,
  etiqueta,
  valor,
  tipo = "text",
  ayuda,
  requerido = false,
}: {
  id: string;
  etiqueta: string;
  valor: string;
  tipo?: string;
  ayuda?: string;
  requerido?: boolean;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{etiqueta}</Label>
      <Input
        id={id}
        name={id}
        type={tipo}
        defaultValue={valor}
        required={requerido}
        aria-describedby={ayuda ? `${id}-ayuda` : undefined}
      />
      {ayuda && (
        <p id={`${id}-ayuda`} className="text-xs text-muted-foreground">
          {ayuda}
        </p>
      )}
    </div>
  );
}

function Guardar() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending}>
      {pending ? "Guardando…" : "Guardar"}
    </Button>
  );
}
