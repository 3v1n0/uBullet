import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import U1db 1.0 as U1db

MainView
{
  id: main
  applicationName: "xyz.trevisan.marco.ubullet"
  readonly property string appId: applicationName + "_ubullet"

  width: units.gu(40)
  height: units.gu(71)
  useDeprecatedToolbar: false

  Connections
  {
    target: Qt.application

    Component.onCompleted: {
      Qt.application.organization = "uBullet"
      Qt.application.domain = "3v1n0.net"
    }
  }

  U1db.Database
  {
    id: db
    path: "uBullet.db"
  }

  U1db.Document
  {
    id: settings

    database: db
    docId: "settings"
    create: true
    defaults: {"account_token": ""}

    function get(key) { return contents[key] }
    function set(key, val) { var cnt = contents; cnt[key] = val; contents = cnt; }
  }

  Page
  {
    id: main_page
    title: i18n.tr("uBullet")

    Component.onCompleted: {
      if (settings.get("account_token").length == 0)
      {
        // For some reason PopupUtils.open doesn't seem to work here :o
        var dialog = Qt.createComponent("AccountsDialog.qml").createObject(main);
        dialog.onVisibleChanged.connect(dialog.__closeIfHidden);
        main.Component.onDestruction.connect(dialog.__closePopup);
        dialog.show();

        dialog.authorized.connect(function(token) {
          settings.set("account_token", token);
          dialog.hide()
        });
      }
    }
  }
}
