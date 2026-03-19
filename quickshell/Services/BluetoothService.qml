pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// Item is used instead of QtObject so that child objects (e.g. Timer)
// can be placed directly using the data default property.
Item {
    id: root

    // ── Panel visibility ──────────────────────────────────────────────────
    property bool panelVisible: false

    function togglePanel() { panelVisible = !panelVisible }
    function closePanel()  { panelVisible = false; stopScan() }

    // ── Internal: default adapter ─────────────────────────────────────────
    readonly property var _adapter: Bluetooth.defaultAdapter

    // All native BluetoothDevice objects for the default adapter.
    // Kept as a separate binding so computed properties share one evaluation.
    readonly property var _nativeDevices: _adapter ? _adapter.devices.values : []

    // ── Exposed state ─────────────────────────────────────────────────────
    readonly property bool powered: _adapter ? _adapter.enabled : false

    // Paired-device list: { mac, name, connected }
    readonly property var devices: {
        const list = _nativeDevices
        const result = []
        for (let i = 0; i < list.length; i++) {
            const d = list[i]
            if (d.paired || d.connected) {
                result.push({
                    mac:       d.address,
                    name:      d.name || d.deviceName || "Unknown Device",
                    connected: d.connected
                })
            }
        }
        return result
    }

    readonly property var availableDevices: {
        // Matches MAC addresses written with : or - separators, e.g. AA:BB:CC:DD:EE:FF
        const macSepPattern = /([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}/

        const list = _nativeDevices
        const seen  = {}   // deduplicate — same device can appear via LE + classic
        const result = []

        for (let i = 0; i < list.length; i++) {
            const d = list[i]
            if (d.paired || d.connected) continue

            // Deduplicate by hardware address
            const mac = d.address
            if (seen[mac]) continue
            seen[mac] = true

            // Use the BlueZ alias (d.name). Skip if empty.
            const rawName = d.name || ""
            if (!rawName) continue

            // Skip names that contain a MAC-style pattern with separators.
            if (macSepPattern.test(rawName)) continue

            // Skip names that equal the device's own MAC when both are
            // normalized to lower-case hex with no separators. This catches
            // unseparated formats like "AABBCCDDEEFF" or "aabbccddeeff".
            const normName = rawName.toLowerCase().replace(/[:-\s]/g, "")
            const normMac  = mac.toLowerCase().replace(/[:-\s]/g, "")
            if (normName === normMac) continue

            result.push({
                mac:     mac,
                name:    rawName,
                icon:    d.icon || "",
                pairing: d.pairing || false
            })
        }
        return result
    }

    readonly property int connectedCount: {
        const list = _nativeDevices
        let n = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected) n++
        }
        return n
    }

    readonly property bool hasConnected: connectedCount > 0

    // Whether the adapter is actively scanning for nearby devices.
    readonly property bool scanning: _adapter ? _adapter.discovering : false

    // True while any device is mid-connect, mid-disconnect, or mid-pair.
    readonly property bool refreshing: {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            const s = list[i].state
            if (s === BluetoothDeviceState.Connecting ||
                s === BluetoothDeviceState.Disconnecting) return true
            if (list[i].pairing) return true
        }
        return false
    }

    // Live status message from device transition states.
    readonly property string statusMessage: {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            if (list[i].pairing)
                return "Pairing with " + (list[i].name || "device") + "\u2026"
            if (list[i].state === BluetoothDeviceState.Connecting)
                return "Connecting to " + (list[i].name || "device") + "\u2026"
            if (list[i].state === BluetoothDeviceState.Disconnecting)
                return "Disconnecting\u2026"
        }
        return ""
    }

    // ── Scan auto-stop (30 s) ─────────────────────────────────────────────
    Timer {
        id: _scanTimer
        interval: 30000
        onTriggered: if (root._adapter) root._adapter.discovering = false
    }

    // ── Actions ───────────────────────────────────────────────────────────
    function togglePower() {
        if (_adapter) _adapter.enabled = !_adapter.enabled
    }

    // Start a BT discovery scan; auto-stops after 30 s.
    function startScan() {
        if (!_adapter) return
        _adapter.discovering = true
        _scanTimer.restart()
    }

    // Stop a running scan immediately.
    function stopScan() {
        if (!_adapter) return
        _adapter.discovering = false
        _scanTimer.stop()
    }

    function connectDevice(mac) {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            if (list[i].address === mac) { list[i].connect(); return }
        }
    }

    function disconnectDevice(mac) {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            if (list[i].address === mac) { list[i].disconnect(); return }
        }
    }

    // Initiate pairing with a discovered (unpaired) device.
    function pairDevice(mac) {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            if (list[i].address === mac) { list[i].pair(); return }
        }
    }
}
