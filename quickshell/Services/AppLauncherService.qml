pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // ── Visibility ──────────────────────────────────────────────────────────
    property bool visible: false
    property string searchText: ""

    // ── Search debounce ─────────────────────────────────────────────────────
    property string _pendingSearch: ""
    property var _debounceTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: root.searchText = root._pendingSearch
    }

    function requestSearch(text) {
        _pendingSearch = text
        _debounceTimer.restart()
    }

    function open() {
        searchText = ""
        visible = true
    }

    function close() {
        visible = false
        searchText = ""
    }

    function toggle() {
        if (visible) close()
        else open()
    }

    // ── App list (live via DesktopEntries — auto-updates on install/remove) ──
    property var apps: []

    function _rebuildApps() {
        const vals = DesktopEntries.applications.values
        if (!vals) { apps = []; return }
        apps = [...vals].sort((a, b) => a.name.localeCompare(b.name))
    }

    readonly property var filteredApps: {
        const q = searchText.trim().toLowerCase()
        if (q === "") return apps
        return apps.filter(a => a.name.toLowerCase().indexOf(q) !== -1)
    }

    // ── Launch ───────────────────────────────────────────────────────────────
    function launch(entry) {
        entry.execute()
        close()
    }

    // ── Auto-refresh when apps are installed / removed ───────────────────────
    property var _watcher: Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root._rebuildApps() }
    }

    Component.onCompleted: _rebuildApps()
}
