
local logChannel = _Engine.logChannel
local channel = "game_object"

local new = typesys.new

---------

GameObjectHandler = typesys.GameObjectHandler {
}

local transRegister = ObjectProxy.transRegister
local transUnregister = ObjectProxy.transUnregister
local transSetPosition = ObjectProxy.transSetPosition
local transSetRotation = ObjectProxy.transSetRotation
local transSetScale = ObjectProxy.transSetScale
local getBoxCollider = ObjectProxy.getBoxCollider
local animSetBool = ObjectProxy.animSetBool
local animSetFloat = ObjectProxy.animSetFloat

function GameObjectHandler:ctor(go, name)
	local id = self._id
	logChannel(channel, "[GameObjectHandler|{0}]ctor", id, name)

	go.name = name or "[NoName]"
	transRegister(id, go.transform, true) -- true will set "Don't Destroy this GameObject"
end

function GameObjectHandler:dtor()
	local id = self._id
	logChannel(channel, "[GameObjectHandler|{0}]dtor", id)

	transUnregister(id, true)
end

function GameObjectHandler:setPosition(p)
	transSetPosition(self._id, p)
end

function GameObjectHandler:setRotation(r)
	transSetRotation(self._id, r)
end

function GameObjectHandler:setScale(s)
	transSetScale(self._id, s)
end

function GameObjectHandler:getBoxCollider()
	return getBoxCollider(self._id)
end

function GameObjectHandler:animSetBool(name, value)
	animSetBool(self._id, name, value)
end

function GameObjectHandler:animSetFloat(name, value)
	animSetFloat(self._id, name, value)
end