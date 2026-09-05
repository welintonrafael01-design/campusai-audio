import Image from "next/image";
import Link from "next/link";

export function Brand() {
  return (
    <Link className="brand" href="/" aria-label="StudyBook AI, inicio">
      <Image
        src="/brand-mark.png"
        alt=""
        width={42}
        height={42}
        priority
      />
      <span>
        StudyBook <strong>AI</strong>
      </span>
    </Link>
  );
}
