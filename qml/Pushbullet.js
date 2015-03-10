.pragma library

var MACHINE_ID_FILE = "/etc/machine-id"
var MACHINE_BUILD_PROPS = "/system/build.prop"
var PB_API_PATH = "https://api.pushbullet.com/v2/"

function Pushbullet(access_token) {
  this.access_token = access_token
  this.push_token = null
  this.device = null
  this.device_iden = null
  this.machine_id = null
  this.devices = null
  this.me = null
  this.updateMe()
}

Pushbullet.prototype = {
  updateMe: function(cb)
  {
    var pb = this
    this.__doGetRequest("users/me", function(status, reply) {
      if (status == 200)
        pb.me = reply
      if (cb) cb()
    });
  },

  setPushToken: function(push_token, cb)
  {
    this.push_token = (push_token && push_token.length) ? "ubuntu:" + push_token : null

    if (this.device && this.device.push_token !== this.push_token)
      this.updateDevice(cb)
  },

  ensureDevice: function(push_token, device_iden, cb)
  {
    var pb = this
    console.log("ENSURE DEVBICE",push_token,device_iden)
    pb.device = null
    pb.setPushToken(push_token)

    pb.getDevices(function(devices) {
      pb.__getMachineId(function() {
        for (var d in devices)
        {
          if (devices[d].active &&
              (devices[d].fingerprint === pb.machine_id ||
               devices[d].iden === device_iden))
          {
            pb.device = devices[d]
            break;
          }
        }

        pb.device ? pb.updateDevice(cb) : pb.createDevice(cb);
      })
    });
  },

  createDevice: function(cb)
  {
    var pb = this
    pb.deviceData(function(device_data) {
      pb.__doPostRequest("devices", device_data, function(status, reply) {
        pb.device = (reply && "iden" in reply) ? reply : null
        if (cb) cb(reply)
      })
    })
  },

  updateDevice: function(cb)
  {
    if (!this.device || !this.device.iden)
    {
      console.error("Impossible to update a device with no iden")
      if (cb) cb()
      return;
    }

    var pb = this
    pb.deviceData(function(device_data) {
      pb.__doPostRequest("devices/"+pb.device.iden, device_data, function(status, reply) {
        pb.device = (reply && "iden" in reply) ? reply : null
        if (cb) cb(pb.device)
      })
    })
  },

  getDevices: function(cb)
  {
    if (this.devices !== null)
    {
      if (cb) cb(this.devices)
      return
    }

    var pb = this
    pb.__doGetRequest("devices", function(status, reply) {
      if (status == 200 && reply.devices)
        pb.devices = reply.devices

      if (cb) cb(pb.devices !== null ? pb.devices : [])
    })
  },

  deviceData: function(cb)
  {
    var pb = this;
    var device_data = {"type": "ubuntu", "kind": "ubuntu" };

    if (this.push_token)
      device_data.push_token = this.push_token

    pb.__getMachineId(function() {
      device_data.fingerprint = pb.machine_id

      pb.__getDeviceProperties(function(dev_props) {
        device_data.nickname = "Ubuntu Phone"

        if ("ro.product.brand" in dev_props)
          device_data.manufacturer = dev_props["ro.product.brand"]

        if ("ro.product.model" in dev_props)
          device_data.model = dev_props["ro.product.model"]

        if ("model" in device_data)
          device_data.nickname = device_data["model"]

        if ("manufacturer" in device_data)
          device_data.nickname = device_data.manufacturer + " " + device_data.nickname

        if (cb) cb(device_data)
      })
    })
  },

  getPushes: function(params, cb)
  {
    var since = params && typeof(params.since) == 'number' ? params.since : 0
    var active = params && (typeof(params.only_active) == 'undefined' || params.only_active)
    this.__doGetRequest("pushes?modified_after=%1&active=%2".arg(since).arg(active ? "true" : "false"), cb);
  },

  deletePush: function(iden, cb)
  {
    this.__doDeleteRequest("pushes/"+iden, cb);
  },

  __getMachineId: function(cb)
  {
    if (this.machine_id)
    {
      cb(this.machine_id)
      return
    }

    var pb = this
    pb.__getLocalFile(MACHINE_ID_FILE, function(response) {
      if (typeof(response) === 'string')
        pb.machine_id = response.trim()
      if (cb) cb(pb.machine_id)
    })
  },

  __getDeviceProperties: function(cb)
  {
    this.__getLocalFile(MACHINE_BUILD_PROPS, function(response) {
      var props = {}
      var lines = (typeof(response) === 'string') ? response.split("\n") : []

      for (var i in lines)
      {
        var trimmed = lines[i].trim()
        if (trimmed.length == 0 || trimmed[0] == "#")
          continue;

        var parameter = trimmed.split("=")
        if (parameter.length == 2)
          props[parameter[0]] = parameter[1]
      }

      if (cb) cb(props)
    })
  },

  __getLocalFile: function(path, cb)
  {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", "file://"+path, true)
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE && cb)
        cb(xhr.responseText)
    }
    xhr.send()
  },

  __doRequest: function(api, mode, parameters, cb)
  {
    var xhr = new XMLHttpRequest()
    xhr.open(mode, PB_API_PATH + api, true)

    xhr.setRequestHeader("Authorization", "Bearer " + this.access_token)
    xhr.setRequestHeader("Accept", "application/json");
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.setRequestHeader("User-Agent", "UbuntuPhone");

    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE && cb)
      {
        var reply = xhr.responseText ? JSON.parse(xhr.responseText) : null
        if (xhr.status != 200)
        {
          var error_string = (reply && "error" in reply) ? reply.error.type+": "+reply.error.message : ""
          console.error("Got error "+xhr.status+(error_string.length ? "; "+error_string : ""));
        }

        cb(xhr.status, reply)
      }
    };
    xhr.send(parameters ? JSON.stringify(parameters) : null)
  },

  __doGetRequest: function(api, cb)
  {
    this.__doRequest(api, "GET", null, cb)
  },

  __doPostRequest: function(api, parameters, cb)
  {
    this.__doRequest(api, "POST", parameters, cb)
  },

  __doDeleteRequest: function(api, cb)
  {
    this.__doRequest(api, "DELETE", null, cb)
  },
}
