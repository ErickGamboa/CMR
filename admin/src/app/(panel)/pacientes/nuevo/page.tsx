import type { Metadata } from "next";
import Link from "next/link";

import { FormularioAlta } from "./formulario";

export const metadata: Metadata = { title: "Nuevo paciente · CMR" };

export default function PaginaNuevoPaciente() {
  return (
    <div className="space-y-6">
      <div className="space-y-3">
        <Link
          href="/pacientes"
          className="text-sm text-muted-foreground hover:text-foreground"
        >
          ← Pacientes
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight">
          Nuevo paciente
        </h1>
        <p className="max-w-prose text-sm text-muted-foreground">
          Para pacientes que no van a crear la cuenta ellos mismos. Queda
          aprobada de una y con una contraseña temporal que le vas a poder
          dictar. El correo importa: es por donde el paciente recupera su
          contraseña si se le olvida.
        </p>
      </div>

      <FormularioAlta />
    </div>
  );
}
