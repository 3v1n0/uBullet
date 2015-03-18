import QtQuick 2.1
import Ubuntu.Components 1.1

Item
{
  id: notification

  property int animationDuration: UbuntuAnimation.SleepyDuration
  property int standDuration: 1000
  property color bgColor: UbuntuColors.coolGrey
  property real bgOpacity: 0.8

  anchors.verticalCenter: parent.verticalCenter
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenterOffset: parent.height/4
  width: parent.width * 0.6

  function show(text)
  {
    notification_label.text = typeof(text) == "string" ? text : ""
    notification_bubble.state = notification_label.text.length ? "visible" : ""
  }

  UbuntuShape
  {
    id: notification_bubble
    opacity: 0
    visible: opacity != 0
    color: Qt.rgba(notification.bgColor.r, notification.bgColor.g, notification.bgColor.b, notification.bgOpacity)
    width: parent.width
    height: notification_label.height * 1.75

    Label
    {
      id: notification_label
      fontSize: "small"
      color: "white"
      width: parent.width * 0.95
      anchors.centerIn: parent
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    states: [
      State {
        name: "visible"

        PropertyChanges {
          target: notification_bubble
          opacity: 1.0
        }
      }
    ]

    transitions: [
      Transition {
        UbuntuNumberAnimation {
          properties: "opacity"
          duration: notification.animationDuration
        }
      }
    ]

    Timer
    {
      interval: notification.standDuration
      running: notification_bubble.opacity == 1.0
      onTriggered: notification_bubble.state = ""
    }
  }
}
