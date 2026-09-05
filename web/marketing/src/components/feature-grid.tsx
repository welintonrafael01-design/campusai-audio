import {
  BookOpenCheck,
  BrainCircuit,
  ClipboardCheck,
  FileQuestion,
  Headphones,
  Layers3,
  MessageCircleMore,
  Mic2,
} from "lucide-react";

type Feature = {
  icon: string;
  title: string;
  description: string;
};

const icons = {
  message: MessageCircleMore,
  summary: BookOpenCheck,
  audio: Headphones,
  voice: Mic2,
  cards: Layers3,
  quiz: BrainCircuit,
  bank: FileQuestion,
  exam: ClipboardCheck,
} as const;

export function FeatureGrid({ features }: { features: readonly Feature[] }) {
  return (
    <div className="feature-grid">
      {features.map((feature) => {
        const Icon = icons[feature.icon as keyof typeof icons] ?? BrainCircuit;
        return (
          <article className="feature-item" key={feature.title}>
            <span className="icon-box" aria-hidden="true">
              <Icon size={23} strokeWidth={1.8} />
            </span>
            <h3>{feature.title}</h3>
            <p>{feature.description}</p>
          </article>
        );
      })}
    </div>
  );
}
