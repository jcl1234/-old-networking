--Function that creates instance(ie: class._new)
local instanceFunc = "_new"
--

local util = {}
--Get length of table
function util.tableLen(table)
	local len = 0
	for k,v in pairs(table) do
		len = len + 1
	end
	return len
end

--Index value from instance
local function indexObj(obj, key)
	local class = rawget(obj, "_class_")
	--If not an instance then set to class
	if not class then class = obj end

	local prototype = rawget(class, "_prototype_")

	--Try Class Vars
	if rawget(obj, key) then return rawget(obj, key) end
	--Try Prototype
	if rawget(prototype, key) then return prototype[key] end
	--Try Super Class
	local superClass = rawget(class, "_inherit_")
	if superClass then
		if superClass[key] then return superClass[key] end
	end
	--
	return rawget(obj, key)
end

--Create Class
function class(prototype, inherit)
	local prototype, inherit = prototype, inherit
	--Create New Class
	local cls = {}
	cls._prototype_ = prototype
	cls._type_ = "class"
	cls._inherit_ = inherit
	local meta = {__index = indexObj}
	cls._meta_ = meta
	setmetatable(cls, meta)
	----Create Instance Function
	cls[instanceFunc] = function(...)
		local object = setmetatable({}, cls._meta_)
		object._class_ = cls
		--Super Function
		object.super = function()
			return cls._inherit_
		end
		--Run Init Function On Creation
		if rawget(rawget(cls, "_prototype_"), "_init") then
			object:_init(...)
		end
		return object
	end

	return cls
end
-----------

--Example--

-- local superClass = class({
-- 	printVal = function(self)
-- 		print(self.val)
-- 	end
-- 	})

-- local sub = class({
-- 	_init = function(self, val)
-- 		self.val = val
-- 	end,
-- 	}, superClass)

-- local sub1 = sub._create(10)
-- sub1:printVal()