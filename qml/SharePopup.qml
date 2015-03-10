import QtQuick 2.1
import Ubuntu.Components 1.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Content 0.1

Item
{
  id: shareItem
  signal done()

  Component
  {
    id: shareDialog
    PopupBase
    {
      id: shareDialog
      anchors.fill: parent
      property var activeTransfer
      property var items: []
      property alias contentType: peerPicker.contentType

      ContentPeerPicker
      {
        id: peerPicker
        handler: ContentHandler.Share
        visible: parent.visible

        onPeerSelected: {
          activeTransfer = peer.request()
          activeTransfer.items = shareDialog.items
          activeTransfer.state = ContentTransfer.Charged
          PopupUtils.close(shareDialog)
        }

        onCancelPressed: {
          PopupUtils.close(shareDialog)
        }
      }

      Component.onDestruction: shareItem.done()
    }
  }

  Component
  {
    id: contentItemComponent
    ContentItem {}
  }

  function share(url, name, contentType)
  {
    var sharePopup = PopupUtils.open(shareDialog, shareItem, {"contentType" : contentType})
    sharePopup.items.push(contentItemComponent.createObject(shareItem, {"url" : url, "name" : name}))
  }

  function shareLink(url, title)
  {
    share(url, title, ContentType.Links)
  }
}
