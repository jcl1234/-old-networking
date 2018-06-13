require("resources.class")

--Utility
local util = {}
--Convert color to decimal val
function util.col(col)
    local r,g,b = col[1], col[2], col[3]
    local fac = 1/255
    return {fac * r, fac * g, fac * b}
end
--Get if point is in square
function util.inSquare(x, y, item)
    if (x >= item.x and x <= item.x + item.width) and (y >= item.y and y <= item.y + item.height) then return true end
end
--Set graphics color to item color
function util.setCol(colorTab)
    love.graphics.setColor(util.col(colorTab))
end


local ui = {}
ui.util = util
--#########--
ui.defaultFont = love.graphics.newFont(14)
--#########--
ui.hovered = nil
ui.mode = nil
ui.clickItem = nil
ui.releaseItem = nil
ui.curTime = 0

local screenW, screenH = love.graphics.getDimensions()
local mouseX,mouseY = nil, nil
--#########--
--Get Hovered Item
local function getHoveredChild(item)
    local hovered = item
    if item.children then
        for k, child in pairs(item.children) do
            if child.hoverable and child.vis and (child.width and child.height) and util.inSquare(mouseX,mouseY,child) then
                hovered = getHoveredChild(child)
            end
        end
    end

    return hovered
end

function ui.getHovered()
    local hovered = nil
    --Get Hovered Menu
    for k, menu in pairs(ui.Menu.menus) do
        if menu.vis and util.inSquare(mouseX,mouseY,menu) then
            hovered = menu
        end
    end

    --Get hovered child
    if hovered then
        for k, child in pairs(hovered.children) do
            if child.hoverable then
                if child.vis and util.inSquare(mouseX,mouseY,child) then
                    hovered = getHoveredChild(child)
                end
            end
        end
    end

    ui.hovered = hovered
end

--Stop Dragging Menu
function ui.stopDragging()
    if ui.mode == "dragging" then ui.mode = nil end
end

--Initialize UI
function ui.init()
    screenW, screenH = love.graphics.getDimensions()
end

--UI Update
function ui.update(dt)
    --Update Program Time
    ui.curTime = ui.curTime + dt
    --Update mouse pos
    mouseX,mouseY = love.mouse.getPosition()
    --Update Hovered Item
    ui.getHovered()

    --Run custom update functions on elements
    for k, element in pairs(ui.UiElement.elements) do
        if element.update then element:update(dt) end
    end

    --Update Children
    ui.Menu.updateChildren()
end

--Mouse Clicked
function ui.mousepressed(button)
    ui.clickItem = ui.hovered

    if not ui.clickItem then return end

    --Run mousepressed on ui elements
    for k, element in pairs(ui.UiElement.elements) do
        if element.mousepressed then
            element:mousepressed(ui.clickItem)
        end
    end

    --Bring clicked menu to top
    ui.Menu.headMenu(ui.clickItem):top()
end

--Mouse released
function ui.mousereleased(button)
    ui.releaseItem = ui.hovered
    ui.stopDragging()

    if not ui.releaseItem then ui.clickItem = nil return end

    --Run Mouse released on objects
    for k, element in pairs(ui.UiElement.elements) do
        if element.mousereleased then
            element:mousereleased(ui.releaseItem)
        end
    end

    --Run Click function on items
    for k, element in pairs(ui.UiElement.elements) do
        if ui.releaseItem == ui.clickItem and ui.releaseItem == element then
            if element.onClick then
                    element:onClick()
            end
        end
    end

    ui.clickItem = nil
end

--Key Pressed
function ui.keypressed(key)

    --Run key pressed function on elements
    if key ~= nil then
        for k, element in pairs(ui.UiElement.elements) do
            if element.keypressed then
                element:keypressed(key)
            end
        end 
    end
end

--Key Down
function ui.textinput(key)

    --Run key down function on elements
    if key ~= nil then
        for k, element in pairs(ui.UiElement.elements) do
            if element.textinput then
                element:textinput(key)
            end
        end
    end
end

--Draw UI
function ui.draw(dt)
    --Draw Menus
    for k,menu in pairs(ui.Menu.menus) do
        if menu.draw and menu.vis then
            menu:draw(dt)
        end
    end
