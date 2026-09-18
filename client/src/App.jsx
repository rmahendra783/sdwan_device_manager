import React, { useEffect, useState, useCallback } from "react";
import { 
  getDevices, 
  getDevice, 
  triggerSync 
} from "./services/api";
import { 
  Server, 
  RefreshCw, 
  AlertTriangle, 
  CheckCircle2, 
  Clock, 
  XCircle, 
  Cpu, 
  Activity, 
  Layers, 
  X,
  ArrowRight,
  ShieldCheck
} from "lucide-react";

export default function App() {
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [syncingMap, setSyncingMap] = useState({});
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [toast, setToast] = useState(null);

  const showToast = (message, type = "info") => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchDevicesList = useCallback(async (isBackground = false) => {
    if (!isBackground) setLoading(true);
    try {
      const response = await getDevices();
      setDevices(response.data);
    } catch (err) {
      console.error("Failed to fetch devices:", err);
      showToast("Unable to reach Rails API at :3000", "error");
    } finally {
      if (!isBackground) setLoading(false);
    }
  }, []);

  // Initial load
  useEffect(() => {
    fetchDevicesList();
  }, [fetchDevicesList]);

  // Polling interval whenever any device is sync_pending
  useEffect(() => {
    const hasPendingSync = devices.some((d) => d.sync_status === "sync_pending");
    if (!hasPendingSync) return;

    const intervalId = setInterval(() => {
      fetchDevicesList(true);
    }, 2500);

    return () => clearInterval(intervalId);
  }, [devices, fetchDevicesList]);

  const handleTriggerSync = async (deviceId) => {
    setSyncingMap((prev) => ({ ...prev, [deviceId]: true }));
    try {
      const res = await triggerSync(deviceId);
      showToast(res.data.message || "Reconciliation job enqueued", "success");
      
      // Optimistic update
      setDevices((prev) =>
        prev.map((d) => (d.id === deviceId ? { ...d, sync_status: "sync_pending" } : d))
      );
    } catch (err) {
      if (err.response?.status === 409) {
        showToast("Conflict: A sync job is already pending for this router.", "warning");
      } else {
        showToast("Sync trigger failed: Check network/API service.", "error");
      }
    } finally {
      setSyncingMap((prev) => ({ ...prev, [deviceId]: false }));
    }
  };

  const openInspector = async (deviceId) => {
    setDetailLoading(true);
    try {
      const res = await getDevice(deviceId);
      setSelectedDevice(res.data);
    } catch (err) {
      showToast("Failed to fetch device details and configuration.", "error");
    } finally {
      setDetailLoading(false);
    }
  };

  const renderStatusBadge = (status) => {
    switch (status) {
      case "in_sync":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <CheckCircle2 size={13} /> In Sync
          </span>
        );
      case "sync_pending":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            <Clock size={13} className="animate-spin" /> Sync Pending
          </span>
        );
      case "out_of_sync":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/20">
            <AlertTriangle size={13} /> Out of Sync
          </span>
        );
      case "sync_failed":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-600/20 text-red-400 border border-red-500/30">
            <XCircle size={13} /> Sync Failed
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-800 text-slate-400 border border-slate-700">
            {status}
          </span>
        );
    }
  };

  const totalDevices = devices.length;
  const inSyncCount = devices.filter((d) => d.sync_status === "in_sync").length;
  const outOfSyncCount = devices.filter((d) => d.sync_status === "out_of_sync").length;
  const pendingCount = devices.filter((d) => d.sync_status === "sync_pending").length;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 antialiased p-6 md:p-10">
      {/* Toast Alert */}
      {toast && (
        <div className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-lg shadow-xl text-sm font-medium border transition-all ${
          toast.type === "error" ? "bg-rose-950/90 border-rose-700 text-rose-200" :
          toast.type === "warning" ? "bg-amber-950/90 border-amber-700 text-amber-200" :
          "bg-emerald-950/90 border-emerald-700 text-emerald-200"
        }`}>
          {toast.message}
        </div>
      )}

      {/* Header */}
      <div className="max-w-7xl mx-auto space-y-8">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 pb-6 border-b border-slate-800">
          <div>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-600/20 border border-blue-500/30 rounded-lg text-blue-400">
                <Server size={24} />
              </div>
              <div>
                <h1 className="text-xl md:text-2xl font-bold tracking-tight text-white">
                  SD-WAN Orchestration Engine
                </h1>
                <p className="text-xs md:text-sm text-slate-400">
                  Zero-Touch Configuration Drift Detection & Edge Reconciliation
                </p>
              </div>
            </div>
          </div>
          <button
            onClick={() => fetchDevicesList(false)}
            disabled={loading}
            className="flex items-center gap-2 px-3.5 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-200 rounded-lg text-xs font-medium transition disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? "animate-spin" : ""} />
            Refresh Inventory
          </button>
        </div>

        {/* Telemetry KPI Metrics */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-slate-900/70 border border-slate-800 p-4 rounded-xl">
            <p className="text-xs uppercase tracking-wider text-slate-400 font-semibold">Total Gateways</p>
            <p className="text-2xl font-bold mt-2 text-white">{totalDevices}</p>
          </div>
          <div className="bg-slate-900/70 border border-slate-800 p-4 rounded-xl">
            <p className="text-xs uppercase tracking-wider text-emerald-400 font-semibold">In Sync</p>
            <p className="text-2xl font-bold mt-2 text-emerald-400">{inSyncCount}</p>
          </div>
          <div className="bg-slate-900/70 border border-slate-800 p-4 rounded-xl">
            <p className="text-xs uppercase tracking-wider text-rose-400 font-semibold">Drift Detected</p>
            <p className="text-2xl font-bold mt-2 text-rose-400">{outOfSyncCount}</p>
          </div>
          <div className="bg-slate-900/70 border border-slate-800 p-4 rounded-xl">
            <p className="text-xs uppercase tracking-wider text-amber-400 font-semibold">Reconciling</p>
            <p className="text-2xl font-bold mt-2 text-amber-400">{pendingCount}</p>
          </div>
        </div>

        {/* Device Grid */}
        {loading ? (
          <div className="py-20 text-center text-slate-500 font-medium">
            <RefreshCw size={24} className="animate-spin mx-auto mb-2 text-slate-600" />
            Loading edge device inventory from Rails API...
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {devices.map((device) => {
              const isSyncing = syncingMap[device.id] || device.sync_status === "sync_pending";

              return (
                <div
                  key={device.id}
                  className="bg-slate-900/80 border border-slate-800/80 hover:border-slate-700/80 rounded-xl p-5 flex flex-col justify-between transition group shadow-sm hover:shadow-md"
                >
                  <div>
                    <div className="flex justify-between items-start gap-2 mb-4">
                      <div>
                        <h2 className="text-base font-semibold text-white group-hover:text-blue-400 transition">
                          {device.hostname}
                        </h2>
                        <span className="text-xs font-mono text-slate-500">
                          {device.serial_number}
                        </span>
                      </div>
                      {renderStatusBadge(device.sync_status)}
                    </div>

                    <div className="space-y-2 py-3 border-y border-slate-800/60 text-xs">
                      <div className="flex justify-between">
                        <span className="text-slate-400 flex items-center gap-1.5">
                          <Cpu size={13} className="text-slate-500" /> Model
                        </span>
                        <span className="text-slate-200 font-mono">{device.device_model || "Edge-Router-v1"}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-400 flex items-center gap-1.5">
                          <Activity size={13} className="text-slate-500" /> Management IP
                        </span>
                        <span className="text-slate-200 font-mono">{device.management_ip || "172.16.255.1"}</span>
                      </div>
                    </div>
                  </div>

                  <div className="mt-5 pt-2 flex items-center gap-2">
                    <button
                      onClick={() => openInspector(device.id)}
                      className="flex-1 py-2 px-3 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-medium transition border border-slate-700/60"
                    >
                      View Drift & Diff
                    </button>
                    <button
                      onClick={() => handleTriggerSync(device.id)}
                      disabled={isSyncing}
                      className="py-2 px-3 bg-blue-600 hover:bg-blue-500 disabled:bg-slate-800/80 disabled:text-slate-500 text-white rounded-lg text-xs font-semibold transition flex items-center justify-center gap-1.5"
                    >
                      <RefreshCw size={13} className={isSyncing ? "animate-spin" : ""} />
                      {isSyncing ? "Pending" : "Sync"}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Detail & Drift Inspector Modal */}
      {selectedDevice && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-xl w-full max-w-3xl overflow-hidden shadow-2xl my-8">
            <div className="flex justify-between items-center p-5 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <Layers size={18} className="text-blue-400" />
                <h3 className="font-bold text-white text-base">
                  Drift Inspector: {selectedDevice.hostname}
                </h3>
              </div>
              <button
                onClick={() => setSelectedDevice(null)}
                className="p-1 rounded text-slate-400 hover:text-white hover:bg-slate-800 transition"
              >
                <X size={18} />
              </button>
            </div>

            <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
              <div className="flex items-center justify-between bg-slate-950 p-4 rounded-lg border border-slate-800">
                <div>
                  <p className="text-xs text-slate-500 font-mono uppercase">Device Sync Status</p>
                  <div className="mt-1">{renderStatusBadge(selectedDevice.sync_status)}</div>
                </div>
                <div>
                  <p className="text-xs text-slate-500 font-mono uppercase">Latest Applied Run</p>
                  <p className="text-xs font-mono text-slate-300 mt-1">
                    {selectedDevice.latest_configuration?.applied_at || "Not yet reconciled"}
                  </p>
                </div>
              </div>

              {/* Diff Engine Breakdown */}
              <div>
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                  Config Diff Payload (JSONB Output)
                </h4>
                <div className="bg-slate-950 border border-slate-800 rounded-lg p-4 font-mono text-xs overflow-x-auto text-emerald-400">
                  <pre>
                    {JSON.stringify(
                      selectedDevice.latest_configuration?.diff_payload || {},
                      null,
                      2
                    )}
                  </pre>
                </div>
              </div>

              {/* Desired Configuration Template */}
              <div>
                <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
                  Desired Template Blueprint
                </h4>
                <div className="bg-slate-950 border border-slate-800 rounded-lg p-4 font-mono text-xs overflow-x-auto text-slate-300">
                  <pre>
                    {JSON.stringify(
                      selectedDevice.latest_configuration?.desired_config || {},
                      null,
                      2
                    )}
                  </pre>
                </div>
              </div>
            </div>

            <div className="p-4 border-t border-slate-800 bg-slate-950/60 flex justify-end gap-2">
              <button
                onClick={() => setSelectedDevice(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-xs font-medium transition"
              >
                Close
              </button>
              <button
                onClick={() => {
                  handleTriggerSync(selectedDevice.id);
                  setSelectedDevice(null);
                }}
                disabled={selectedDevice.sync_status === "sync_pending"}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-lg text-xs font-semibold transition flex items-center gap-1.5"
              >
                <RefreshCw size={13} /> Reconcile Drift Now
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}