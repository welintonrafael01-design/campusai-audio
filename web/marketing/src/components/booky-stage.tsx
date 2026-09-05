import Image from "next/image";

type BookyStageProps = {
  compact?: boolean;
  message?: string;
};

export function BookyStage({
  compact = false,
  message = "Hola, soy Booky. Tu compañero inteligente de aprendizaje.",
}: BookyStageProps) {
  return (
    <figure
      className={compact ? "booky-stage booky-stage-compact" : "booky-stage"}
      aria-label="Presentación de Booky, compañero inteligente de aprendizaje"
    >
      <div className="booky-atmosphere" aria-hidden="true">
        <span className="booky-orbit" />
        <span className="booky-star booky-star-one" />
        <span className="booky-star booky-star-two" />
        <span className="booky-star booky-star-three" />
      </div>
      <div className="booky-mark" aria-hidden="true">
        <span className="booky-mark-ring" />
        <Image src="/brand-mark.png" alt="" width={116} height={116} priority />
        <strong>BOOKY</strong>
      </div>
      <figcaption className="booky-bubble">{message}</figcaption>
    </figure>
  );
}
