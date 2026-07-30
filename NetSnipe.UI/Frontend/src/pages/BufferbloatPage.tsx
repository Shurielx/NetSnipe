import { useState } from "react";
import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type Props = { onStart: (downloadMb: number, seconds: number) => void; running: boolean };

export default function BufferbloatPage({ onStart, running }: Props) {
  const [downloadMb, setDownloadMb] = useState("10");
  const [seconds, setSeconds] = useState("90");
  return (
    <>
      <PageHeader eyebrow="MEASURE / 04" title="Bufferbloat" description="Find out whether latency increases when the connection is busy. This measures the effect; it does not change router or Windows settings." />
      <div className="workspace-grid">
        <Panel className="workspace-main" eyebrow="HOW IT WORKS" title="Idle versus loaded gateway latency">
          <div className="step-list"><div><span>01</span><strong>Idle baseline</strong><p>Ping the active gateway for 15 seconds without a download.</p></div><div><span>02</span><strong>Temporary load</strong><p>Download a temporary test file while continuing to ping the same gateway.</p></div><div><span>03</span><strong>Added latency</strong><p>Compare the loaded median with the idle median and classify the increase.</p></div></div>
          <div className="callout callout-amber"><strong>Internet required</strong><span>The default load uses Cloudflare's speed-test endpoint. The test can take up to the selected maximum duration.</span></div>
        </Panel>
        <Panel className="workspace-side" eyebrow="TEST SETTINGS" title="Temporary load">
          <label className="field-label">Download size (MB)<select className="field-input select-input" value={downloadMb} onChange={(event) => setDownloadMb(event.target.value)}><option value="10">10 MB</option><option value="25">25 MB</option><option value="50">50 MB</option></select></label>
          <label className="field-label">Maximum load duration (seconds)<input className="field-input" type="number" min="10" max="90" value={seconds} onChange={(event) => setSeconds(event.target.value)} /></label>
          <button className="button button-primary button-wide" disabled={running} onClick={() => onStart(Number(downloadMb), Math.max(10, Math.min(90, Number(seconds) || 90)))}>{running ? "Bufferbloat test running..." : "Start bufferbloat test"}</button>
          <p className="safety-copy">The download is temporary and no settings are written.</p>
        </Panel>
      </div>
    </>
  );
}