end
--                ||||||||||||||||||||||||||||||||||||||||||||||||||||||||                --
--UI BASE CLASSES vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv                --

--Ui Element
ui.UiElement = class({
    elements = {},
    _init = function(self, x, y, width, height, parent)
        self.color = {200,100,0}
        self.hoverable = true
        --Draw on loop
        self.loopDraw = true
        self.parent = parent
        --Dimensions
        self.startX, self.x, self.startY, self.y = x, x, y, y    
        self.width, self.height = width, height

        --Init child
        if self.parent then 
            self.parent:addChild(self)
            self.vis = true
        end

        table.insert(ui.UiElement.elements, self)
    end,

    --Draw Function
    draw = function(self)
        util.setCol(self.color)
        love.graphics.rectangle("fill",self.x,self.y,self.width,self.height)
    end
    })

--Menu Class----------------------------------------------------------------------
ui.Menu = class({
    menus = {},
    childMenus = {},

    _init = function(self, x, y, width, height, parent)
        self.type = "menu"
        self.children = {}
        self.super()._init(self, x, y, width, height, parent)
        self.border = 1
        self.borderColor = {255,255,255}

        self.edgeBound = true
        self.transparent = false
        self.draggable = true

        --Bind
        self.bind = nil
        self.hasCondition = false
        self.condition = nil

        self.dragX, self.dragY = 0, 0

        if not self.parent then
            self.color = {100,100,100}
            self.vis = false
            table.insert(self.menus, self)            
        else
            self.vis = true
            self.color = {200,0,0}
        end
    end,

    --Add Child
    addChild = function(self, child)
        local hasChild = false
        for k,v in pairs(self.children) do
            if v == child then hasChild = true end
        end
        if not hasChild then
            table.insert(self.children, child)
            if child.type == "menu" then
                table.insert(self.childMenus, child)
            end
        end
    end,

    --Create at location
    open = function(self, x, y)
        local x, y = x or self.x, y or self.y
        self.startX, self.x, self.startY, self.y = x, x, y, y
        self.vis = true
    end,

    --Hide menu
    close = function(self)
        self.vis = false
    end,

    --Center menu on position
    center = function(self, x, y)
        self:open(x - self.width/2, y - self.height/2)
    end,

    --Bring menu to front of list
    top = function(self)
        local menu = ui.Menu.headMenu(self)
        for k,v in pairs(ui.Menu.menus) do
            if v == menu then
                table.remove(ui.Menu.menus, k)
                table.insert(ui.Menu.menus, v)
            end
        end
    end,

    setBind = function(self, bind, condition)
        self.bind, self.condition = bind, condition
        if condition ~= nil then
            self.hasCondition = true
        else
            self.hasCondition = false
        end
    end,

    --Open menu from bind
    keypressed = function(self, key)
        if ui.mode ~= nil then return end
        if key == self.bind then
            if not self.vis then
                if (self.hasCondition and self.condition) or (not self.hasCondition) then
                    self:open()
                    self:top()

                    ui.stopDragging()
                end
            else
                self:close()
            end
        end
    end,

    --Mouse Pressed
    mousepressed = function(self, item)
        if item ~= self then return end
            --Bring menu to top
            self:top()

        --Start Dragging if mouse is on any type of menu
        if not ui.mode then
            if self.draggable or self.parent then
                local self = self.headMenu(ui.clickItem)
                ui.mode = "dragging"
                self.startX, self.startY = self.x, self.y
                self.dragX, self.dragY = mouseX, mouseY
            end
        end
    end,

    --Menu Dragging
    update = function(self)
        local menu = self.headMenu(ui.clickItem)
        if menu ~= self then return end
        if ui.mode == "dragging" then
            if menu.vis then
                local offsetX, offsetY = menu.dragX - menu.startX, menu.dragY - menu.startY
                local newX, newY = mouseX - offsetX, mouseY - offsetY
                --Lock menu to screen boundaries
                if menu.edgeBound then
                    if (newX < 0) then newX = 0 end
                    if newX + menu.width > screenW then newX = screenW - menu.width end
                    if (newY < 0) then newY = 0 end
                    if newY + menu.height > screenH then newY = screenH - menu.height end
                end
                menu.x, menu.y = newX, newY
            else
                ui.stopDragging()
            end
        end
    end,

    draw = function(self)
        if self.vis and self.loopDraw then
            if not self.transparent then
                --Draw Border
                if self.border > 0 then
                    local borderX, borderY, borderWidth, borderHeight = self.x - self.border, self.y - self.border, self.width + (self.border * 2), self.height + (self.border * 2)
                    util.setCol(self.borderColor)
                    love.graphics.rectangle("fill", borderX, borderY, borderWidth, borderHeight)
                end
                --Draw self
                util.setCol(self.color)
                love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
            end
            --Draw Children
            for k, child in pairs(self.children) do
                if child.draw and child.vis and  child.loopDraw then
                    child:draw()
                end 
            end
        end
    end,



    --##CLASSMETHODS##--
    --Get top menu parent of a child
    headMenu = function(child)
        local item = child
        if item and item.parent then
            repeat 
                item = item.parent
            until not item.parent
        end

        return item
    end,

    updateChildren = function()
        --Menu Children
        for k, menu in pairs(ui.Menu.menus) do
            for k, child in pairs(menu.children) do
                child.x, child.y = menu.x + child.startX, menu.y + child.startY
            end
        end
        --Child menu children
        for k, menu in pairs(ui.Menu.childMenus) do
            for k, child in pairs(menu.children) do
                child.x, child.y = menu.x + child.startX, menu.y + child.startY
            end
        end
    end

    }, ui.UiElement)

