pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

QtObject {
    id: root

    // All available players
    property var players: Mpris.players.values

    // Track the last active player identity so pausing doesn't jump
    property string _lastActiveIdentity: ""

    // Priority-based player selection:
    // 1. Currently playing player (prefer last-active if still playing)
    // 2. Last-active player if still available (even if paused)
    // 3. Any paused player
    // 4. First available player
    // 5. null
    property var player: {
        const list = players
        if (!list || list.length === 0) return null

        if (_lastActiveIdentity !== "") {
            for (let i = 0; i < list.length; i++) {
                if (list[i].identity === _lastActiveIdentity && list[i].isPlaying)
                    return list[i]
            }
        }

        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }

        if (_lastActiveIdentity !== "") {
            for (let i = 0; i < list.length; i++) {
                if (list[i].identity === _lastActiveIdentity)
                    return list[i]
            }
        }

        for (let i = 0; i < list.length; i++) {
            if (!list[i].isPlaying)
                return list[i]
        }

        return list[0]
    }

    onPlayerChanged: {
        // Seed live position from the new player's current reported value
        _livePosition = player ? player.position : 0
        _lastTickMs   = Date.now()
        if (player && player.isPlaying)
            _lastActiveIdentity = player.identity
    }

    // ── Live position tracking ──────────────────────────────────────────────
    // Key design principle: NEVER use Date.now() inside a binding expression.
    // Date.now() is a plain JS function — it is invisible to QML's dependency
    // tracker and will NEVER cause a binding to re-evaluate on its own.
    //
    // Correct pattern: the timer directly mutates _livePosition (a real QML
    // property).  Any binding that reads _livePosition — progress, the bar
    // width, etc. — is automatically notified and re-evaluated by Qt's property
    // change system without any "dummy tick" tricks.

    property real _livePosition: 0  // current displayed position in seconds
    property real _lastTickMs:   0  // wall-clock ms at last timer tick
                                    // real (not int) — Date.now() ~1.74e12 overflows int32

    // Guard flag: set to true for one event-loop turn after any track change so
    // that onPositionChanged cannot race-override the reset to zero.
    property bool _justChangedTrack: false

    property var _playerConnections: Connections {
        target: root.player

        // Real seek from D-Bus — snap to the reported position.
        // Skipped for one event-loop turn after a track change to prevent the
        // position update that the player emits alongside the track transition
        // from overriding the reset to zero.
        function onPositionChanged() {
            if (root._justChangedTrack) return
            if (root.player) {
                root._livePosition = root.player.position
                root._lastTickMs   = Date.now()
            }
        }

        // Track change via uniqueId — reset progress to zero.
        // uniqueId changes on next / previous / auto-advance for players that
        // implement MPRIS TrackId correctly.
        function onUniqueIdChanged() {
            root._justChangedTrack = true
            root._livePosition = 0
            root._lastTickMs   = Date.now()
            Qt.callLater(function() { root._justChangedTrack = false })
        }

        // Fallback for players that never change uniqueId (Spotify, most browser
        // media, etc.).  trackTitle changes on every track transition and is the
        // next-most-reliable indicator available over MPRIS.
        function onTrackTitleChanged() {
            root._justChangedTrack = true
            root._livePosition = 0
            root._lastTickMs   = Date.now()
            Qt.callLater(function() { root._justChangedTrack = false })
        }

        // Play / pause — re-anchor from the current reported position so we
        // don't accumulate time while the player is stopped.
        // Skipped during a track change (position hasn't settled yet).
        function onIsPlayingChanged() {
            if (root._justChangedTrack) return
            root._livePosition = root.player ? root.player.position : 0
            root._lastTickMs   = Date.now()
        }
    }

    // Every 500 ms while playing, advance _livePosition by the actual elapsed
    // wall-clock time.  Because _livePosition is a real QML property, every
    // binding that depends on it (progress, the bar width) re-evaluates
    // automatically — no dummy tick counter needed.
    property var _positionTimer: Timer {
        interval: 500
        running: root.isPlaying && root.hasPlayer
        repeat: true
        onTriggered: {
            const now     = Date.now()
            const elapsed = (now - root._lastTickMs) / 1000  // ms → seconds
            root._lastTickMs = now
            if (root.player && root.isPlaying) {
                const next = root._livePosition + elapsed
                root._livePosition = (root.length > 0)
                    ? Math.min(next, root.length)
                    : next
            }
        }
    }

    // Convenience properties
    readonly property bool   hasPlayer:   player !== null
    readonly property bool   isPlaying:   player ? player.isPlaying : false
    readonly property string trackTitle:  player ? (player.trackTitle  || "Unknown Title") : ""
    readonly property string trackArtist: player ? (player.trackArtist || "") : ""
    readonly property string trackArtUrl: player ? (player.trackArtUrl || "") : ""
    readonly property real   position:    _livePosition
    readonly property real   length:      player ? player.length : 0
    readonly property real   progress:    length > 0 ? _livePosition / length : 0
    readonly property bool   canNext:      player ? player.canGoNext     : false
    readonly property bool   canPrevious:  player ? player.canGoPrevious : false
    readonly property bool   canPlay:      player ? player.canPlay        : false

    // Actions
    function togglePlaying() {
        if (player) player.togglePlaying()
    }

    function next() {
        if (player && player.canGoNext) player.next()
    }

    function previous() {
        if (player && player.canGoPrevious) player.previous()
    }
}
