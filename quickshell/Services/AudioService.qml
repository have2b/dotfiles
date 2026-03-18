pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // ── Exposed state ─────────────────────────────────────────────────────
    property real volume: 50    // 0–100 (integer percentage)
    property bool muted: false

    // ── Volume polling ────────────────────────────────────────────────────
    property var _volProc: Process {
        id: volProc
        // wpctl output: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        property string output: ""
        stdout: SplitParser {
            onRead: data => volProc.output += data + "\n"
        }
        onExited: {
            const out = volProc.output.trim()
            volProc.output = ""
            const match = out.match(/Volume:\s*([\d.]+)/)
            if (match) {
                root.volume = Math.round(parseFloat(match[1]) * 100)
            }
            root.muted = out.indexOf("[MUTED]") >= 0
        }
    }

    property var _pollTimer: Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: volProc.running = true
    }

    // ── Control commands ──────────────────────────────────────────────────
    property var _cmdProc: Process {
        id: cmdProc
        onExited: volProc.running = true     // refresh immediately after any command
    }

    function increaseVolume() {
        cmdProc.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"]
        cmdProc.running = true
    }

    function decreaseVolume() {
        cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]
        cmdProc.running = true
    }

    function setVolume(vol) {
        cmdProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(vol) + "%"]
        cmdProc.running = true
    }

    function toggleMute() {
        cmdProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        cmdProc.running = true
    }
}
