pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // ── Panel visibility ──────────────────────────────────────────────────
    property bool panelVisible: false

    function togglePanel() {
        if (!panelVisible) {
            panelVisible = true
            refreshDevices()
        } else {
            panelVisible = false
        }
    }

    function closePanel() {
        panelVisible = false
    }

    // ── Bluetooth state ───────────────────────────────────────────────────
    property bool powered: false
    property int connectedCount: 0
    property bool hasConnected: connectedCount > 0

    // ── Device list ───────────────────────────────────────────────────────
    // Each entry: { mac: string, name: string, connected: bool }
    property var devices: []
    property bool refreshing: false
    property string statusMessage: ""

    // Intermediate storage used while resolving paired + connected state
    property var _pairedDevices: []

    // ── Periodic state polling ────────────────────────────────────────────
    property var _btPoweredProc: Process {
        id: btPoweredProc
        command: ["bluetoothctl", "show"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => btPoweredProc.output += data + "\n"
        }
        onExited: {
            root.powered = btPoweredProc.output.indexOf("Powered: yes") !== -1
            btPoweredProc.output = ""
        }
    }

    property var _btConnectedCountProc: Process {
        id: btConnectedCountProc
        command: ["bluetoothctl", "devices", "Connected"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => btConnectedCountProc.output += data + "\n"
        }
        onExited: {
            const lines = btConnectedCountProc.output.trim().split("\n")
            btConnectedCountProc.output = ""
            let count = 0
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].trim() !== "") count++
            }
            root.connectedCount = count
        }
    }

    property var _pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            btPoweredProc.running = true
            btConnectedCountProc.running = true
        }
    }

    // ── Device list refresh ───────────────────────────────────────────────
    // Step 1: fetch all paired devices
    property var _pairedProc: Process {
        id: pairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        running: false
        property string output: ""
        stdout: SplitParser {
            onRead: data => pairedProc.output += data + "\n"
        }
        onExited: {
            const lines = pairedProc.output.trim().split("\n")
            pairedProc.output = ""
            let devs = []
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (!line) continue
                // Format: "Device MAC Name With Spaces"
                const spaceAfterDevice = line.indexOf(" ")
                if (spaceAfterDevice < 0) continue
                const rest = line.substring(spaceAfterDevice + 1)
                const spaceAfterMac = rest.indexOf(" ")
                if (spaceAfterMac < 0) continue
                const mac = rest.substring(0, spaceAfterMac)
                const name = rest.substring(spaceAfterMac + 1)
                devs.push({ mac: mac, name: name, connected: false })
            }
            root._pairedDevices = devs
            // Step 2: fetch connected devices to mark which are connected
            connectedListProc.running = true
        }
    }

    // Step 2: cross-reference with connected devices
    property var _connectedListProc: Process {
        id: connectedListProc
        command: ["bluetoothctl", "devices", "Connected"]
        running: false
        property string output: ""
        stdout: SplitParser {
            onRead: data => connectedListProc.output += data + "\n"
        }
        onExited: {
            const lines = connectedListProc.output.trim().split("\n")
            connectedListProc.output = ""
            // Build a set of connected MACs
            let connectedMacs = {}
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim()
                if (!line) continue
                const parts = line.split(" ")
                if (parts.length >= 2) connectedMacs[parts[1]] = true
            }
            // Merge connected state into paired list (create new objects for reactivity)
            let devs = root._pairedDevices
            let merged = []
            for (let i = 0; i < devs.length; i++) {
                merged.push({
                    mac: devs[i].mac,
                    name: devs[i].name,
                    connected: !!connectedMacs[devs[i].mac]
                })
            }
            root.devices = merged
            root.refreshing = false
        }
    }

    function refreshDevices() {
        if (root.refreshing) return
        root.refreshing = true
        pairedProc.running = true
    }

    // ── Connect / Disconnect / Power toggle ───────────────────────────────
    property var _btActionProc: Process {
        id: btActionProc
        property string output: ""
        stdout: SplitParser {
            onRead: data => btActionProc.output += data + "\n"
        }
        onExited: {
            btActionProc.output = ""
            btPoweredProc.running = true
            btConnectedCountProc.running = true
            root.refreshDevices()
            clearStatusTimer.restart()
        }
    }

    property var _clearStatusTimer: Timer {
        id: clearStatusTimer
        interval: 3000
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    function connectDevice(mac) {
        root.statusMessage = "Connecting..."
        btActionProc.command = ["bluetoothctl", "connect", mac]
        btActionProc.running = true
    }

    function disconnectDevice(mac) {
        root.statusMessage = "Disconnecting..."
        btActionProc.command = ["bluetoothctl", "disconnect", mac]
        btActionProc.running = true
    }

    function togglePower() {
        if (root.powered) {
            btActionProc.command = ["bluetoothctl", "power", "off"]
        } else {
            btActionProc.command = ["bluetoothctl", "power", "on"]
        }
        btActionProc.running = true
    }
}
