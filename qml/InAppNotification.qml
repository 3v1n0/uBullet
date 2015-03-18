import QtQuick 2.1
import Ubuntu.Components 1.1

Item
{
  id: notification

  property int animationDuration: UbuntuAnimation.SleepyDuration
  property int standDuration: 1000
  property color bgColor: UbuntuColors.coolGrey
  property real bgOpacity: 0.8
  property var queue: []

  anchors.verticalCenter: parent.verticalCenter
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenterOffset: parent.height/4
  width: parent.width * 0.6

  function show(text)
  {
    if (typeof(text) == "string" && text.length)
    {
      if (bubble.state == "")
      {
        bubble.state = "visible"
        label.text = text;
      }
      else
      {
        queue.push(text)
      }
    }
  }

  UbuntuShape
  {
    id: bubble
    opacity: 0
    visible: opacity != 0
    color: Qt.rgba(notification.bgColor.r, notification.bgColor.g, notification.bgColor.b, notification.bgOpacity)
    width: parent.width
    height: label.height * 1.75

    Label
    {
      id: label
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
          target: bubble
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
      running: bubble.opacity == 1.0
      repeat: notification.queue.length > 0 && running
      onTriggered: {
        if (notification.queue.length)
          label.text = notification.queue.shift()
        else
          bubble.state = ""
      }
    }
  }
}
