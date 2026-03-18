pragma Singleton
import QtQuick

QtObject {
    // ── Base Color Palette ──────────────────────────────────────────────────
    readonly property color light: "#e2e8f0"
    readonly property color primary: "#3b82f6"
    readonly property color accent: "#93c5fd"
    readonly property color secondary: "#818cf8"
    readonly property color background: "#0b132b"
    readonly property color error: "#ef4444"
    readonly property color success: "#22c55e"
    readonly property color warning: "#f59e0b"
    readonly property color surface: "#1a2744"
    readonly property color textDim: "#64748b"

    // ── Panel & Border Colors ───────────────────────────────────────────────
    readonly property color panelBorder: Qt.rgba(1, 1, 1, 0.08)
    readonly property color panelShadow: Qt.rgba(0, 0, 0, 0.30)
    readonly property color separator: Qt.rgba(1, 1, 1, 0.06)
    readonly property color barBorder: Qt.rgba(226/255, 232/255, 240/255, 0.18)

    // ── Surface / Card States ───────────────────────────────────────────────
    readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.10)
    readonly property color surfaceMuted: Qt.rgba(1, 1, 1, 0.05)
    readonly property color cardNormal: Qt.rgba(1, 1, 1, 0.03)
    readonly property color cardHover: Qt.rgba(1, 1, 1, 0.07)
    readonly property color cardBorder: Qt.rgba(1, 1, 1, 0.05)

    // ── Primary (blue) Tints ────────────────────────────────────────────────
    readonly property color primaryTint: Qt.rgba(59/255, 130/255, 246/255, 0.10)
    readonly property color primaryTintHover: Qt.rgba(59/255, 130/255, 246/255, 0.18)
    readonly property color primaryBorder: Qt.rgba(59/255, 130/255, 246/255, 0.22)
    readonly property color primaryBorderActive: Qt.rgba(59/255, 130/255, 246/255, 0.28)

    // ── Error (red) Tints ───────────────────────────────────────────────────
    readonly property color errorTint: Qt.rgba(239/255, 68/255, 68/255, 0.08)
    readonly property color errorTintHover: Qt.rgba(239/255, 68/255, 68/255, 0.20)
    readonly property color errorBorder: Qt.rgba(239/255, 68/255, 68/255, 0.28)

    // ── Accent (light-blue) Tints ───────────────────────────────────────────
    readonly property color accentTint: Qt.rgba(147/255, 197/255, 253/255, 0.07)
    readonly property color accentTintHover: Qt.rgba(147/255, 197/255, 253/255, 0.15)
    readonly property color accentBorder: Qt.rgba(147/255, 197/255, 253/255, 0.28)

    // ── Animation ──────────────────────────────────────────────────────────
    readonly property int animationFast: 120
    readonly property int animationNormal: 180

    // ── Common ─────────────────────────────────────────────────────────────
    readonly property int normalWidth: 14
    readonly property int barHeight: 36
    readonly property int iconSize: 14
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
