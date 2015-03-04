var MACHINE_ID_FILE = "/etc/machine-id"
var MACHINE_BUILD_PROPS = "/system/build.prop"
var PB_API_PATH = "https://api.pushbullet.com/v2/"

function Pushbullet(access_token) {
  this.access_token = access_token
  this.device_iden = null;
  this.machine_id = null
  this.devices = null
}

Pushbullet.prototype = {
  ensureDevice: function(push_token, device_iden, cb)
  {
    var pb = this
    pb.push_token = "ubuntu:" + push_token
    pb.device_iden = device_iden;

    pb.__getMachineId(function() {
      pb.getDevices(function(devices) {
        var device = null
        for (var d in devices)
        {
          if (devices[d].active &&
              (devices[d].fingerprint === pb.machine_id ||
               devices[d].iden == pb.device_iden))
          {
            device = devices[d]
            pb.device_iden = device.iden;
            break;
          }
        }

        if (!device)
        {
          pb.createDevice(cb)
        }
        else
        {
          pb.updateDevice(cb)
        }
      })
    });
  },

  createOrUpdateDevice: function(cb)
  {
    var pb = this
    pb.deviceData(function(device_data) {
      pb.__doPostRequest("devices", device_data, function(status, reply) {
        pb.device_iden = reply.iden
        if (cb) cb(reply)
      })
    })
  },

  updateDevice: function(cb)
  {
    if (!this.device_iden)
    {
      console.error("Impossible to update a device with no iden")
      if (cb) cb()
      return;
    }

    var pb = this
    pb.deviceData(function(device_data) {
      pb.__doPostRequest("devices/"+pb.device_iden, device_data, function(status, reply) {
        if (cb) cb(reply)
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
    var device_data = {"push_token": this.push_token, "type": "ubuntu", "kind": "ubuntu" };

    pb.__getMachineId(function() {
      device_data["fingerprint"] = pb.machine_id

      pb.__getDeviceProperties(function(dev_props) {
        device_data["nickname"] = "Ubuntu Phone"

        if ("ro.product.brand" in dev_props)
          device_data["manufacturer"] = dev_props["ro.product.brand"]

        if ("ro.product.model" in dev_props)
          device_data["model"] = dev_props["ro.product.model"]

        if ("manufacturer" in device_data)
        {
          device_data["nickname"] = device_data["manufacturer"]

          if ("model" in device_data)
            device_data["nickname"] += " " + device_data["model"]
        }
        else if ("model" in device_data)
        {
          device_data["nickname"] == device_data["model"]
        }

        if (cb) cb(device_data)
      })
    })
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
      pb.machine_id = response.trim()
      if (cb) cb(pb.machine_id)
    })
  },

  __getDeviceProperties: function(cb)
  {
    this.__getLocalFile(MACHINE_BUILD_PROPS, function(response) {
      var props = {}
      var lines = response.split("\n")
      for (var i in lines)
      {
        var trimmed = lines[i].trim()
        if (trimmed.length == 0 || trimmed[0] == "#")
          continue;

        var parameter = trimmed.split("=")
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
        cb(xhr.status, JSON.parse(xhr.responseText))
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
