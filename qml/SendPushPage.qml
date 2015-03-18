import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Connectivity 1.0

Page
{
  id: send_push_page
  property string type: "note"
  title: i18n.tr("New Push")

  Flickable
  {
    clip: true
    contentHeight: main_column.height
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: send_button.top
    anchors.bottomMargin: units.gu(1.5)

    ColumnLayout
    {
      id: main_column
      anchors.margins: units.gu(1.5)
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
          id: desination_selector
          expanded: false
          model: 4
          delegate: OptionSelectorDelegate { text: "faa"+index }
          onSelectedIndexChanged: {}
          Layout.fillWidth: true
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
        visible: send_push_page.type == "link"
        placeholderText: i18n.tr("Link")
        Layout.fillWidth: true
      }

      RowLayout
      {
        visible: send_push_page.type == "file"
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
        visible: send_push_page.type == "image"
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
    anchors.margins: units.gu(1.5)
    enabled: NetworkingStatus.online && !sending
    text: i18n.tr("Send")
    color: "#6EC07C"

    onClicked: {}
  }
}
