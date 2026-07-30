import { useState } from "react";
import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type Props = { onApply: (profile: string, channelWidth: string) => void; running: boolean };
const profiles = [
  { id: "Balanced", title: "Balanced defaults", tone: "Recommended", text: "Restores normal Wi-Fi roaming, standard TCP behavior, IPv4 LSO and Auto channel width." },
  { id: "Gaming Balanced", title: "Gaming balanced", tone: "Measured", text: "Keeps roaming enabled while applying TCP latency settings, multimedia throttling changes and disabling IPv4 Large Send Offload." },
  { id: "Lowest Ping", title: "Lowest ping", tone: "Aggressive", text: "Disables Wi-Fi background scanning and applies the latency-focused TCP and LSO changes. Roaming convenience is reduced." },
  { id: "Download / Streaming", title: "Download / streaming", tone: "Throughput", text: "Restores normal throughput-oriented behavior and Auto channel width." },
];

export default function ProfilesPage({ onApply, running }: Props) {
  const [selected, setSelected] = useState("Gaming Balanced");
  const [channelWidth, setChannelWidth] = useState("Auto");
  return (
    <>
      <PageHeader eyebrow="CHANGE / PROFILES" title="Apply a reversible profile" description="Profiles change Windows settings only after confirmation. A versioned backup is created first, and every change should be judged by before/after measurements." />
      <div className="profile-grid">{profiles.map((profile) => <button key={profile.id} className={`profile-card ${selected === profile.id ? "selected" : ""}`} onClick={() => setSelected(profile.id)}><div className="profile-topline"><span className="eyebrow">{profile.tone}</span><span className="radio-dot" /></div><h2>{profile.title}</h2><p>{profile.text}</p></button>)}</div>
      <Panel className="profile-detail" eyebrow="SELECTED PROFILE" title={selected}>
        <div className="profile-table"><div><span>Wi-Fi background scanning</span><strong>{selected === "Lowest Ping" ? "Disabled" : "Enabled"}</strong></div><div><span>TcpAckFrequency / TCPNoDelay</span><strong>{selected === "Balanced" || selected === "Download / Streaming" ? "Default" : "1 / 1"}</strong></div><div><span>IPv4 Large Send Offload</span><strong>{selected === "Balanced" || selected === "Download / Streaming" ? "Enabled" : "Disabled"}</strong></div><div><span>IPv4 meaning</span><strong>IPv4 stays enabled</strong></div><div><span>Channel width</span><strong>Auto</strong></div></div>
        <div className="callout callout-blue"><strong>About IPv4 LSO</strong><span>Disabling IPv4 Large Send Offload does not disable IPv4. It only changes one adapter offload feature.</span></div>
        <div className="profile-actions"><button className="button button-primary" disabled={running} onClick={() => onApply(selected, "Auto")}>{running ? "Applying profile..." : selected === "Gaming Balanced" ? "Review, measure and apply" : `Review and apply ${selected}`}</button><label className="inline-field">Custom channel width<select className="field-input select-input" value={channelWidth} onChange={(event) => setChannelWidth(event.target.value)}><option value="Auto">Auto</option><option value="20">20 MHz</option><option value="40">40 MHz</option><option value="80">80 MHz</option><option value="160">160 MHz</option></select></label><button className="button button-outline" disabled={running} onClick={() => onApply("Custom", channelWidth)}>Apply channel width</button></div>
      </Panel>
    </>
  );
}
