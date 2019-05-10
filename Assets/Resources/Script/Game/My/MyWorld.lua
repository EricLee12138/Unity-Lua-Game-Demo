
local logChannel = _Engine.logChannel
local logErrorChannel = _Engine.logErrorChannel
local logWarningChannel = _Engine.logWarningChannel

local new = typesys.new
local delete = typesys.delete

local Map = typesys.map

local channel = "world"

---------

local WorldTypes = {
	[1] = Ground,
	[3] = Enemy,
	[4] = Player,
	[5] = Coin,
	[6] = Camera,
}

local WorldTypesWeak = {
	[Enemy] = true,
	[Coin] = true,
}

World = typesys.World {
	reg_objs = Map,   -- type_id --> obj_map(obj_id --> obj)
	creatures = Map,  -- _id --> creature
	enemies = Map,
	coins = Map,
	asset_manager = AssetManager,
	weak_ground = Ground,
	weak_player = Player,
	weak_camera = Camera,
}

function World:ctor()
	logChannel(channel, "open")

	local reg_objs = new(Map, type(0), Map) 
	for type_id,obj_type in pairs(WorldTypes) do
		reg_objs:set(type_id, new(Map, type(0), obj_type, WorldTypesWeak[obj_type]))
	end
	self.reg_objs = reg_objs

	self.enemies = new(Map, type(0), Enemy)
	self.coins = new(Map, type(0), Coin)
	self.asset_manager = new(AssetManager)
end

function World:dtor()
	logChannel(channel, "close")
end

function World:register(v)
	local type_id = v.type
	local obj_type = WorldTypes[type_id]
	local obj_id = v.id

	local reg_objs = self.reg_objs
	local obj_map = reg_objs:get(type_id)
	local obj = obj_map:get(obj_id)

	if obj then
		logErrorChannel(channel, "<register> {0}:{1} is already exist!!", obj_type._type_name, obj_id)
	else
		obj = new(obj_type, v)
		obj_map:set(obj_id, obj)
		logChannel(channel, "<register> {0}:{1}", obj_type._type_name, obj_id)
	end

	if Enemy == obj_type then
		logChannel(channel, "<color=red> {0}:{1} is ready</color>", obj_type._type_name, obj_id)
		entity.enableAllComponents(obj)
		self.enemies:set(obj_id, obj)
	end

	if Player == obj_type then
		logChannel(channel, "<color=green> {0} is ready</color>", obj_type._type_name)
		entity.enableAllComponents(obj)
		self.player = obj
	end

	if Coin == obj_type then
		logChannel(channel, "<color=yellow> {0} is ready</color>", obj_type._type_name)
		entity.enableAllComponents(obj)
		self.coins:set(obj_id, obj)
	end

	if Camera == obj_type then
		logChannel(channel, "<color=blue> {0} is ready</color>", obj_type._type_name)
		self.camera = obj
	end
end

function World:unregister(v)
	local type_id = v.type
	local obj_type = WorldTypes[v.type]
	local obj_id = v.id

	local reg_objs = self.reg_objs
	local obj_map = reg_objs:get(type_id)
	local obj = obj_map:get(obj_id)

	if obj then
		obj_map:set(obj_id, nil)
		logChannel(channel, "<unregister> {0}:{1}", tostring(obj_type._type_name), obj_id)
	else
		if not WorldTypesWeak[obj_type] then
			logWarningChannel(channel, "<unregister> {0}:{1} is not exist!!", tostring(obj_type._type_name), obj_id)
		end
	end
end

function World:getType(e)
	return WorldTypes[e.type]
end

function World:getEnemyByID(id)
	return self.enemies:get(id)
end

function World:destroyEnemyByID(id)
	self.enemies:set(id, nil)
end

function World:destroyCoin(coin)
	self.coins:set(coin.id, nil)
end

function World:update(time, delta_time)

	self.camera:update(self, time, delta_time)

	SystemEnemyAI.update(self, time, delta_time)
	SystemCollect.update(self, time, delta_time)
	SystemDamage.update(self, time, delta_time)
	SystemMove.update(self, time, delta_time)
	SystemAnimation.update(self, time, delta_time)
	SystemDeath.update(self, time, delta_time)
	SystemControl.update(self, time, delta_time)

	-- log check caches status
	-- entity.printCache()
	-- entity.printCacheLookup()
end

function World:lateupdate(time, delta_time)
	self.camera:lateupdate(self, time, delta_time)
end




