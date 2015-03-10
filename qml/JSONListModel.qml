import QtQuick 2.1
import "jsonpath.js" as JSONPath

ListModel
{
  property bool updating: false
  property var jsonObject: null
  property string query

  onJsonObjectChanged: updateJSONModel()
  onQueryChanged: updateJSONModel()
  Component.onCompleted: updateJSONModel();

  function updateJSONModel()
  {
    clear();

    var json = query.length ? JSONPath.jsonPath(jsonObject, query) : jsonObject
    for (var key in json)
      append(json[key]);
  }
}
