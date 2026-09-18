import type { FaqItem } from '@/lib/faq';

export function FaqList({ items }: { items: FaqItem[] }) {
  return (
    <div className="faq-list" data-reveal>
      {items.map((item) => (
        <details className="faq" key={item.q}>
          <summary dangerouslySetInnerHTML={{ __html: item.q }} />
          <div className="faq__answer">
            <p dangerouslySetInnerHTML={{ __html: item.a }} />
          </div>
        </details>
      ))}
    </div>
  );
}
