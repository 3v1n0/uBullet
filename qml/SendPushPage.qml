import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Connectivity 1.0
import "."

Page
{
  id: send_push_page
  property string type: Constants.typeNote
  title: i18n.tr("New Push")

  Flickable
  {
    clip: true
    contentHeight: main_column.height
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: send_button.top
    anchors.bottomMargin: Constants.defaultMargins

    ColumnLayout
    {
      id: main_column
      anchors.margins: Constants.defaultMargins
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: anchors.margins

      RowLayout
      {
        anchors.fill: parent

        Label
        {
          text: i18n.tr("To")
          fontSize: "x-small"
        }

        OptionSelector
        {
          readonly property var broadcastDevice: { "active": true, "pushable": true, "iden": "",
                                                   "nickname": i18n.tr("All my devices") }
          id: desination_selector
          expanded: false
          model: JSONListModel {}
          delegate: OptionSelectorDelegate { text: nickname; subText: model ? model : "" }
          Layout.fillWidth: true
          containerHeight: Math.min(model.count, 4) * itemHeight + (model.count > 4 ? itemHeight * 0.75 : 0)

          Component.onCompleted: {
            model.jsonObject = [broadcastDevice]
            main.pb.getDevices(function(devices) {
              devices.unshift(broadcastDevice)
              model.jsonObject = devices
            })
          }
        }
      }

      TextField
      {
        id: title
        placeholderText: i18n.tr("Title")
        Layout.fillWidth: true
      }

      TextField
      {
        id: link
        visible: send_push_page.type == Constants.typeLink
        placeholderText: i18n.tr("Link")
        Layout.fillWidth: true
      }

      RowLayout
      {
        visible: send_push_page.type == Constants.typeFile
        Label
        {
          text: i18n.tr("File")
          fontSize: "x-small"
        }

        Label
        {
          Layout.fillWidth: true
        }
      }

      UbuntuShape
      {
        visible: send_push_page.type == Constants.typeImage
        image: Image {
          id: push_image
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
        }
        Layout.fillWidth: true
      }

      TextArea
      {
        id: message
        placeholderText: i18n.tr("Message")
        Layout.fillWidth: true
      }
    }
  }

  Button
  {
    id: send_button
    property bool sending: false
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: Constants.defaultMargins
    enabled: NetworkingStatus.online && !sending
    text: i18n.tr("Send")
    color: Constants.pushbulletGreen

    onClicked: {}
  }
}
