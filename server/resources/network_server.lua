local enet = require "enet"
require "resources.class"

--Split incoming data type
local dataSplitStr = "+|==@|"

--Client class-------------
local client = class({
  clients = {},

  _init = function(self, peer)
    self.peer = peer
    self.ip = peer
    self.timeout = 0

    table.insert(self.clients, self)
  end,

  --Send String
  send = function(self, data)
    self.peer:send(data)
  end,

  --Remove self from client list
  disconnected = function(self)
    if self.onDisconnect then
      self.onDisconnect()
    end

    for k, v in pairs(self.clients) do
      if v == self then
        table.remove(self.clients, k)
      end
    end
  end,

  --##CLASSMETHODS##--
  get = function(self, ip)
    for k, client in pairs(self.clients) do
      if client.ip == ip then
        return client
      end
    end
  end,

  getAll = function(self)
    return self.clients
  end
  })
---------------------------

local network = {}
network.sendData = {}
network.receiveHandle = {}
network.clientTimeout = 15

--Split String
function network.splitStr(str, splitChars)
    local result = {}
    for match in (str..splitChars):gmatch("(.-)"..splitChars) do
        table.insert(result, match)
    end
    return result
end

-- Get data in colon space format
function network.format(str, datType)
  local spaceTab = network.splitStr(str, " ")

  for k, dat in pairs(spaceTab) do
    local colonTab = network.splitStr(dat, ":")
    if colonTab[1] == datType then return colonTab[2] end
  end
end

network.host = enet.host_create()

--Connect to IP
function network.createServer(ip)
  network.host = enet.host_create(ip)
  return network.host
end

--Send data to client
function network.send(client, type, data)
  local data = data or ""
  table.insert(network.sendData, {client, type..dataSplitStr..data})
  return type..dataSplitStr..data
end

--Send data to all clients
function network.broadcast(type, data, exclusion)
  for k, client in pairs(client.clients) do
    if client ~= exclusion then
      network.send(client, type, data)
    end
  end
end

--Handle data
function network.receive(type, func)
  table.insert(network.receiveHandle, {type, func})
end
--Run Handles
function network.runHandles(handleType, event)
  if network.receiveHandle then
    local eventSplit = network.splitStr(event.data, dataSplitStr)
    if handleType == "receive" then
      for k, handle in pairs(network.receiveHandle) do
        if (eventSplit[1] == handle[1]) then
            handle[2](client:get(event.peer), eventSplit[2], event)
        end
      end
    end
    if handleType == "connect" or handleType == "disconnect" then
      for k, handle in pairs(network.receiveHandle) do
        if handle[1] == handleType then
          handle[2](client:get(event.peer))
        end
      end
    end
  end
end

--Update Network
function network.update(dt, timeout)
  --Communicate with clients
  if network.host then
    local event = network.host:service(timeout or 0)

    --Receive from client
    if event then
      --Client Connects
      if event.type == "connect" then
        local newClient = client._new(event.peer)

        network.runHandles("connect", event)
      end
      --Client disconnects
      if event.type == "disconnect" then
        if client:get(event.peer) then
          client:get(event.peer):disconnected()
        end

        network.runHandles("disconnect", event)
      end
      --Handle data
      if event.type == "receive" then
        network.runHandles("receive", event)

        if event.data == "=pong=" then
          client:get(event.peer).timeout = 0
        end
      end

      event = network.host:service()
    end

    --Send to clients
    if network.sendData then
      for k, info in pairs(network.sendData) do
        local client = info[1]
        if client then
          local data = info[2]
          if string.match(data, "pl1") then
            print(data)
          end
          client:send(data)
          network.sendData[k] = nil
        end
      end
    end

    --Update Client Timeouts
    for k, client in pairs(client.clients) do
      client:send("=ping=")
      client.timeout = client.timeout + dt

      if client.timeout > network.clientTimeout then
        client.peer:disconnect()
        client:disconnected()
      end
    end
  end
end

return network

