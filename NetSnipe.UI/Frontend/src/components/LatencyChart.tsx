import { useState } from "react";
import type { LatencySample, Measurement } from "../types/api";

type Props = {
  measurements: Measurement[];
};

export default function LatencyChart({ measurements }: Props) {
  const [hoveredSample, setHoveredSample] = useState<number | null>(null);
  if (!measurements.length) return null;
  const samples: LatencySample[] = measurements.length === 1 && measurements[0].samples?.length
    ? measurements[0].samples
    : [];
  const max = samples.length
    ? Math.max(...samples.map((item) => Number(item.latency_ms ?? 0)), 1)
    : Math.max(...measurements.map((item) => Number(item.max_ms ?? item.average_ms ?? 0)), 1);
  const samplePoints = samples.map((item, index) => {
    const x = samples.length === 1 ? 50 : (index / (samples.length - 1)) * 100;
    const y = 100 - (Number(item.latency_ms ?? 0) / max) * 82 - 8;
    return `${x},${Math.max(8, y)}`;
  }).join(" ");
  const points = measurements.map((item, index) => {
    const x = measurements.length === 1 ? 50 : (index / (measurements.length - 1)) * 100;
    const y = 100 - (Number(item.average_ms ?? 0) / max) * 82 - 8;
    return `${x},${Math.max(8, y)}`;
  }).join(" ");
  const singleValue = Number(measurements[0]?.average_ms ?? 0);
  const singleY = 100 - (singleValue / max) * 82 - 8;

  return (
    <div className="chart-card">
       <div className="chart-heading"><span>{samples.length > 1 ? "Latency over time" : measurements.length === 1 ? "Average latency" : "Average latency by target"}</span><span className="chart-unit">milliseconds</span></div>
       <div className="chart-plot">
         <svg className="latency-chart" viewBox="0 0 100 100" preserveAspectRatio="none" role="img" aria-label={samples.length > 1 ? "Latency over time chart" : "Average latency chart"}>
           <line x1="0" y1="92" x2="100" y2="92" className="chart-axis" />
           <line x1="0" y1="50" x2="100" y2="50" className="chart-gridline" />
           {samples.length > 1
             ? <polyline points={samplePoints} className="chart-line" />
             : measurements.length === 1
             ? <line x1="12" y1={Math.max(8, singleY)} x2="88" y2={Math.max(8, singleY)} className="chart-line chart-single-line" />
             : <polyline points={points} className="chart-line" />}
         </svg>
         {samples.length > 1 && samples.map((item, index) => {
           const x = (index / (samples.length - 1)) * 100;
           const y = Math.max(8, 100 - (Number(item.latency_ms ?? 0) / max) * 82 - 8);
           return <button
             key={`sample-${index}`}
             className={`chart-marker ${hoveredSample === index ? "active" : ""}`}
             style={{ left: `${x}%`, top: `${y}%` }}
             aria-label={`Sample ${index + 1}: ${Number(item.latency_ms ?? 0)} milliseconds`}
             onMouseEnter={() => setHoveredSample(index)}
             onMouseLeave={() => setHoveredSample(null)}
             onFocus={() => setHoveredSample(index)}
             onBlur={() => setHoveredSample(null)}
           />;
         })}
         {hoveredSample !== null && samples[hoveredSample] && (
           <div className="chart-tooltip" style={{ left: `${(hoveredSample / (samples.length - 1)) * 100}%` }}>
             <strong>{Number(samples[hoveredSample].latency_ms ?? 0)} ms</strong>
             <span>Sample {hoveredSample + 1} · {Number(samples[hoveredSample].elapsed_seconds ?? 0).toFixed(1)} s</span>
           </div>
         )}
       </div>
      <div className="chart-labels">{measurements.map((item) => <span key={item.target}>{item.target}</span>)}</div>
    </div>
  );
}
