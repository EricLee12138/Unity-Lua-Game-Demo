
local logChannel = _Engine.logChannel
local logErrorChannel = _Engine.logErrorChannel

local new = typesys.new
local delete = typesys.delete

local Map = typesys.map

local channel = "world"

---------

local WorldTypes = {
	[1] = Ground,
}

World = typesys.World {
	reg_objs = Map,   -- type_id --> obj_map(obj_id --> obj)
	creatures = Map,  -- _id --> creature
	asset_manager = AssetManager,
	weak_ground = Ground,
}

function World:ctor()
	logChannel(channel, "open")

	local reg_objs = new(Map, type(0), Map) 
	for type_id,obj_type in pairs(WorldTypes) do
		reg_objs:set(type_id, new(Map, type(0), obj_type))
	end
	self.reg_objs = reg_objs

	self.creatures = new(Map, type(0), Creature)
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

	if Ground == obj_type then
		logChannel(channel, "<color=green>{0} is ready</color>", obj_type._type_name)
		
		self.ground = obj

		local born_p = obj.position -- use ground.position 
		for i=1, 10 do
			local c = entity.new(Creature, self, born_p)
			entity.enableAllComponents(c)
			self.creatures:set(c._id, c)
		end
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
		logErrorChannel(channel, "<unregister> {0}:{1} is not exist!!", tostring(obj_type._type_name), obj_id)
	end
end

function World:update(time, delta_time)
	self.ground:update(self, time, delta_time)

	SystemAI.update(self, time, delta_time)
	SystemMove.update(self, time, delta_time)

	-- log check caches status
	-- entity.printCache()
	-- entity.printCacheLookup()
end




