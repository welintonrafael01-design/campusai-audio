"use client";

import { useId, useState } from "react";
import { ChevronDown } from "lucide-react";

type FaqItem = {
  question: string;
  answer: string;
};

export function FaqList({ items }: { items: readonly FaqItem[] }) {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const prefix = useId();

  return (
    <div className="faq-list">
      {items.map((item, index) => {
        const isOpen = openIndex === index;
        const panelId = `${prefix}-panel-${index}`;
        return (
          <section className="faq-item" key={item.question}>
            <h2>
              <button
                type="button"
                aria-expanded={isOpen}
                aria-controls={panelId}
                onClick={() => setOpenIndex(isOpen ? null : index)}
              >
                {item.question}
                <ChevronDown aria-hidden="true" size={20} />
              </button>
            </h2>
            <div id={panelId} hidden={!isOpen}>
              <p>{item.answer}</p>
            </div>
          </section>
        );
      })}
    </div>
  );
}
