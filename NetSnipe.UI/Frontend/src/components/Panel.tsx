import type { ReactNode } from "react";

type Props = {
  title?: string;
  eyebrow?: string;
  children: ReactNode;
  className?: string;
};

export default function Panel({ title, eyebrow, children, className = "" }: Props) {
  return (
    <section className={`panel ${className}`}>
      {eyebrow && <div className="eyebrow">{eyebrow}</div>}
      {title && <h2>{title}</h2>}
      {children}
    </section>
  );
}
