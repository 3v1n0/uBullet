import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Connectivity 1.0
import "."

Page
{
  id: send_push_page
  property string type: Constants.typeNote
  title: i18n.tr("New Push")

  Flickable
  {
    id: flickable_form
    clip: true
    enabled: !send_button.sending
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
          property bool valid: true
          readonly property var broadcastDevice: { "active": true, "pushable": true, "iden": "",
                                                   "nickname": i18n.tr("All my devices") }
          readonly property var customDevice: { "active": true, "pushable": true, "iden": "", "email": "",
                                                "nickname": i18n.tr("Custom device (email address)") }

          id: device_selector
          expanded: false
          model: JSONListModel {}
          Layout.fillWidth: true
          containerHeight: Math.min(model.count, 4) * itemHeight + (model.count > 4 ? itemHeight * 0.75 : 0)
          delegate: OptionSelectorDelegate {
            text: nickname
            subText: model ? model : (email ? email : "")
            onPressedChanged: {
              if (pressed && typeof(email) == "string" &&
                  device_selector.currentlyExpanded &&
                  (device_selector.selectedIndex == index || !email.length))
              {
                PopupUtils.open(custom_email_dialog)
              }
            }
          }

          onSelectedIndexChanged: {
            var device = getSelectedDevice();
            valid = !getSelectedDevice().email || getSelectedDevice().email.length > 0
          }

          Component.onCompleted: {
            model.jsonObject = [broadcastDevice]
            main.pb.getDevices(function(devices) {
              model.jsonObject.push.apply(model.jsonObject, devices)
              model.jsonObject.push(customDevice)
              model.updateJSONModel()
            })
          }

          function getSelectedDevice()
          {
            return model.get(selectedIndex)
          }

          Component
          {
            id: custom_email_dialog
            Dialog
            {
              id: dialog
              title: i18n.tr("Custom device")
              text: i18n.tr("Add an email address to send this push to (if not a Pushbullet user will get an email)")

              TextField
              {
                id: email_field
                text: device_selector.getSelectedDevice().email
                inputMethodHints: Qt.ImhEmailCharactersOnly
                validator: RegExpValidator { regExp:/\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*/ }
              }

              RowLayout
              {
                Button
                {
                  Layout.alignment: Qt.AlignHCenter
                  text: i18n.tr("Ok")
                  enabled: email_field.acceptableInput
                  color: UbuntuColors.orange
                  onClicked: {
                    device_selector.model.setProperty(device_selector.selectedIndex, "email", email_field.text)
                    device_selector.valid = true
                    PopupUtils.close(dialog)
                  }
                }

                Button
                {
                  Layout.alignment: Qt.AlignHCenter
                  text: i18n.tr("Cancel")
                  onClicked: {
                    device_selector.valid = device_selector.getSelectedDevice().email.length > 0
                    PopupUtils.close(dialog)
                  }
                }
              }
            }
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

  Rectangle
  {
    id: loading_overlay
    visible: send_button.sending
    opacity: visible ? 1 : 0
    anchors.fill: flickable_form
    color: Qt.rgba(UbuntuColors.coolGrey.r, UbuntuColors.coolGrey.g, UbuntuColors.coolGrey.b, 0.4)

    Behavior on opacity
    {
      UbuntuNumberAnimation { duration: UbuntuAnimation.BriskDuration }
    }

    ActivityIndicator
    {
      anchors.centerIn: parent
      running: parent.visible
    }
  }

  Button
  {
    id: send_button
    property bool sending: false
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: Constants.defaultMargins
    enabled: NetworkingStatus.online && device_selector.valid && !sending
    text: i18n.tr("Send")
    color: Constants.pushbulletGreen

    onClicked: {
      sending = true
      var push = {"type": send_push_page.type, "title": title.text, "body": message.text}

      if (push.type == Constants.typeLink)
        push.url = link.text

      main.pb.sendPush(push, function(reply) {
        sending = false

        if (reply.ok)
        {
          notification.show(i18n.tr("Push sent correctly!"))
          page_stack.pop()
        }
        else
        {
          var message = i18n.tr("Got an error while sending push");
          if (reply.error)
            i18n.tr("Got an error while sending push: %1".arg(reply.error.message));

          notification.show(message)
        }
      })
    }
  }
}
