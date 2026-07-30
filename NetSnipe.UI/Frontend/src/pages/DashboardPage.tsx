import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";
import type { StatusData, Target } from "../types/api";

type Props = {
  status: StatusData;
  targets: Target[];
  monitorRunning: boolean;
  onOpen: (page: "diagnostics" | "ping" | "dns" | "bufferbloat" | "profiles" | "monitor") => void;
  onRefresh: () => void;
};

export default function DashboardPage({ status, targets, monitorRunning, onOpen, onRefresh }: Props) {
  const gateway = String(status.gateway ?? "Not detected");
  return (
    <>
      <PageHeader eyebrow="FIELD OVERVIEW" title="Understand the connection before changing it." description="A local-first workspace for measuring Wi-Fi stability, testing specific targets and applying reversible profiles." action={<button className="button button-quiet" onClick={onRefresh}>Refresh status</button>} />
      <div className="hero-grid">
        <Panel className="hero-panel" eyebrow="CURRENT LINK" title={String(status.status ?? "Unknown")}>
          <p className="hero-copy">{String(status.description ?? "The adapter snapshot is not available yet.")}</p>
          <div className="hero-facts"><span><b>Gateway</b>{gateway}</span><span><b>Link</b>{String(status.link_speed ?? "n/a")}</span><span><b>Signal</b>{status.signal !== undefined ? `${status.signal}%` : "n/a"}</span></div>
        </Panel>
        <Panel className="accent-panel" eyebrow="SAFETY" title="Changes stay reversible.">
          <p className="hero-copy">Every profile creates a versioned backup before touching Windows settings.</p>
          <div className="safety-line"><span className="dot dot-green" /> {String(status.backup_count ?? 0)} saved backup(s)</div>
        </Panel>
      </div>
      <div className="section-heading"><div><div className="eyebrow">QUICK START</div><h2>Pick one clear next step</h2></div></div>
      <div className="quick-grid">
        <button className="quick-card" onClick={() => onOpen("diagnostics")}><span className="quick-number">01</span><strong>One-time diagnostics</strong><span>Gateway plus public references. About 60 seconds. Read-only.</span></button>
        <button className="quick-card" onClick={() => onOpen("ping")}><span className="quick-number">02</span><strong>Custom latency test</strong><span>Ping one saved, local or game-related target with your own limits.</span></button>
        <button className="quick-card" onClick={() => onOpen("bufferbloat")}><span className="quick-number">03</span><strong>Check bufferbloat</strong><span>Compare gateway latency at idle and while downloading a temporary file.</span></button>
      </div>
      <div className="two-column-grid">
        <Panel eyebrow="TARGET LIBRARY" title="Saved custom targets">
          {targets.length ? <div className="target-list">{targets.map((target) => <div className="target-row" key={target.id}><span>{target.name}</span><code>{target.address}</code></div>)}</div> : <p className="empty-copy">No custom targets yet. Add one from the Custom ping screen.</p>}
        </Panel>
        <Panel eyebrow="BACKGROUND HISTORY" title={monitorRunning ? "Monitor is running" : "Monitor is stopped"}>
          <p className="empty-copy">The monitor is a continuous worker that writes measurements to a local JSONL history file. It is separate from one-time diagnostics.</p>
          <button className="button button-outline" onClick={() => onOpen("monitor")}>{monitorRunning ? "Open monitor" : "Configure monitor"}</button>
        </Panel>
      </div>
    </>
  );
}
