import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1

UbuntuShape
{
  id: bubble
  property string sender: "You"
  property string what: "note"
  property string title
  property string body
  property string img_src
  property var when
  readonly property double content_spacing: units.gu(0.9)

  width: parent.width
  height: childrenRect.height + content_spacing
  color: "white"

  image: Image
  {
    id: bg_image
    property bool ready: status == Image.Ready
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    source: bubble.img_src ? (bubble.img_src + "?w=%1&h=%2&fit=crop".arg(width).arg(height)) : ""
  }

  Rectangle
  {
    visible: bg_image.ready
    anchors.fill: parent
    color: "black"
    radius: units.gu(0.9)
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#cc000000" }
      GradientStop { position: 1.0; color: "#22000000" }
    }
  }

  ColumnLayout
  {
    id: content_layout
    x: content_spacing
    y: content_spacing
    width: parent.width - content_spacing * 2
    Layout.alignment: Qt.AlignTop | Qt.AlignLeft

    RowLayout
    {
      Layout.alignment: Qt.AlignTop

      Label
      {
        text: "%1 sent yourself a %2".arg(bubble.sender).arg(bubble.what)
        fontSize: "x-small"
        font.weight: Font.Bold
        color: "#aaa"
        Layout.fillWidth: true
      }

      Label
      {
        text: new Date(bubble.when * 1000).toLocaleString(Qt.locale(), Locale.ShortFormat)
        fontSize: "small"
        color: "#aaa"
        Layout.alignment: Qt.AlignRight
      }
    }

    ColumnLayout
    {
      Layout.fillHeight: false

      Label
      {
        Layout.alignment: Qt.AlignTop
        visible: text.length > 0
        text: bubble.title
        fontSize: "medium"
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        Layout.maximumWidth: content_layout.width
        color: bg_image.ready ? "white" : "#34495E"
      }

      Label
      {
        visible: text.length > 0
        text: bubble.body
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        Layout.maximumWidth: content_layout.width
        color: bg_image.ready ? "white" : "black"
      }
    }
  }
}