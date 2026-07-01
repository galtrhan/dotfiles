pragma Singleton
import Quickshell
import QtQuick

Singleton {
  property string namedaysText: ""
  property string namedaysTooltip: ""
  property string ipText: ""
  property string tempsText: ""
  property string tempsTooltip: ""
  property string tempsClass: ""
  property string recText: ""
  property bool copyIpRequested: false
  property string recClass: "idle"
  property int brightnessPercent: -1
}
