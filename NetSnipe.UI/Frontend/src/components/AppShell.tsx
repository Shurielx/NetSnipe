import type { ReactNode } from "react";

type Page = "dashboard" | "diagnostics" | "ping" | "dns" | "bufferbloat" | "profiles" | "monitor";

const navigation: Array<{ id: Page; label: string; eyebrow: string }> = [
  { id: "dashboard", label: "Overview", eyebrow: "Home" },
  { id: "diagnostics", label: "Diagnostics", eyebrow: "Measure" },
  { id: "ping", label: "Custom ping", eyebrow: "Measure" },
  { id: "dns", label: "DNS resolution", eyebrow: "Measure" },
  { id: "bufferbloat", label: "Bufferbloat", eyebrow: "Measure" },
  { id: "profiles", label: "Profiles", eyebrow: "Change" },
  { id: "monitor", label: "History monitor", eyebrow: "Observe" },
];

type Props = {
  page: Page;
  onNavigate: (page: Page) => void;
  adapter: string;
  status: string;
  children: ReactNode;
};

export default function AppShell({ page, onNavigate, adapter, status, children }: Props) {
  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand-lockup">
          <span className="brand-mark">N</span>
          <div>
            <div className="brand-name">NetSnipe</div>
            <div className="brand-caption">network field kit</div>
          </div>
        </div>

        <nav className="nav-list" aria-label="Main navigation">
          {navigation.map((item) => (
            <button className={`nav-item ${page === item.id ? "active" : ""}`} key={item.id} onClick={() => onNavigate(item.id)}>
              <span className="nav-eyebrow">{item.eyebrow}</span>
              <span>{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-footnote">
          <span className="dot dot-green" />
          <span>Local-first. Nothing changes silently.</span>
        </div>
      </aside>

      <main className="main-content">
        <header className="topbar">
          <div>
            <div className="topbar-kicker">ACTIVE ADAPTER</div>
            <div className="topbar-value">{adapter || "Detecting adapter..."}</div>
          </div>
          <div className="topbar-status">
            <span className={`status-pill ${status === "Attention" ? "attention" : ""}`}>
              <span className="dot dot-green" /> {status || "Ready"}
            </span>
          </div>
        </header>
        <section className="page-area">{children}</section>
      </main>
    </div>
  );
}

export type { Page };
