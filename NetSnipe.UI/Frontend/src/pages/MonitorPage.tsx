import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type Props = { running: boolean; onStart: () => void; onStop: () => void; onRefresh: () => void; latest: string };

export default function MonitorPage({ running, onStart, onStop, onRefresh, latest }: Props) {
  return (
    <>
      <PageHeader eyebrow="OBSERVE / HISTORY" title="Connection history" description="Unlike a one-time test, this keeps measuring in the background and records how the connection behaves while you use the computer." action={<button className="button button-quiet" onClick={onRefresh}>Refresh status</button>} />
      <div className="workspace-grid">
        <Panel className="workspace-main" eyebrow="WHAT IS DIFFERENT" title="One-time test versus background worker">
          <div className="comparison-grid"><div><span className="comparison-label">Diagnostics</span><strong>Runs once</strong><p>Shows a result in the GUI and exits automatically.</p></div><div><span className="comparison-label">Monitor</span><strong>Runs continuously</strong><p>Measures repeatedly in another process and keeps a local history.</p></div></div>
          <div className="callout callout-blue"><strong>When to use it</strong><span>Start this before reproducing an intermittent problem. It is not a faster diagnostics test: it is a background recorder for problems that appear later.</span></div>
        </Panel>
        <Panel className="workspace-side" eyebrow="WORKER STATUS" title={running ? "Monitor is running" : "Monitor is stopped"}>
          <div className={`status-large ${running ? "online" : "offline"}`}><span className="dot" />{running ? "Collecting measurements" : "No background worker"}</div>
          <p className="field-help">The worker uses the gateway plus saved targets and writes to the local NetSnipe data folder.</p>
          {running ? <button className="button button-danger button-wide" onClick={onStop}>Stop background monitor</button> : <button className="button button-primary button-wide" onClick={onStart}>Start background monitor</button>}
          <button className="button button-outline button-wide" onClick={onRefresh}>Refresh monitor status</button>
        </Panel>
      </div>
      {latest && <Panel className="monitor-latest" eyebrow="LATEST LOG SAMPLE" title="Raw latest record"><pre className="raw-block">{latest}</pre></Panel>}
    </>
  );
}
