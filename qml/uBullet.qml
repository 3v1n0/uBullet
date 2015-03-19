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

  property string accountToken
  property string deviceIden
  property var pb: null

  applicationName: "xyz.trevisan.marco.ubullet"
  automaticOrientation: true
  useDeprecatedToolbar: false
  anchorToKeyboard: true

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

  Connections
  {
    target: NetworkingStatus

    onOnlineChanged: {
      if (NetworkingStatus.online)
        setUpPB()
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
          return get(i, "accountServiceHandle");
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
      accountToken = reply.AccessToken;
    }
    onEnabledChanged: {
      if (!enabled)
      {
        accountToken = ""
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

  Loader
  {
    id: push_client
    property bool enabled: NetworkingStatus.online
    property string token

    onEnabledChanged: sourceComponent = enabled ? push_client_component : null

    Component
    {
      id: push_client_component

      PushClient
      {
        appId: main.appId

        onTokenChanged: {
          push_client.token = token;
          setupPushNotifications()
        }

        onError: console.error("PushClient Error:", status)
        Component.onDestruction: push_client.token = ""
      }
    }
  }

  onAccountTokenChanged: {
    push_model.clear()
    setUpPB()
  }

  onDeviceIdenChanged: {
    settings.set("device_iden", deviceIden)
    setupPushNotifications()
    updatePushModel()
  }

  SharePopup
  {
    id: share_popup
  }

  function setUpPB()
  {
    if (NetworkingStatus.online)
    {
      pb = accountToken.length ? new PB.Pushbullet(accountToken) : null
      setupDevice()
    }
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

  function updatePushModel()
  {
    if (push_model.updating)
      return;

    push_model.updating = true;
    pb.getPushes({}, function(reply) {
      push_model.jsonObject = reply.ok && reply.data ? reply.data.pushes : null
      push_model.updating = false
    })
  }


  PageStack
  {
    id: page_stack

    function showSendPushPage(type)
    {
      push(Qt.resolvedUrl("SendPushPage.qml"), {type: type})
    }

    Page
    {
      id: main_page
      title: i18n.tr("uBullet")
      visible: false

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
              pb.deletePush(iden, function(reply) {
                if (reply.ok)
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
              visible: model.type && type == "file" && model.file_url
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
            who: (sender_iden === pb.me.iden) ? i18n.tr("You") : (model.sender_name ? sender_name : sender_email)
            to: (sender_iden === pb.me.iden) ? (model.to ? (model.to.name ? model.to.name : model.to.email) : i18n.tr("yourself")) : i18n.tr("you")
            what: type
            title: model.title ? model.title : (model.file_name ? file_name : "")
            body: model.body ? model.body : ""
            when: created
            img_src: model.image_url ? image_url : ""
            link: model.url ? url : ""
          }
        }

        PullToRefresh
        {
          property bool refresh_requested: false
          refreshing: refresh_requested && push_model.updating
          onRefresh: {
            refresh_requested = true
            updatePushModel();
          }
        }
      }

      ActivityIndicator
      {
        id: loading_indicator
        anchors.centerIn: parent
        visible: !push_model.count && (push_model.updating || (!deviceIden.length && NetworkingStatus.online))
        running: visible
      }

      EmptyState
      {
        id: empty_state
        anchors.centerIn: parent
        width: parent.width
        visible: !push_model.count && !loading_indicator.visible
        iconName: "info"
        title: i18n.tr("No Push bullets")
        subTitle: i18n.tr("Use the bottom edge to send a new Push")

        states: [
          State
          {
            name: "OFFLINE"
            when: !NetworkingStatus.online
            PropertyChanges
            {
              target: empty_state
              iconName: "sync-offline"
              title: i18n.tr("No Push bullets")
              subTitle: i18n.tr("Ensure you've an active connection in order to fetch your pushes")
            }
          }
        ]
      }

      RadialBottomEdge
      {
        expandAngle: 180
        hintIconName: "add"
        actions: [
          RadialAction
          {
            iconName: "stock_image"
            iconColor: UbuntuColors.coolGrey
            onTriggered: page_stack.showSendPushPage("image")
          },

          RadialAction
          {
            iconName: "note"
            iconColor: UbuntuColors.coolGrey
            onTriggered: page_stack.showSendPushPage("note")
          },

          RadialAction
          {
            iconName: "external-link"
            iconColor: UbuntuColors.coolGrey
            onTriggered: page_stack.showSendPushPage("link")
          },

          RadialAction
          {
            iconName: "attachment"
            iconColor: UbuntuColors.coolGrey
            onTriggered: page_stack.showSendPushPage("file")
          }
        ]
      }

      Component.onCompleted: page_stack.push(main_page)
    }
  }
}