--Label Class--------------------------------------
ui.Label = class({
    _init = function(self, text, x, y, parent)
        self.type = "label"
        self.super()._init(self, x, y, nil, nil, parent)
        self.hoverable = false
        self.color = {255,255,255}

        self.font = nil
        self.text = text

        self.center = false

        self.textWidth = nil
        self.textHeight = nil

        self:setFont(ui.defaultFont)
    end,

    draw = function(self)
        util.setCol(self.color)
        love.graphics.setFont(self.font)

        if not self.center then
            love.graphics.print(self.text, self.x, self.y)
        else
            love.graphics.print(self.text, self.x - self.textWidth/2, self.y - self.textHeight/2)
        end
    end,

    setText = function(self, text)
        self.text = text

        self:setSize()
    end,

    setFont = function(self, font)
        self.font = font

        self:setSize()
    end,

    setSize = function(self)
        if not self.font then return end
        self.textWidth = self.font:getWidth(self.text or "")
        self.textHeight = self.font:getHeight()
    end

    }, ui.UiElement)

--Button Class------------
ui.Button = class({
    buttons = {},

    _init = function(self, x, y, width, height, parent)
        self.type = "button"
        self.super()._init(self, x, y, width, height, parent)

        self.onClick = nil
        self.label = nil

        self.hovered = false
        self.hoverCol = {150,150,150}

        self.clickColor = {0,0,200}
        self.border = 2

        table.insert(self.buttons, self)
    end,

    --Set Text On BUtton
    setLabel = function(self, text)
        local label = ui.Label._new(text, self.x + self.width/2, self.y + self.height/2, self.parent)
        label.center = true

        self.label = label
    end,

    draw = function(self)
        if not self.transparent then
            --Clicked
            if self.clickColor and self == ui.hovered and self == ui.clickItem and ui.mode ~= "dragging" then
                util.setCol(self.clickColor)
                love.graphics.rectangle("fill", self.x - self.border, self.y - self.border, self.width + self.border * 2, self.height + self.border * 2)
            end

            --Hovered
            if self.hoverCol and self == ui.hovered and ui.mode ~= "dragging" then
                util.setCol(self.hoverCol)
            else
                util.setCol(self.color)
            end

            love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
        end
    end

    }, ui.UiElement)

