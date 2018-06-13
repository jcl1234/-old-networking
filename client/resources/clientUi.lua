local ui = require "resources.ui"
local class = require "resources.class"
local net = require "resources.network_client"

ui.defaultFont = love.graphics.newFont(13)

local gui = {}
--------------------------------------------
--Main Menu
function gui.createMainMen(player)
  --Main Menu
  gui.mainMenu = ui.Menu._new(0,0,300,168)
  gui.mainMenu:center(400,300)
  gui.mainMenu.draggable = true


  --Join Server Menu---------------------------------
  local joinMenu = ui.Menu._new(10,16,280,140,gui.mainMenu)
  joinMenu.color = {50,50,50}
  --Ip Textbox
  local ipTextbox = ui.Textbox._new(65,58,110,15,joinMenu)
  ipTextbox:allowChars({{".",":"}, ipTextbox.numbers})
  ipTextbox.label:setFont(love.graphics.newFont(10))
  --Ip Textbox Label
  local joinLabel = ui.Label._new("IP:", ipTextbox.x - 25, ipTextbox.y - 1, joinMenu)
  --Join Server Button
  local joinBtn = ui.Button._new(ipTextbox.x + ipTextbox.width + 10, ipTextbox.y - 3, 60, 20, joinMenu)
  joinBtn.color = {0,100,0}
  joinBtn:setLabel("Connect")
  joinBtn.onClick = function()
    net.connect(ipTextbox.text)
  end

  --Set Name
  local nameBox = ui.Textbox._new(65,18,110,15,joinMenu)
  nameBox.limit = 10
  nameBox.spaces = false
  nameBox.onType = function()
    player:setName(nameBox.text)
  end
  --Name Label
  local nameLabel = ui.Label._new("Name:", nameBox.x - 55, nameBox.y - 1, joinMenu)
  ---------------------------------------------------

  --Color Buttons
  local colors = {{255,255,255}, {255,0,0}, {0,255,0}, {0,0,255}, {255,255,0}, {255,0,255}, {0,255,255}}
  local butSize = 30
  local colorButs = {}
  for k, color in pairs(colors) do
    local colorButton = ui.Button._new(5 + ((k - 1) * (butSize + 10)), joinMenu.height - butSize - 10, butSize, butSize, joinMenu)
    local realCol = color
    colorButton.color = color
    colorButton.selected = false
    local dulCol = {}

    for k, col in pairs(color) do
      local newCol = col
      if col == 255 then newCol = 120 end
      table.insert(dulCol, newCol)
    end

    colorButton.onClick = function()
      for k, btn in pairs(colorButs) do
        btn.selected = false
      end
      colorButton.selected = true

      player.color = realCol
    end

    local oldDraw = colorButton.draw
    colorButton.draw = function(colorButton)
      if not colorButton.selected then
        colorButton.color = dulCol
      else
        colorButton.color = realCol
      end
      oldDraw(colorButton)
    end

    table.insert(colorButs, colorButton)
  end
  colorButs[1].selected = true
end


-- local joinMenu = ui.Menu._new(50,50,200,300)
-- joinMenu.draggable = false
-- joinMenu:center(400,300)

-- local serverMsg = ui.Textbox._new(10,10,100,15,joinMenu)
-- serverMsg:allowChars({{".",":"}, serverMsg.numbers})
-- serverMsg.label:setFont(love.graphics.newFont(10))
-- local sendBtn = ui.Button._new(130,10,60,20,joinMenu)
-- sendBtn.color = {0,100,0}
-- sendBtn:setLabel("Connect")

-- receiveLabel = ui.Label._new("-", 10,100, joinMenu)

-- local pooBtn = ui.Button._new(50,150,60,20, joinMenu)
-- pooBtn.onClick = function()
--   network.sendToServer("fart", serverMsg.text)
-- end

-- sendBtn.onClick = function()
--   local ip = network.splitStr(serverMsg.text, ":")
--   local port = nil
--   local len = 0
--   --Get port
--   for k,v in pairs(ip) do
--     len = len + 1
--   end

--   if len > 1 then
--     port = ip[2]
--   end

--   local server = network.connect(ip[1], port)
-- end

-- --Receive from server
-- network.receive("fart", function(data)
--   receiveLabel:setText(data)
-- end)
























































--------------------------------------------
function gui.init()

  --Init ui
  ui.init()
end

function gui.update(dt)

  --Update UI
  ui.update(dt)
end

function gui.mousepressed(button)
  --Ui MousePress
  ui.mousepressed(button)
end

function gui.mousereleased(button)
  --Ui Mouserelease
  ui.mousereleased(button)
end

--Key Pressed
function gui.keypressed(key)
  --Ui KeyPress
  ui.keypressed(key)
end

function gui.textinput(key)
  --Ui Text Input
  ui.textinput(key)
end

--Graphics
function gui.draw(dt)

  --Draw UI
  ui.draw(dt)
end

return gui