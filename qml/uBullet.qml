import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import U1db 1.0 as U1db

MainView
{
  id: main
  applicationName: "xyz.trevisan.marco.ubullet"
  readonly property string appId: applicationName + "_ubullet"
  property string token

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
    defaults: {"account_id": 0}

    function get(key) { return contents[key] }
    function set(key, val) { var cnt = contents; cnt[key] = val; contents = cnt; }
  }

  AccountServiceModel
  {
    id: services_model
    applicationId: main.appId

    function getAccountById(id)
    {
      for (var i = 0; i < count; ++i)
      {
        if (get(i, "accountId") == id)
        {
          return get(i, "accountServiceHandle");
        }
      }

      return null;
    }

    function startAuth(id)
    {
      var accountHandle = getAccountById(id);
      if (accountHandle)
      {
        account_service.objectHandle = accountHandle;
        account_service.authenticate(null);
      }
    }
  }

  AccountService
  {
    id: account_service

    onAuthenticationError: {
      console.error("Impossible to auth with accout "+displayName+": "+error.message)
      settings.set("account_id", 0)
    }
    onAuthenticated: {
      settings.set("account_id", accountId)
      token = reply.AccessToken;
    }
    onEnabledChanged: {
      if (!enabled)
      {
        token = ""
        main_page.setupAccount();
      }
    }
  }

  Page
  {
    id: main_page
    title: i18n.tr("uBullet")

    Component.onCompleted: setupAccount()

    function setupAccount()
    {
      var accountId = settings.get("account_id")

      if (services_model.getAccountById(accountId))
      {
        services_model.startAuth(accountId)
      }
      else
      {
        // For some reason PopupUtils.open doesn't seem to work here :o
        var dialog = Qt.createComponent("AccountsDialog.qml").createObject(main);
        dialog.onVisibleChanged.connect(dialog.__closeIfHidden);
        main.Component.onDestruction.connect(dialog.__closePopup);
        dialog.account_model = services_model;
        dialog.show();

        dialog.authorized.connect(function(id) {
          services_model.startAuth(id)
          dialog.hide()
          dialog.destroy()
        });
      }
    }
  }
}
