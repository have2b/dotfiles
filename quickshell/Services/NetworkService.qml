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
            scan()
        } else {
            panelVisible = false
        }
    }

    function closePanel() {
        panelVisible = false
    }

    // ── Current connection state ──────────────────────────────────────────
    property string connectionType: "none"   // "wifi" | "ethernet" | "none"
    property string ssid: ""
    property string deviceName: ""
    property int signalStrength: 0
    property bool connected: connectionType !== "none"

    // ── Available networks ────────────────────────────────────────────────
    // Each entry: { ssid: string, signal: int, security: string, inUse: bool }
    property var networks: []
    property bool scanning: false
    property bool connecting: false
    property string statusMessage: ""

    // ── Status polling ────────────────────────────────────────────────────
    property var _nmStatusProc: Process {
        id: nmStatusProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => nmStatusProc.output += data + "\n"
        }
        onExited: {
            const lines = nmStatusProc.output.trim().split("\n")
            nmStatusProc.output = ""
            let foundWifi = false
            let foundEthernet = false
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i]
                if (!line) continue
                // Format: DEVICE:TYPE:STATE:CONNECTION (CONNECTION may contain colons)
                const parts = line.split(":")
                if (parts.length < 4) continue
                const device = parts[0]
                const type = parts[1]
                const state = parts[2]
                const conn = parts.slice(3).join(":")
                if (type === "wifi" && state === "connected" && !foundWifi) {
                    root.connectionType = "wifi"
                    root.ssid = conn
                    root.deviceName = device
                    foundWifi = true
                } else if (type === "ethernet" && state === "connected" && !foundEthernet) {
                    root.connectionType = "ethernet"
                    root.ssid = conn
                    root.deviceName = device
                    foundEthernet = true
                }
            }
            if (!foundWifi && !foundEthernet) {
                root.connectionType = "none"
                root.ssid = ""
                root.deviceName = ""
            }
        }
    }

    property var _signalProc: Process {
        id: signalProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list"]
        running: false
        property string output: ""
        stdout: SplitParser {
            onRead: data => signalProc.output += data + "\n"
        }
        onExited: {
            const lines = signalProc.output.trim().split("\n")
            signalProc.output = ""
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split(":")
                if (parts[0] === "*") {
                    root.signalStrength = parseInt(parts[1]) || 0
                    break
                }
            }
        }
    }

    property var _pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            nmStatusProc.running = true
            if (root.connectionType === "wifi")
                signalProc.running = true
        }
    }

    // ── WiFi network scanning (on demand) ────────────────────────────────
    property var _scanProc: Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"]
        running: false
        property string output: ""
        stdout: SplitParser {
            onRead: data => scanProc.output += data + "\n"
        }
        onExited: {
            const lines = scanProc.output.trim().split("\n")
            scanProc.output = ""
            let nets = []
            let seen = {}
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i]
                if (!line.trim()) continue
                // Format: (*|):SSID:SIGNAL:SECURITY — SSID may contain escaped colons (\:)
                // We parse from right: last field = SECURITY, second-last = SIGNAL, first = IN-USE
                const firstColon = line.indexOf(":")
                if (firstColon < 0) continue
                const inUse = line.substring(0, firstColon) === "*"
                const rest = line.substring(firstColon + 1)
                const lastColon = rest.lastIndexOf(":")
                if (lastColon < 0) continue
                const security = rest.substring(lastColon + 1).trim()
                const rest2 = rest.substring(0, lastColon)
                const secLastColon = rest2.lastIndexOf(":")
                if (secLastColon < 0) continue
                const signal = parseInt(rest2.substring(secLastColon + 1)) || 0
                // Unescape nmcli terse-mode colons in SSID
                const ssid = rest2.substring(0, secLastColon).replace(/\\:/g, ":")
                if (!ssid) continue
                if (seen[ssid]) {
                    for (let j = 0; j < nets.length; j++) {
                        if (nets[j].ssid === ssid) {
                            if (signal > nets[j].signal) nets[j].signal = signal
                            if (inUse) nets[j].inUse = true
                        }
                    }
                    continue
                }
                seen[ssid] = true
                nets.push({
                    ssid: ssid,
                    signal: signal,
                    security: (security === "--" || security === "") ? "" : security,
                    inUse: inUse
                })
            }
            // Sort: in-use first, then by signal strength
            nets.sort((a, b) => {
                if (a.inUse !== b.inUse) return a.inUse ? -1 : 1
                return b.signal - a.signal
            })
            root.networks = nets
            root.scanning = false
        }
    }

    function scan() {
        if (root.scanning) return
        root.scanning = true
        scanProc.running = true
    }

    // ── Connect / Disconnect ──────────────────────────────────────────────
    property var _actionProc: Process {
        id: actionProc
        property string output: ""
        stdout: SplitParser {
            onRead: data => actionProc.output += data + "\n"
        }
        onExited: {
            actionProc.output = ""
            root.connecting = false
            nmStatusProc.running = true
            if (root.connectionType === "wifi")
                signalProc.running = true
            root.scan()
            clearStatusTimer.restart()
        }
    }

    property var _clearStatusTimer: Timer {
        id: clearStatusTimer
        interval: 3000
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    function connectNetwork(ssid) {
        if (root.connecting) return
        root.connecting = true
        root.statusMessage = "Connecting to " + ssid + "..."
        actionProc.command = ["nmcli", "device", "wifi", "connect", ssid]
        actionProc.running = true
    }

    function disconnectNetwork() {
        if (root.connecting || !root.deviceName) return
        root.connecting = true
        root.statusMessage = "Disconnecting..."
        actionProc.command = ["nmcli", "device", "disconnect", root.deviceName]
        actionProc.running = true
    }
}
