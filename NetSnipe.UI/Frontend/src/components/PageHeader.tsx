import type { ReactNode } from "react";

type Props = {
  eyebrow: string;
  title: string;
  description: string;
  action?: ReactNode;
};

export default function PageHeader({ eyebrow, title, description, action }: Props) {
  return (
    <div className="page-header">
      <div>
        <div className="eyebrow">{eyebrow}</div>
        <h1>{title}</h1>
        <p>{description}</p>
      </div>
      {action && <div className="page-header-action">{action}</div>}
    </div>
  );
}
