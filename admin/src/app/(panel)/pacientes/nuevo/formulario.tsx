"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import { ClaveTemporal } from "@/components/clave-temporal";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

import { darDeAlta, type EstadoAlta } from "./acciones";

const INICIAL: EstadoAlta = { error: null, creado: null };

export function FormularioAlta() {
  const [estado, enviar] = useActionState(darDeAlta, INICIAL);

  // Ya se creó: lo único que importa ahora es la contraseña, antes de que se
  // pierda. El formulario estorba.
  if (estado.creado) {
    return (
      <ClaveTemporal
        titulo="Cuenta creada"
        nombre={estado.creado.nombre}
        correo={estado.creado.correo}
        clave={estado.creado.clave}
        verFicha={`/pacientes/${estado.creado.id}`}
      />
    );
  }

  return (
    <form action={enviar} className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-2">
        <Campo id="nombre" etiqueta="Nombre" requerido autoFoco />
        <Campo id="apellidos" etiqueta="Apellidos" />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <Campo id="cedula" etiqueta="Cédula" />
        <Campo id="telefono" etiqueta="Teléfono" tipo="tel" />
      </div>

      <Campo
        id="correo"
        etiqueta="Correo"
        tipo="email"
        requerido
        ayuda="Con este entra a la app y recupera su contraseña."
      />

      {estado.error && (
        <Alert variant="destructive" className="animate-in fade-in">
          <AlertDescription>{estado.error}</AlertDescription>
        </Alert>
      )}

      <Crear />
    </form>
  );
}

function Campo({
  id,
  etiqueta,
  tipo = "text",
  ayuda,
  requerido = false,
  autoFoco = false,
}: {
  id: string;
  etiqueta: string;
  tipo?: string;
  ayuda?: string;
  requerido?: boolean;
  autoFoco?: boolean;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{etiqueta}</Label>
      <Input
        id={id}
        name={id}
        type={tipo}
        required={requerido}
        autoFocus={autoFoco}
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

function Crear() {
  const { pending } = useFormStatus();

  return (
    <Button type="submit" disabled={pending}>
      {pending ? "Creando…" : "Crear cuenta"}
    </Button>
  );
}
