export type EstadoPaciente = "pendiente" | "activo" | "inactivo";

export type Paciente = {
  user_id: string;
  nombre: string;
  apellidos: string | null;
  nombre_completo: string;
  cedula: string | null;
  correo: string | null;
  telefono: string | null;
  fecha_nacimiento: string | null;
  estado: EstadoPaciente;
};

/** Las columnas que pide cualquier pantalla de pacientes. */
export const COLUMNAS_PACIENTE =
  "user_id, nombre, apellidos, nombre_completo, cedula, correo, telefono, " +
  "fecha_nacimiento, estado";

export const ETIQUETA_ESTADO: Record<EstadoPaciente, string> = {
  pendiente: "Pendiente",
  activo: "Activo",
  inactivo: "Inactivo",
};

/**
 * Cómo se pinta cada estado.
 *
 * "Pendiente" va en turquesa y no en rojo: no es un error ni un problema, es
 * alguien esperando a que lo atiendan.
 */
export const COLOR_ESTADO: Record<EstadoPaciente, string> = {
  pendiente: "bg-accent text-accent-foreground",
  activo: "bg-secondary text-secondary-foreground",
  inactivo: "bg-muted text-muted-foreground",
};
