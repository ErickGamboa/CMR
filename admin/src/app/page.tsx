import { redirect } from "next/navigation";

/**
 * La raíz no muestra nada propia: el middleware ya mandó al login a quien no
 * tenga sesión, así que quien llegue acá va directo a su lista de trabajo.
 */
export default function Raiz() {
  redirect("/pacientes");
}
