local enet = require "enet"

local dataSplitStr = "+|==@|"
local defaultPort = "4799"

local network = {}
network.sendData = {}
network.receiveHandle = {}

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
function network.connect(ip, port)
  local usePort = port
  if port == nil then
    usePort = defaultPort
  end

  -- network.server = network.host:connect(ip..":"..usePort)
  network.server = network.host:connect("192.168.0.72:4799")

  return network.server, network.host
end

--Send data to server
function network.sendToServer(type, data)
  local data = data or ""
  table.insert(network.sendData, type..dataSplitStr..data)
end

--Handle data
function network.receive(data, func)
  table.insert(network.receiveHandle, {data, func})
end

--Run Handles
function network.runHandles(handleType, event)
  if network.receiveHandle then
    local eventSplit = network.splitStr(event.data, dataSplitStr)
    if handleType == "receive" then
      for k, handle in pairs(network.receiveHandle) do
        if (eventSplit[1] == handle[1]) then
            handle[2](eventSplit[2], event)
        end
      end
    end
    if handleType == "connect" or handleType == "disconnect" then
      for k, handle in pairs(network.receiveHandle) do
        if handle[1] == handleType then
          handle[2]()
        end
      end
    end
  end
end
--Update Network
function network.update(dt, timeout)
  --Communicate with server
  if network.server then
    local event = network.host:service(timeout or 0)

    --Receive from server
    if event then
      --Client Connects
      if event.type == "connect" then

        network.runHandles("connect", event)
      end
      --Client disconnects
      if event.type == "disconnect" then
        network.runHandles("disconnect", event)
      end
      --Handle data
      if event.type == "receive" then
        network.runHandles("receive", event)

        if event.data == "=ping=" then
          network.server:send("=pong=")
        end
      end


      event = network.host:service()
    end

    --Send to server
    if network.sendData then
      for k, data in pairs(network.sendData) do
        network.server:send(data)
      end
      network.sendData = {}
    end
  end
end

return network

