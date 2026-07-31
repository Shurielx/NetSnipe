import { useState } from "react";
import PageHeader from "../components/PageHeader";
import Panel from "../components/Panel";

type CustomSettings = { wifiScanning: boolean; tcpAckFrequency: boolean; tcpNoDelay: boolean; lsoIPv4: boolean; multimediaThrottling: boolean };
type Props = { onApply: (profile: string, channelWidth: string, customSettings?: CustomSettings) => void; onRestoreWifiScanning: () => void; running: boolean };
const profiles = [
  { id: "Balanced", title: "Balanced defaults", tone: "Recommended", text: "Restores normal Wi-Fi roaming, standard TCP behavior, IPv4 LSO and Auto channel width." },
  { id: "Gaming Balanced", title: "Gaming balanced", tone: "Measured", text: "Keeps roaming enabled while applying TCP latency settings, multimedia throttling changes and disabling IPv4 Large Send Offload." },
  { id: "Lowest Ping", title: "Lowest ping", tone: "Aggressive", text: "Disables Wi-Fi background scanning and applies the latency-focused TCP and LSO changes. Roaming convenience is reduced." },
  { id: "Download / Streaming", title: "Download / streaming", tone: "Throughput", text: "Restores normal throughput-oriented behavior and Auto channel width." },
  { id: "Custom", title: "Custom profile", tone: "Your settings", text: "Choose exactly which supported network and latency settings NetSnipe should apply." },
];

export default function ProfilesPage({ onApply, onRestoreWifiScanning, running }: Props) {
  const [selected, setSelected] = useState("Gaming Balanced");
  const [channelWidth, setChannelWidth] = useState("Auto");
  const [customSettings, setCustomSettings] = useState<CustomSettings>(() => {
    try { return JSON.parse(localStorage.getItem("netsnipe-custom-profile") ?? "null") ?? { wifiScanning: true, tcpAckFrequency: true, tcpNoDelay: true, lsoIPv4: false, multimediaThrottling: true }; } catch { return { wifiScanning: true, tcpAckFrequency: true, tcpNoDelay: true, lsoIPv4: false, multimediaThrottling: true }; }
  });
  const updateCustom = (key: keyof CustomSettings, value: boolean) => setCustomSettings((current) => ({ ...current, [key]: value }));
  const saveCustom = () => localStorage.setItem("netsnipe-custom-profile", JSON.stringify(customSettings));
  return (
    <>
      <PageHeader eyebrow="CHANGE / PROFILES" title="Apply a reversible profile" description="Profiles change Windows settings only after confirmation. A versioned backup is created first, and every change should be judged by before/after measurements." />
      <div className="profile-grid">{profiles.map((profile) => <button key={profile.id} className={`profile-card ${selected === profile.id ? "selected" : ""}`} onClick={() => setSelected(profile.id)}><div className="profile-topline"><span className="eyebrow">{profile.tone}</span><span className="radio-dot" /></div><h2>{profile.title}</h2><p>{profile.text}</p></button>)}</div>
      <Panel className="profile-detail" eyebrow="SELECTED PROFILE" title={selected}>
        {selected === "Custom" ? <div className="custom-settings"><label><input type="checkbox" checked={customSettings.wifiScanning} onChange={(event) => updateCustom("wifiScanning", event.target.checked)} /><span><strong>Wi-Fi background scanning</strong><small>Allow Windows to find nearby networks.</small></span></label><label><input type="checkbox" checked={customSettings.tcpAckFrequency} onChange={(event) => updateCustom("tcpAckFrequency", event.target.checked)} /><span><strong>TcpAckFrequency = 1</strong><small>Use the latency-focused TCP acknowledgement setting.</small></span></label><label><input type="checkbox" checked={customSettings.tcpNoDelay} onChange={(event) => updateCustom("tcpNoDelay", event.target.checked)} /><span><strong>TCPNoDelay = 1</strong><small>Reduce delayed TCP packet batching.</small></span></label><label><input type="checkbox" checked={customSettings.lsoIPv4} onChange={(event) => updateCustom("lsoIPv4", event.target.checked)} /><span><strong>IPv4 Large Send Offload</strong><small>Keep adapter offload enabled for throughput.</small></span></label><label><input type="checkbox" checked={customSettings.multimediaThrottling} onChange={(event) => updateCustom("multimediaThrottling", event.target.checked)} /><span><strong>Latency-focused multimedia throttling</strong><small>Use the latency-focused Windows multimedia value.</small></span></label></div> : <div className="profile-table"><div><span>Wi-Fi background scanning</span><strong>{selected === "Lowest Ping" ? "Disabled" : "Enabled"}</strong></div><div><span>TcpAckFrequency / TCPNoDelay</span><strong>{selected === "Balanced" || selected === "Download / Streaming" ? "Default" : "1 / 1"}</strong></div><div><span>IPv4 Large Send Offload</span><strong>{selected === "Balanced" || selected === "Download / Streaming" ? "Enabled" : "Disabled"}</strong></div><div><span>IPv4 meaning</span><strong>IPv4 stays enabled</strong></div><div><span>Channel width</span><strong>Auto</strong></div></div>}
        <div className="callout callout-blue"><strong>About IPv4 LSO</strong><span>Disabling IPv4 Large Send Offload does not disable IPv4. It only changes one adapter offload feature.</span></div>
         <div className="profile-actions"><button className="button button-primary" disabled={running} onClick={() => onApply(selected, selected === "Custom" ? channelWidth : "Auto", selected === "Custom" ? customSettings : undefined)}>{running ? "Applying profile..." : selected === "Gaming Balanced" ? "Review, measure and apply" : `Review and apply ${selected}`}</button><label className="inline-field">Custom channel width<select className="field-input select-input" value={channelWidth} onChange={(event) => setChannelWidth(event.target.value)}><option value="Auto">Auto</option><option value="20">20 MHz</option><option value="40">40 MHz</option><option value="80">80 MHz</option><option value="160">160 MHz</option></select></label>{selected === "Custom" && <button className="button button-outline" disabled={running} onClick={saveCustom}>Save custom settings</button>}<button className="button button-outline" disabled={running} onClick={() => onRestoreWifiScanning()}>Restore Wi-Fi scanning</button></div>
      </Panel>
    </>
  );
}
