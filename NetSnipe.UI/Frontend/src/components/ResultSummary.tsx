import type { BackendResult, JsonRecord, Measurement } from "../types/api";
import MeasurementCard from "./MeasurementCard";
import LatencyChart from "./LatencyChart";

const asRecord = (value: unknown): JsonRecord => value && typeof value === "object" ? value as JsonRecord : {};
const asMeasurements = (value: unknown): Measurement[] => Array.isArray(value) ? value as Measurement[] : [];

type Props = {
  result: BackendResult | null;
  action: string;
};

export default function ResultSummary({ result, action }: Props) {
  if (!result) return null;
  if (!result.success) {
    return <div className="result-error"><strong>Action failed</strong><span>{result.error ?? "Unknown backend error"}</span></div>;
  }

  const data = asRecord(result.data);
  const measurements = action === "PingTest"
    ? [asRecord(data.measurement) as Measurement]
    : asMeasurements(data.measurements);

  if (measurements.length) {
    return (
      <div className="result-stack">
        <div className="result-title-row"><div><div className="eyebrow">RESULT</div><h2>{action === "PingTest" ? "Ping result" : "Diagnostics result"}</h2></div><span className="metric-pill good">Completed</span></div>
        <LatencyChart measurements={measurements} />
        <div className="measurement-list">{measurements.map((measurement, index) => <MeasurementCard key={`${measurement.target}-${index}`} measurement={measurement} />)}</div>
        {typeof data.note === "string" && <p className="result-note">{data.note}</p>}
      </div>
    );
  }

  if (action === "DnsTest") {
    const rows = Array.isArray(data.results) ? data.results as JsonRecord[] : [];
    return <div className="result-stack"><div className="eyebrow">RESULT</div><h2>DNS resolution result</h2><div className="table-wrap"><table><thead><tr><th>Server</th><th>Name</th><th>Result</th><th>Latency</th></tr></thead><tbody>{rows.map((row, index) => <tr key={`${String(row.server)}-${String(row.name)}-${index}`}><td>{String(row.server ?? "n/a")}</td><td>{String(row.name ?? "n/a")}</td><td><span className={row.success ? "table-good" : "table-bad"}>{row.success ? "Success" : "Failed"}</span></td><td>{String(row.latency_ms ?? "n/a")} ms</td></tr>)}</tbody></table></div></div>;
  }

  if (action === "Bufferbloat") {
    const added = Number(data.added_latency_ms);
    const label = Number.isFinite(added) ? added <= 20 ? "Low added latency" : added <= 50 ? "Moderate added latency" : "High added latency" : "Not enough samples";
    return <div className="result-stack"><div className="eyebrow">RESULT</div><h2>Bufferbloat result</h2><div className="hero-metric"><strong>{Number.isFinite(added) ? `${added.toFixed(1)} ms` : "n/a"}</strong><span>{label}</span></div><div className="metric-grid"><div><span>Gateway</span><strong>{String(data.gateway ?? "n/a")}</strong></div><div><span>Idle median</span><strong>{String(asRecord(data.baseline).median_ms ?? "n/a")} ms</strong></div><div><span>Loaded median</span><strong>{String(data.loaded_ping_median_ms ?? "n/a")} ms</strong></div><div><span>Loaded samples</span><strong>{String(data.loaded_samples ?? 0)}</strong></div></div><p className="result-note">{String(data.note ?? "The test compares gateway latency before and during a temporary download.")}</p></div>;
  }

  if (action === "OptimizeProfile") {
    const comparison = asRecord(data.comparison);
    const rows = Array.isArray(comparison.rows) ? comparison.rows as JsonRecord[] : [];
    return <div className="result-stack"><div className="eyebrow">PROFILE MEASUREMENT</div><h2>{String(data.profile ?? "Profile")} before / after</h2><p className="result-note">{String(comparison.recommendation ?? "Review the deltas with the actual game and route you care about.")}</p><div className="table-wrap"><table><thead><tr><th>Target</th><th>Median delta</th><th>P95 delta</th><th>Jitter delta</th><th>Loss delta</th></tr></thead><tbody>{rows.map((row, index) => <tr key={`${String(row.target)}-${index}`}><td>{String(row.target ?? "n/a")}</td><td>{String(row.median_delta_ms ?? "n/a")} ms</td><td>{String(row.p95_delta_ms ?? "n/a")} ms</td><td>{String(row.jitter_delta_ms ?? "n/a")} ms</td><td>{String(row.loss_delta_percent ?? "n/a")}%</td></tr>)}</tbody></table></div></div>;
  }

  return <div className="result-success"><strong>Action completed</strong><span>{String(data.note ?? "The backend completed the requested action.")}</span></div>;
}

export { asRecord, asMeasurements };
