import type { ProgressEvent } from "../types/api";

type Props = {
  progress: ProgressEvent | null;
  running: boolean;
  onCancel: () => void;
};

export default function ProgressPanel({ progress, running, onCancel }: Props) {
  if (!running && !progress) return null;
  const total = Number(progress?.total_seconds ?? 0);
  const elapsed = Number(progress?.elapsed_seconds ?? 0);
  const percent = total > 0 ? Math.min(100, Math.max(0, (elapsed / total) * 100)) : 0;

  return (
    <div className="progress-panel">
      <div className="progress-topline">
        <strong>{running ? "Test in progress" : "Last progress sample"}</strong>
        {running && <button className="button button-danger button-small" onClick={onCancel}>Cancel</button>}
      </div>
      <div className="progress-label">
        <span>{progress?.target ?? "Preparing target..."}</span>
        <span>{Math.round(percent)}%</span>
      </div>
      <div className="progress-track"><div className="progress-value" style={{ width: `${percent}%` }} /></div>
      <div className="progress-stats">
        <span>Sent <b>{progress?.sent ?? 0}</b></span>
        <span>Received <b>{progress?.received ?? 0}</b></span>
        <span>Loss <b>{Number(progress?.loss_percent ?? 0).toFixed(1)}%</b></span>
        <span>Last reply <b>{progress?.last_latency_ms ?? "waiting"} ms</b></span>
      </div>
    </div>
  );
}
