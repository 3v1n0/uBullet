import QtQuick 2.1
import Ubuntu.Components 1.1

Item
{
  id: notification

  property int animationDuration: UbuntuAnimation.SleepyDuration
  property int standDuration: 1500
  property color bgColor: UbuntuColors.coolGrey
  property real bgOpacity: 0.8
  property alias fontSize: label.fontSize
  property alias fontWeight: label.font.weight
  property var queue: []

  anchors.verticalCenter: parent.verticalCenter
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenterOffset: parent.height/4
  width: parent.width * 0.75
  z: Number.POSITIVE_INFINITY

  function show(text)
  {
    if (typeof(text) == "string" && text.length)
    {
      if (!bubble.showing)
      {
        bubble.showing = true
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
    property bool showing: false
    opacity: showing ? 1 : 0
    visible: opacity != 0
    color: Qt.rgba(notification.bgColor.r, notification.bgColor.g, notification.bgColor.b, notification.bgOpacity)
    width: parent.width
    height: label.height * 2.25

    Label
    {
      id: label
      fontSize: "small"
      font.weight: Font.Bold
      color: "white"
      width: parent.width * 0.95
      anchors.centerIn: parent
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    Behavior on opacity
    {
      UbuntuNumberAnimation { duration: UbuntuAnimation.SleepyDuration }
    }

    Timer
    {
      interval: notification.standDuration
      running: bubble.showing
      repeat: running
      onTriggered: {
        if (notification.queue.length)
          label.text = notification.queue.shift()
        else
          bubble.showing = false
      }
    }
  }
}
