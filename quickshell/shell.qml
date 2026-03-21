import Quickshell
import Quickshell.Hyprland
import "Components"
import "./" as App

ShellRoot {
  id: root

  // ── Global shortcut: Super + D toggles the app launcher ──────────────────
  // Add this line to ~/.config/hypr/hyprland.conf:
  //   bind = SUPER, D, global, quickshell:launcher
  GlobalShortcut {
    name: "launcher"
    description: "Toggle app launcher"
    onPressed: App.AppLauncherService.toggle()
  }

  // Spawn one bar per connected screen
  Variants {
    id: barVariants
    model: Quickshell.screens
    Bar {
      required property var modelData
      screen: modelData
    }
  }

  // First instantiated bar — popup panels anchor to this window
  readonly property var primaryBar: barVariants.instances.length > 0 ? barVariants.instances[0] : null
  readonly property rect panelAnchorRect: primaryBar
    ? Qt.rect(primaryBar.width - 1, 0, 1, primaryBar.implicitHeight)
    : Qt.rect(0, 0, 1, 40)

  AppLauncher {
    id: appLauncher
  }

  NotificationCenter {
    id: notificationCenter
    anchor.window: root.primaryBar
    anchor.rect: root.panelAnchorRect
  }

  NetworkPanel {
    id: networkPanel
    anchor.window: root.primaryBar
    anchor.rect: root.panelAnchorRect
  }

  BluetoothPanel {
    id: bluetoothPanel
    anchor.window: root.primaryBar
    anchor.rect: root.panelAnchorRect
  }
}
