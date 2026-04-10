import Quickshell
import QtQuick

// import "modules/bar"
// import "modules/notifications"
import "Modules/Sidebar"
import "Modules/BackendTesterPanel"
import "Modules/NetworkWidget"
import "Services" as Svc

ShellRoot {

  // Load Services on startup
  Component.onCompleted: {
    Svc.ThemeService.load();
    Svc.BackendService.load();
  }

  Sidebar {}

  BackendTesterPanel {}

  NetworkWidget {}
}
