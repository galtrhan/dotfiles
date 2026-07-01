pragma Singleton
import Quickshell
import QtQuick

Singleton {
  readonly property SystemClock clock: SystemClock {
    precision: SystemClock.Seconds
  }
}
