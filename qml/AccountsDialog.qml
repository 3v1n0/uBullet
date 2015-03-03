import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.OnlineAccounts 0.1
import Ubuntu.OnlineAccounts.Client 0.1

Dialog
{
  id: dialog
  property var account_model
  signal authorized(string id)

  title: i18n.tr("No Account configured")
  text: i18n.tr("Authorize or select the PushBullet account you want to use")

  OptionSelector
  {
    id: accounts
    expanded: true
    visible: model.count > 0
    model: account_model
    delegate: OptionSelectorDelegate { text: displayName; }
    onSelectedIndexChanged: error_label.error = undefined
  }

  Text
  {
    id: error_label
    property var error: undefined
    visible: error ? true : false
    wrapMode: Text.WordWrap
    color: UbuntuColors.darkAubergine
    text: "Impossible to authenticate account; error: "+error
  }

  RowLayout
  {
    Button
    {
      id: select_button
      text: i18n.tr("Select")
      visible: accounts.visible
      Layout.minimumWidth: parent.width/2
      color: UbuntuColors.orange
      onClicked: {
        var handle = accounts.model.get(accounts.selectedIndex, "accountServiceHandle")
        account_service.objectHandle = handle
        account_service.authenticate(null)
      }
      AccountService
      {
        id: account_service
        onAuthenticated: dialog.authorized(accountId)
        onAuthenticationError: {error_label.visible = true; error_label.error = error.message }
      }
    }

    Button
    {
      Layout.alignment: Qt.AlignHCenter
      Layout.minimumWidth: parent.width/2
      text: i18n.tr(accounts.visible ? "Add More" : "Add account")
      color: accounts.visible ? UbuntuColors.warmGrey : UbuntuColors.orange
      onClicked: {
        if (accounts.model.count == 0)
        {
          accounts.model.countChanged.connect(function() {
            if (accounts.model.count == 1)
              select_button.clicked()
          });
        }

        account_setup.exec();
      }

      Setup
      {
        id: account_setup
        applicationId: main.appId
        providerId: main.applicationName + "_pushbullet-account"
      }
    }
  }
}
