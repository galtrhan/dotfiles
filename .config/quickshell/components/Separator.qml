import QtQuick
import ".."
import "."

BarLabel {
    property string variant: "dot"

    text: variant === "line" ? "|" : "·"
    labelColor: Theme.fgMuted
}
