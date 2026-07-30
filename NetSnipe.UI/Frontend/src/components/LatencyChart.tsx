import type { Measurement } from "../types/api";

type Props = {
  measurements: Measurement[];
};

export default function LatencyChart({ measurements }: Props) {
  if (!measurements.length) return null;
  const max = Math.max(...measurements.map((item) => Number(item.max_ms ?? item.average_ms ?? 0)), 1);
  const points = measurements.map((item, index) => {
    const x = measurements.length === 1 ? 50 : (index / (measurements.length - 1)) * 100;
    const y = 100 - (Number(item.average_ms ?? 0) / max) * 82 - 8;
    return `${x},${Math.max(8, y)}`;
  }).join(" ");

  return (
    <div className="chart-card">
      <div className="chart-heading"><span>Average latency by target</span><span className="chart-unit">milliseconds</span></div>
      <svg className="latency-chart" viewBox="0 0 100 100" preserveAspectRatio="none" role="img" aria-label="Average latency chart">
        <line x1="0" y1="92" x2="100" y2="92" className="chart-axis" />
        <line x1="0" y1="50" x2="100" y2="50" className="chart-gridline" />
        <polyline points={points} className="chart-line" />
        {measurements.map((item, index) => {
          const x = measurements.length === 1 ? 50 : (index / (measurements.length - 1)) * 100;
          const y = 100 - (Number(item.average_ms ?? 0) / max) * 82 - 8;
          return <circle key={`${item.target}-${index}`} cx={x} cy={Math.max(8, y)} r="1.4" className="chart-dot" />;
        })}
      </svg>
      <div className="chart-labels">{measurements.map((item) => <span key={item.target}>{item.target}</span>)}</div>
    </div>
  );
}
