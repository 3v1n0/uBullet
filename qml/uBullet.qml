import QtQuick 2.1
import Ubuntu.Components 1.1
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1

MainView
{
  id: main
  width: units.gu(40)
  height: units.gu(71)
  applicationName: "xyz.trevisan.marco.ubullet"
  useDeprecatedToolbar: false

  Connections
  {
    target: Qt.application

    Component.onCompleted: {
      Qt.application.organization = "uBullet"
      Qt.application.domain = "3v1n0.net"
    }
  }
}
