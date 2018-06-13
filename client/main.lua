local ui = require "resources.clientUi"
local net = require "resources.network_client"
-------------------------------------------------

local game = {}
game.state = "menu"
game.screenW, game.screenH = nil, nil

local nameFont = love.graphics.newFont(10)

--Control Handling--
local function isDown(key)
  return love.keyboard.isDown(key)
end

--Player Class------
local player = class({
  players = {},

  _init = function(self, x, y)

    self.networkX = nil
    self.networkY = nil
    self.x = tonumber(x)
    self.y = tonumber(y)
    self.id = nil

    self.color = {255,255,255}
    self.size = 7

    self.active = false
    self.client = false

    self.speed = 5

    self.nameColor = {255,255,255}
    self.name =  ""
    self.textWidth = nameFont:getWidth(self.name)

    table.insert(self.players, self)

  end,
  --Set Player Name
  setName = function(self, name)
    self.name = name
    self.textWidth = nameFont:getWidth(self.name)
  end,
  --Move player
  move = function(self, dir, factor)
    local factor = factor or 1
    if dir == "hor" then self.x = self.x + self.speed * factor
    elseif dir == "vert" then self.y = self.y + self.speed * factor end
  end,

  --Get player pos to be networked
  getPos = function(self)
    return "id:"..self.id.." x:"..self.x.." y:"..self.y
  end,

  --Get player info to be networked
  getInfo = function(self)
    return "name:"..self.name.." x:"..self.x.." y:"..self.y.." colorR:"..self.color[1].." colorG:"..self.color[2].." colorB:"..self.color[3]
  end,

  --Network position
  updatePos = function(self)
    if self.x ~= self.networkX or self.y ~= self.networkY then
      if not self.id then return end
      net.sendToServer("player_position", self:getPos())
    end
  end,
  --Controls
  update = function(self)
    if self.client then
      --Move controls
      if self.active and game.state ~= "menu" then
        if isDown("w") and self.y > 0 then self:move("vert", -1) end
        if isDown("s") and self.y + self.size < game.screenH then self:move("vert") end
        if isDown("d") and self.x + self.size < game.screenW then self:move("hor") end
        if isDown("a") and self.x > 0 then self:move("hor", -1) end
      end
      self:updatePos()
    end
  end,

  draw = function(self)
    if self.active then
      --Draw Name
      love.graphics.setColor(self.nameColor[1], self.nameColor[2], self.nameColor[3])
      love.graphics.print(self.name, self.x - self.textWidth/2, self.y - 20)
      --Draw box
      love.graphics.setColor(self.color[1], self.color[2], self.color[3])
      love.graphics.rectangle("fill", self.x, self.y, self.size, self.size)
    end
  end,

  --##CLASSMETHODS##--
  updateAll = function(self)
    for k, ply in pairs(self.players) do
      ply:update()
    end
  end,

  drawAll = function(self)
    --Draw other players
    for k, ply in pairs(self.players) do
      if ply ~= localPlayer then
        ply:draw()
      end
    end

    --Draw Local Player
    localPlayer:draw()
  end,

  getById = function(self, id)
    for k, ply in pairs(self.players) do
      if ply.id == id then
        return ply, k
      end
    end
  end
  })

function love.load()
  love.window.setTitle("Client")

  --Create player
  localPlayer = player._new(20, 20, "Fred")
  localPlayer.client = true
  localPlayer.active = true

  ui.createMainMen(localPlayer)


  --Init screen size
  game.screenW, game.screenH = love.graphics.getDimensions()
  --Init ui
  ui.init()
end

function love.update(dt)
  --Update Plyaers
  player:updateAll()
  --Update Network
  net.update(dt)
  --Update UI
  ui.update(dt)

  --Set player display
  if ui.mainMenu.vis then
    localPlayer.x, localPlayer.y = ui.mainMenu.x + 230, ui.mainMenu.y + 40
  end
end

function love.mousepressed(button)
  --Ui MousePress
  ui.mousepressed(button)
end

function love.mousereleased(button)
  --Ui Mouserelease
  ui.mousereleased(button)
end

--Key Pressed
function love.keypressed(key)
  --Ui KeyPress
  ui.keypressed(key)
end

function love.textinput(key)
  --Ui Text Input
  ui.textinput(key)
end

--Graphics
function love.draw(dt)
  --Draw UI
  ui.draw(dt)

  --Draw Players
  player:drawAll()
end

--Networking------------
--Connect to server
net.receive("connect", function()
  ui.mainMenu:close()
  game.state = "play"

  net.sendToServer("player_info", localPlayer:getInfo())
end)

--Set Local Player ID
net.receive("get_id", function(data)
  local id = tonumber(data)
  localPlayer.id = id
end)

--Create player from server
net.receive("create_player", function(data)
  local id = net.format(data, "id")
  local name = net.format(data, "name")
  local x = net.format(data, "x")
  local y = net.format(data, "y")

  local r = net.format(data, "colorR")
  local g = net.format(data, "colorG")
  local b = net.format(data, "colorB")

  local ply = player._new(x, y)
  ply.id = tonumber(id)
  ply:setName(name)
  ply.color = {r,g,b}
  ply.active = true
end)

--Receive player position
net.receive("player_position", function(data)
  local id = tonumber(net.format(data, "id"))
  local x = tonumber(net.format(data, "x"))
  local y = tonumber(net.format(data, "y"))

  local ply = player:getById(id)

  if localPlayer == ply then
    localPlayer.networkX, localPlayer.networkY = tonumber(x), tonumber(y)
  else
    ply.x, ply.y = x, y
  end

end)

--Player Disconnected
net.receive("player_disconnected", function(data)
  if not data then return end
  local ply, ind = player:getById(tonumber(data))

  if ind then
    table.remove(player.players, ind)
  end
end)