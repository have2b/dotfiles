pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// Event-driven Bluetooth via Quickshell.Bluetooth — no polling, no process spawning.
// BluetoothAdapter and BluetoothDevice are reactive QML objects: their properties
// (enabled, connected, state, …) fire signals automatically when BlueZ reports changes.
QtObject {
    id: root

    // ── Panel visibility ──────────────────────────────────────────────────
    property bool panelVisible: false

    function togglePanel() { panelVisible = !panelVisible }
    function closePanel()  { panelVisible = false }

    // ── Internal: default adapter ─────────────────────────────────────────
    readonly property var _adapter: Bluetooth.defaultAdapter

    // All native BluetoothDevice objects for the default adapter.
    // Kept as a separate binding so `devices` and `connectedCount` share one
    // evaluation of .values rather than each calling it independently.
    readonly property var _nativeDevices: _adapter ? _adapter.devices.values : []

    // ── Exposed state ─────────────────────────────────────────────────────
    readonly property bool powered: _adapter ? _adapter.enabled : false

    // Paired-device list in the shape the existing UI expects:
    //   { mac: string, name: string, connected: bool }
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

    readonly property int connectedCount: {
        const list = _nativeDevices
        let n = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected) n++
        }
        return n
    }

    readonly property bool hasConnected: connectedCount > 0

    // True while any device is mid-connect or mid-disconnect — replaces the
    // old manual `refreshing` flag that was set around bluetoothctl calls.
    readonly property bool refreshing: {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            const s = list[i].state
            if (s === BluetoothDeviceState.Connecting ||
                s === BluetoothDeviceState.Disconnecting) return true
        }
        return false
    }

    // Live status message derived from device transition states — no manual
    // timers or clearStatusTimer needed.
    readonly property string statusMessage: {
        const list = _nativeDevices
        for (let i = 0; i < list.length; i++) {
            if (list[i].state === BluetoothDeviceState.Connecting)
                return "Connecting to " + (list[i].name || "device") + "\u2026"
            if (list[i].state === BluetoothDeviceState.Disconnecting)
                return "Disconnecting\u2026"
        }
        return ""
    }

    // ── Actions ───────────────────────────────────────────────────────────
    function togglePower() {
        if (_adapter) _adapter.enabled = !_adapter.enabled
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
}
