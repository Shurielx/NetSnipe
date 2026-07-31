import type { ReactNode } from "react";

type Page = "dashboard" | "diagnostics" | "ping" | "dns" | "bufferbloat" | "profiles" | "monitor";

const navigation: Array<{ id: Page; label: string; eyebrow: string; group: string }> = [
  { id: "dashboard", label: "Overview", eyebrow: "Home", group: "Start here" },
  { id: "diagnostics", label: "Connection check", eyebrow: "Broad snapshot", group: "Test connection" },
  { id: "ping", label: "Target ping", eyebrow: "One destination", group: "Test connection" },
  { id: "dns", label: "DNS check", eyebrow: "Name lookup", group: "Test connection" },
  { id: "bufferbloat", label: "Bufferbloat", eyebrow: "Under load", group: "Test connection" },
  { id: "profiles", label: "Network profiles", eyebrow: "Change settings", group: "Change settings" },
  { id: "monitor", label: "Connection history", eyebrow: "Runs over time", group: "Observe" },
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
          {navigation.map((item, index) => (
            <div key={item.id}>
              {(index === 0 || navigation[index - 1].group !== item.group) && <div className="nav-group-label">{item.group}</div>}
              <button className={`nav-item ${page === item.id ? "active" : ""}`} onClick={() => onNavigate(item.id)}>
                <span className="nav-eyebrow">{item.eyebrow}</span>
                <span>{item.label}</span>
              </button>
            </div>
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
            <span className="build-version" title="Build currently running">BUILD {import.meta.env.VITE_NETSNIPE_VERSION || "DEV"}</span>
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
