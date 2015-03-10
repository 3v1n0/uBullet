import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Connectivity 1.0
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1
import Ubuntu.PushNotifications 0.1
import U1db 1.0 as U1db
import "Pushbullet.js" as PB
import "3rd-party"

MainView
{
  id: main
  readonly property string appId: applicationName + "_pushbullet"

  property string token
  property string deviceIden
  property var pb: null

  applicationName: "xyz.trevisan.marco.ubullet"
  automaticOrientation: true
  useDeprecatedToolbar: false

  width: units.gu(40)
  height: units.gu(71)

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
    appId: main.appId

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
    pb.getPushes(0, function(status, reply) {
      push_model.jsonObject = (status == 200) ? reply.pushes : null
    })
  }

  SharePopup
  {
    id: share_popup
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

    ListView
    {
      anchors.fill: parent
      model: JSONListModel { id: push_model }

      delegate: ListItemWithActions {
        width: parent.width
        height: bubble.height + units.gu(2)

        leftSideAction: Action {
          iconName: "delete"
          text: i18n.tr("Remove")
          onTriggered: {
            bubble.aboutToRemove = true
            pb.deletePush(iden, function(status) {
              if (status == 200)
                push_model.remove(index)

              bubble.aboutToRemove = false
            })
          }
        }

        rightSideActions: [
          Action
          {
            iconName: "save"
            text: i18n.tr("Download")
            visible: type && type == "file" && file_url
            onTriggered: {
              // TODO implement proper download
              Qt.openUrlExternally(file_url)
            }
          },
          Action
          {
            iconName: "share"
            text: i18n.tr("Share")
            visible: typeof(url) != "undefined" || typeof(file_url) != "undefined"
            onTriggered: {
              share_popup.shareLink(url || file_url, title)
            }
          }
        ]

        PushBubble
        {
          id: bubble
          who: (sender_iden === pb.me.iden) ? i18n.tr("You") : (sender_name ? sender_name : sender_email)
          to: (sender_iden === pb.me.iden) ? i18n.tr("yourself") : i18n.tr("you")
          what: type
          title: model.title ? model.title : (file_name ? file_name : "")
          body: model.body ? model.body : ""
          when: created
          img_src: image_url ? image_url : ""
          link: url ? url : ""
        }
      }
    }

    ActivityIndicator
    {
      running: true
      visible: !deviceIden.length && !push_model.count
      anchors.centerIn: parent
    }
  }
}
