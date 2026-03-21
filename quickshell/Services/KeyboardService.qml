pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // Current input method label, e.g. "US", "FR", "PINY"
    // Empty string when fcitx5 is not running.
    property string currentLayout:  ""
    property bool   fcitxAvailable: false

    // ── Format raw fcitx5 IM name → short display label ──────────────────────
    // Examples:
    //   "keyboard-us"        → "US"
    //   "keyboard-fr-oss"    → "FR"
    //   "keyboard-de-neo"    → "DE"
    //   "pinyin"             → "PINY"
    //   "mozc"               → "MOZC"
    //   "hangul"             → "HANG"
    function _formatIM(raw) {
        if (!raw) return ""
        // Strip the "keyboard-" prefix; keep only the first dash-segment
        const base = raw.replace(/^keyboard-/, "").split("-")[0].toUpperCase()
        // Cap at 4 characters so it never overflows the pill
        return base.length > 4 ? base.slice(0, 4) : base
    }

    // ── Process: run fcitx5-remote -n ────────────────────────────────────────
    property var _imProc: Process {
        id: imProc
        command: ["fcitx5-remote", "-n"]
        running: true

        property string _buf: ""

        stdout: SplitParser {
            onRead: data => imProc._buf += data
        }

        onExited: (code) => {
            const raw = imProc._buf.trim()
            imProc._buf = ""

            if (code === 0 && raw.length > 0) {
                root.fcitxAvailable = true
                root.currentLayout  = root._formatIM(raw)
            } else {
                // fcitx5 not running or returned an error
                root.fcitxAvailable = false
                root.currentLayout  = ""
            }
        }
    }

    // ── Poll every second ─────────────────────────────────────────────────────
    property var _pollTimer: Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: imProc.running = true
    }
}
