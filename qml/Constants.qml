pragma Singleton
import QtQuick 2.0
import Ubuntu.Components 1.0

QtObject
{
  readonly property real defaultMargins: units.gu(1.5)

  readonly property color pushbulletGreen: "#6EC07C"
  readonly property color pushbulletBlue: "#34495E"

  readonly property string typeNote: "note"
  readonly property string typeLink: "link"
  readonly property string typeFile: "file"
  readonly property string typeList: "list"
  readonly property string typeImage: "image"
}
