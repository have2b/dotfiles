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

  Bar {
    id: bar
  }

  AppLauncher {
    id: appLauncher
  }

  NotificationCenter {
    id: notificationCenter
    anchor.window: bar
    anchor.rect: Qt.rect(bar.width - 1, 0, 1, bar.implicitHeight)
  }

  NetworkPanel {
    id: networkPanel
    anchor.window: bar
    anchor.rect: Qt.rect(bar.width - 1, 0, 1, bar.implicitHeight)
  }

  BluetoothPanel {
    id: bluetoothPanel
    anchor.window: bar
    anchor.rect: Qt.rect(bar.width - 1, 0, 1, bar.implicitHeight)
  }
}
