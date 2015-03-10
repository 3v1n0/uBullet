import QtQuick 2.1
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.1

UbuntuShape
{
  id: bubble
  property bool aboutToRemove: false
  property string who: i18n.tr("You")
  property string to: i18n.tr("yourself")
  property string what
  property string title
  property string body
  property string img_src
  property string link
  property var when
  readonly property double content_spacing: units.gu(0.9)

  width: parent.width
  height: content_layout.height + content_spacing * 2
  color: "white"
  opacity: aboutToRemove ? 0.4 : 1.0

  image: Image
  {
    id: bg_image
    property bool ready: status == Image.Ready
    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    source: bubble.img_src ? (bubble.img_src + "?w=%1&h=%2&fit=crop".arg(width).arg(height)) : ""
  }

  function translatedWhat()
  {
    if (what == "note")
      return i18n.tr("note")
    else if (what == "link")
      return i18n.tr("link")
    else if (what == "file")
      return i18n.tr("file")
    else if (what == "list")
      return i18n.tr("list")

    return what
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
        text: i18n.tr("%1 sent %2 a %3".arg(bubble.who).arg(bubble.to).arg(bubble.translatedWhat()))
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

      Label
      {
        visible: bubble.link.length > 0
        text: "<a href=\"%1\">%2</a>".arg(bubble.link).arg(bubble.link)
        fontSize: "small"
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.maximumWidth: content_layout.width
        linkColor: "#6EC07C"
        onLinkActivated: Qt.openUrlExternally(link)
      }
    }
  }

  ActivityIndicator
  {
    anchors.centerIn: parent
    running: bubble.aboutToRemove
    visible: running
  }
}
