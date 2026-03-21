pragma Singleton
import QtQuick

QtObject {
    // ── Catppuccin Macchiato Palette ─────────────────────────────────────────

    // Base surfaces (darkest → lightest)
    readonly property color crust:      "#181926"
    readonly property color mantle:     "#1e2030"
    readonly property color background: "#24273a"   // base  — main bar bg
    readonly property color surface:    "#363a4f"   // surface0 — pill backgrounds
    readonly property color surface1:   "#494d64"   // surface1 — hover states
    readonly property color overlay:    "#6e738d"   // overlay0 — muted borders

    // Text
    readonly property color light:    "#cad3f5"     // text     — primary labels
    readonly property color subtext:  "#b8c0e0"     // subtext1 — secondary labels
    readonly property color textDim:  "#a5adcb"     // subtext0 — dim / date / icons

    // Accent palette
    readonly property color primary:   "#8aadf4"    // blue   — network, primary actions
    readonly property color accent:    "#c6a0f6"    // mauve  — active workspace, BT
    readonly property color secondary: "#c6a0f6"    // alias for accent
    readonly property color teal:      "#8bd5ca"    // teal
    readonly property color sky:       "#91d7e3"    // sky
    readonly property color pink:      "#f5bde6"    // pink
    readonly property color peach:     "#f5a97f"    // peach

    // Semantic
    readonly property color success: "#a6da95"      // green
    readonly property color warning: "#eed49f"      // yellow
    readonly property color error:   "#ed8796"      // red

    // ── Panel & Border Colors ───────────────────────────────────────────────
    readonly property color panelBorder: Qt.rgba(202/255, 211/255, 245/255, 0.10)
    readonly property color panelShadow: Qt.rgba(0, 0, 0, 0.50)
    readonly property color separator:   Qt.rgba(202/255, 211/255, 245/255, 0.10)
    readonly property color barBorder:   Qt.rgba(202/255, 211/255, 245/255, 0.08)

    // ── Surface / Card States ───────────────────────────────────────────────
    readonly property color surfaceHover:  Qt.rgba(202/255, 211/255, 245/255, 0.08)
    readonly property color surfaceMuted:  Qt.rgba(138/255, 173/255, 244/255, 0.08)
    readonly property color cardNormal:    Qt.rgba(202/255, 211/255, 245/255, 0.04)
    readonly property color cardHover:     Qt.rgba(138/255, 173/255, 244/255, 0.12)
    readonly property color cardBorder:    Qt.rgba(138/255, 173/255, 244/255, 0.08)

    // ── Primary (blue) Tints ────────────────────────────────────────────────
    readonly property color primaryTint:         Qt.rgba(138/255, 173/255, 244/255, 0.12)
    readonly property color primaryTintHover:    Qt.rgba(138/255, 173/255, 244/255, 0.20)
    readonly property color primaryBorder:       Qt.rgba(138/255, 173/255, 244/255, 0.24)
    readonly property color primaryBorderActive: Qt.rgba(138/255, 173/255, 244/255, 0.32)

    // ── Error (red) Tints ───────────────────────────────────────────────────
    readonly property color errorTint:      Qt.rgba(237/255, 135/255, 150/255, 0.10)
    readonly property color errorTintHover: Qt.rgba(237/255, 135/255, 150/255, 0.22)
    readonly property color errorBorder:    Qt.rgba(237/255, 135/255, 150/255, 0.30)

    // ── Accent (mauve) Tints ────────────────────────────────────────────────
    readonly property color accentTint:      Qt.rgba(198/255, 160/255, 246/255, 0.10)
    readonly property color accentTintHover: Qt.rgba(198/255, 160/255, 246/255, 0.18)
    readonly property color accentBorder:    Qt.rgba(198/255, 160/255, 246/255, 0.32)

    // ── Animation ──────────────────────────────────────────────────────────
    readonly property int animationFast:   120
    readonly property int animationNormal: 180
    readonly property int animationSlow:   280

    // ── Geometry ───────────────────────────────────────────────────────────
    readonly property int normalWidth:  14
    readonly property int barHeight:    40      // visible pill height
    readonly property int iconSize:     14
    readonly property int panelRadius:  12
    readonly property int buttonRadius: 6

    // ── Typography ────────────────────────────────────────────────────────
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
