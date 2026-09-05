import Image from "next/image";

export function BookyPlaceholder() {
  return (
    <figure className="booky-placeholder">
      <Image src="/brand-mark.png" alt="" width={96} height={96} />
      <figcaption>
        <strong>Asset oficial de Booky pendiente de integración</strong>
        <span>
          Este espacio está reservado para el personaje aprobado. No se ha
          redibujado ni reinterpretado su diseño.
        </span>
      </figcaption>
    </figure>
  );
}
