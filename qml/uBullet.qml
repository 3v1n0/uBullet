import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import Ubuntu.PushNotifications 0.1
import U1db 1.0 as U1db
import "Pushbullet.js" as PB

MainView
{
  id: main
  applicationName: "xyz.trevisan.marco.ubullet"
  readonly property string appId: applicationName + "_ubullet"

  property string token
  property string deviceIden
  property var pb: null

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
    defaults: {"account_id": 0, "device_iden": ""}

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
        setupAccount();
      }
    }

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
        dialog.show();

        dialog.authorized.connect(function(id) {
          services_model.startAuth(id)
          dialog.hide()
          dialog.destroy()
        });
      }
    }
  }

  PushClient
  {
    id: push_client
    appId: main.applicationName + "_pushbullet"

    onTokenChanged: {
      setupPushNotifications()
    }
    onError: console.error("PushClient Error:", error)
  }

  onTokenChanged: {
    console.log("PB Token set to",token)
    pb = token.length ? new PB.Pushbullet(token) : null
    setupDevice()
  }

  onDeviceIdenChanged: {
    settings.set("device_iden", deviceIden)
    setupPushNotifications()
  }

  function setupDevice()
  {
    if (!pb)
      return

    pb.ensureDevice(push_client.token, settings.get("device_iden"), function(reply) {
      if (!pb.device)
        return;

      deviceIden = pb.device.iden
    });
  }

  function setupPushNotifications()
  {
    if (pb && deviceIden.length)
      pb.setPushToken(push_client.token)
  }

  Page
  {
    id: main_page
    title: i18n.tr("uBullet")

    ActivityIndicator
    {
      running: true
      anchors.centerIn: parent
    }
  }
}
