import type { Measurement } from "../types/api";

const value = (item: number | null | undefined, suffix = "") => item === null || item === undefined ? "n/a" : `${item}${suffix}`;

type Props = {
  measurement: Measurement;
};

export default function MeasurementCard({ measurement }: Props) {
  const loss = Number(measurement.loss_percent ?? 100);
  const tone = loss === 0 ? "good" : loss <= 2 ? "warn" : "bad";
  return (
    <article className="measurement-card">
      <div className="measurement-head">
        <div>
          <div className="measurement-target">{measurement.target ?? "Unknown target"}</div>
          <div className="measurement-subtitle">{measurement.received ?? 0} received / {measurement.sent ?? 0} sent</div>
        </div>
        <span className={`metric-pill ${tone}`}>{loss.toFixed(1)}% loss</span>
      </div>
      <div className="metric-grid">
        <div><span>Minimum</span><strong>{value(measurement.min_ms, " ms")}</strong></div>
        <div><span>Average</span><strong>{value(measurement.average_ms, " ms")}</strong></div>
        <div><span>Maximum</span><strong>{value(measurement.max_ms, " ms")}</strong></div>
        <div><span>Median</span><strong>{value(measurement.median_ms, " ms")}</strong></div>
        <div><span>P95</span><strong>{value(measurement.p95_ms, " ms")}</strong></div>
        <div><span>Jitter</span><strong>{value(measurement.jitter_ms, " ms")}</strong></div>
      </div>
    </article>
  );
}
