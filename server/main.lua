local enet = require "enet"
local net = require "resources.network_server"
require "resources.class"

--Server Player Class
local player = class({
  players = {},

  _init = function(self, client, x, y)
    self.client = client
    self.client.onDisconnect = function()
      for k, ply in pairs(self.players) do
        net.broadcast("player_disconnected", self.id)
        if ply == self then table.remove(self.players, k) end
      end
    end

    self:createId()
    self.x , self.y = tonumber(x), tonumber(y)

    table.insert(self.players, self)
  end,

  --Create ID
  createId = function(self)
    local plys = 0
    for k, ply in pairs(self.players) do
      plys = plys + 1
    end
    self.id = plys
  end,

  --Get player pos to be networked
  getPos = function(self)
    return "id:"..self.id.." x:"..self.x.." y:"..self.y
  end,

  --Get player info to be networked
  getInfo = function(self)
    return "name:"..self.name.." id:"..self.id.." x:"..self.x.." y:"..self.y.." colorR:"..self.color[1].." colorG:"..self.color[2].." colorB:"..self.color[3]
  end,

  getById = function(self, id)
    for k, ply in pairs(self.players) do
      if ply.id == id then
        return ply
      end
    end
  end
  })



---------------------
function love.load()
	love.window.setTitle("Server")

  net.createServer("192.168.0.72:4799")
end

function love.update(dt)
  --Update Network
  net.update(dt, 100)

end

--Networking------------------------
--Player Connects
net.receive("player_info", function(client, data)
  local name = net.format(data, "name")
  local x = net.format(data, "x")
  local y = net.format(data, "y")

  local r = net.format(data, "colorR")
  local g = net.format(data, "colorG")
  local b = net.format(data, "colorB")

  local ply = player._new(client, x, y)
  ply.name = name
  ply.color = {r,g,b}

  --Send player ID
  net.send(client, "get_id", tostring(ply.id))

  --Send client other player info
  for k, pl in pairs(player.players) do
    if pl.id ~= ply.id then
      net.send(client, "create_player", pl:getInfo())
    end
  end
  --Send new player dat to all other players
  net.broadcast("create_player", ply:getInfo(), client)
end)

--Player sends new Position
net.receive("player_position", function(client, data)
    local id = tonumber(net.format(data, "id"))
    local x = tonumber(net.format(data, "x"))
    local y = tonumber(net.format(data, "y"))

    local ply = player:getById(id)
    if ply then
      ply.x = x
      ply.y = y

      net.broadcast("player_position", ply:getPos())
    end
end)

function love.draw()
  for k, ply in pairs(player.players) do
    love.graphics.setColor(ply.color[1], ply.color[2], ply.color[3])
    love.graphics.rectangle("fill", ply.x, ply.y, 7, 7)
  end
end


