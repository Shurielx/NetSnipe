import { useState } from "react";
import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type Props = { onStart: (seconds: number) => void; running: boolean };

export default function DiagnosticsPage({ onStart, running }: Props) {
  const [seconds, setSeconds] = useState("60");
  return (
    <>
      <PageHeader eyebrow="MEASURE / 01" title="One-time diagnostics" description="A fixed health check for the current connection. It does not use the Custom ping settings on the next page." />
      <div className="workspace-grid">
        <Panel className="workspace-main" eyebrow="WHAT WILL HAPPEN" title="One test, three reference points">
          <p className="lead-copy">NetSnipe resolves the active gateway at runtime, then measures it together with two public Internet reference addresses.</p>
          <div className="step-list"><div><span>01</span><strong>Local path</strong><p>Your actual gateway, such as 192.168.1.1.</p></div><div><span>02</span><strong>External reference</strong><p>1.1.1.1 as a stable Internet comparison.</p></div><div><span>03</span><strong>External reference</strong><p>8.8.8.8 as a second route comparison.</p></div></div>
          <div className="callout callout-blue"><strong>Important</strong><span>Changing the target, rate or duration on Custom ping will not change this test.</span></div>
        </Panel>
        <Panel className="workspace-side" eyebrow="SETTINGS" title="Diagnostic budget">
          <label className="field-label">Total test budget (seconds)<input className="field-input" type="number" min="15" max="900" value={seconds} onChange={(event) => setSeconds(event.target.value)} /></label>
          <p className="field-help">The budget is shared between the unique targets. With 60 seconds this is usually about 20 seconds per target.</p>
          <button className="button button-primary button-wide" disabled={running} onClick={() => onStart(Math.max(15, Math.min(900, Number(seconds) || 60)))}>{running ? "Diagnostics running..." : "Start diagnostics"}</button>
          <p className="safety-copy">Read-only. No Windows network settings are changed.</p>
        </Panel>
      </div>
    </>
  );
}