--Textbox Class
ui.Textbox = class({
    mode = "textbox",

    lowercase = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"},
    uppercase = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"},
    numbers = {"1","2","3","4","5","6","7","8","9","0"},
    punctuation = {",","'", '"', ";", ".", ":"},
    special = {"~","`","!","@","#","$","%","^","&","*","(",")","-","_","=","+","[","]","{","}","/","\\"},
    _init = function(self, x, y, width, height, parent)
        self.type = "textbox"
        self.super()._init(self, x, y, width, height, parent)

        --Create button and label
        self:createButton()
        self:createLabel()

        self.cursorTime = 0
        self.cursorRate = 0.5
        self.text = ""
        self.cursor = "|"
        self.displayText = ui.Label._new("", x, y, parent)
        self.spaces = true
        self.selected = false
        self.limit = 0

        self.shiftDown = false


        --Color
        self.color = {200,0,0}
        self.border = 2
        self.borderColor = {150,0,0}

        self.allowed = {self.lowercase, self.uppercase, self.numbers}
        self.forbid = {}
    end,

    createButton = function(self)
        self.textButton = ui.Button._new(self.x, self.y, self.width, self.height, self.parent)
        self.textButton.transparent = false

        self.textButton.onClick = function()
            ui.mode = self.mode

            self.selected = true
        end
    end,

    createLabel = function(self)
        self.label = ui.Label._new("", self.x, self.y, self.parent)

    end,

    allowChars = function(self, ...)
        args = ...
        if type(args[1]) == "string" then
            self.allowed = args
        elseif type(args[1]) == "table" then
            self.allowed = {}
            for k, tab in pairs(args) do
                table.insert(self.allowed, tab)
            end
        end
    end,

    forbidChars = function(self, ...)
        self.forbid = {}
        for k, char in pairs(...) do
            table.insert(self.forbid, char)
        end
    end,

    --Unselect textbox
    mousepressed = function(self, item)
        if item ~= self then
            self.selected = false
            if ui.mode == self.mode then
                ui.mode = nil
            end
        end
    end,

    --Text input
    textinput = function(self, key)
        local allowed = false
        if self.selected then
            --Check allowed
            for k, tab in pairs(self.allowed) do
                for k, char in pairs(tab) do
                    if char == key then allowed = true end
                end
            end
            --Check forbid
            for k, tab in pairs(self.forbid) do
                for k, char in pairs(tab) do
                    if char == key then return end
                end
            end
        end
        --Add Char
        if (string.len(self.text) <= self.limit) or self.limit == 0 then
            if allowed then
                self.text = self.text..key
            end
        end
    end,

    --Back space and space
    keypressed = function(self, key)
        --Backspace
        if key == "backspace" then
            if string.len(self.text) > 0 then
                self.text = self.deleteLastChar(self.text)
            end
        end
        --Add Space
        if (string.len(self.text) <= self.limit) or self.limit == 0 then
            --Space
            if key == "space" and self.spaces then
                self.text = self.text.." "
            end
        end
    end,

    update = function(self, dt)
        --Flash Cursor
        if self.selected then
            self.cursorTime = self.cursorTime + dt

            if self.cursorTime >= self.cursorRate then
                if self.cursor == "" then
                    self.cursor = "|"
                else
                    self.cursor = ""
                end

                self.cursorTime = 0
            end
        else
            self.cursor = ""
            self.cursorTime = 0
        end

        --Update text
        self.label.text = (self.text..self.cursor)
    end,

    --Draw Textbox
    draw = function(self)
        if not self.transparent then
            --Draw Border
            util.setCol(self.borderColor)
            love.graphics.rectangle("fill", self.x - self.border, self.y - self.border, self.width + self.border * 2, self.height + self.border*2)
            --Draw Typebox
            util.setCol(self.color)
            love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        end

        --Draw Text


    end,

    --##STATIC METHODS##--
    deleteLastChar = function(str)
        return(str:gsub("[%z\1-\127\194-\244][\128-\191]*$", ""))
    end,

    replaceChar = function(str, oldChar, newChar)
        local newStr = ""
        for i = 1, #str do
            local char = str:sub(i,i)
            if char ~= oldChar then
                newStr = newStr..char
            else
                newStr = newStr..newChar
            end
        end
        return newStr
    end


    }, ui.UiElement)

--#######--
return ui