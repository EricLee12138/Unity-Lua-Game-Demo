
local _DEBUG_ON = typesys.DEBUG_ON

local print = _DEBUG_ON and print or function() end
local assert = assert

local table_pool = {}
local function newTable()
	local n = #table_pool
	if 0 < n then
		local t = table_pool[n]
		table_pool[n] = nil
		return t
	end
	return {}
end
local function deleteTable(t)
	for k in pairs(t) do
		t[k] = nil
	end
	table_pool[#table_pool+1] = t
end

-------------

local proto_info = {} -- type --> proto
local type_mt = {}

local entity_components = {} -- entity_id --> info
local entities_cache = {} -- components group --> entitie_ids
local cache_lookup = {} -- entity_type --> [component --> components group list]

local matching_system = nil
local delay_entities_id = {}

entity = {}

type_mt.__call = function(t, proto)
	-- transform t
	t = typesys[t._type_name]
	entity[t._type_name] = t

	if nil ~= proto_info[t] then
		error(string.format("redifined entity: %s", t._type_name))
	end
	local cs = proto._components
	assert(nil ~= cs)

	print("\n------define entity:", t._type_name, "begin--------")

	local e_proto = {_pool_capacity = proto._pool_capacity, _strong_pool = proto._strong_pool}
	for i=1, #cs do
		c = cs[i]
		assert(component.checkType(c))
		print("component:", component.getTypeName(c))

		component.fillEntityField(c, e_proto)
	end

	proto_info[t] = proto

	-- register type
	t(e_proto)

	print("------define entity:", t._type_name, "end--------\n")
	return t
end

setmetatable(entity,{
	__index = function(t, name)
		local new_t = setmetatable({
			_type_name = name
		}, type_mt)
		t[name] = new_t
		return new_t
	end
})

local getObjectByID = typesys.getObjectByID
local getType = typesys.getType
local getTypeName = typesys.getTypeName
local checkType = typesys.checkType
local new = typesys.new
local delete = typesys.delete

entity.getObjectByID = getObjectByID
entity.getType = getType
entity.getTypeName = getTypeName
entity.checkType = checkType
entity.new = new
entity.delete = delete

local function buildComponentsInfo(e, init)
	init = init or false

	local id = e._id
	local info = entity_components[id]
	if nil == info then
		info = {}
		entity_components[id] = info
	end
	local proto = proto_info[entity[e._type_name]]
	local cs = proto._components
	for i=1, #cs do
		c = cs[i]
		info[c] = init
	end
	return info
end

local function checkComponents(info, cs)
	for i=1, #cs do
		if not info[cs[i]] then
			return false
		end
	end
	return true
end

local function makesureCacheIncludeEntity(es, e)

	local id = e._id
	for i=1, #es do
		if es[i] == id then
			return
		end
	end
	es[#es+1] = id
end

local function makesureCacheExcludeEntity(es, e)
	local id = e._id
	for i=1, #es do
		if es[i] == id then
			table.remove(es, i)
			return
		end
	end
end

local function doMakesureCacheProc(cs_list, e, proc)
	local es = nil
	local cs = nil
	for i=1, #cs_list do
		cs = cs_list[i]
		es = entities_cache[cs]
		proc(es, e)
	end
end

local function refreshCache(e, c, enabled)
	if nil ~= matching_system then
		local info = delay_entities_id[e._id]
		if nil == info then
			info = newTable() 
			delay_entities_id[e._id] = info
		end
		if nil == c then
			info.all = enabled
		elseif nil == info.all then
			info[c] = enabled
		end
		return
	end

	local e_type = getType(e)
	local cs_map = cache_lookup[e_type]
	if nil == cs_map then
		-- no cache
		return
	end

	if nil == c then
		-- all components
		if enabled then
			-- makesure es include e
			for _,cs_list in pairs(cs_map) do
				doMakesureCacheProc(cs_list, e, makesureCacheIncludeEntity)
			end
		else
			-- makesure es exclude e
			for _,cs_list in pairs(cs_map) do
				doMakesureCacheProc(cs_list, e, makesureCacheExcludeEntity)
			end
		end
	else
		local cs_list = cs_map[c]
		if nil == cs_list then
			-- no cache
			return
		end

		if enabled then
			doMakesureCacheProc(cs_list, e, makesureCacheIncludeEntity)
		else
			doMakesureCacheProc(cs_list, e, makesureCacheExcludeEntity)
		end
	end
end

local function buildCacheLookup(e, cs)
	local e_type = getType(e)
	local cs_map = cache_lookup[e_type]
	if nil == cs_map then
		cs_map = {}
		cache_lookup[e_type] = cs_map
	end

	local c = nil
	local cs_list = nil
	local added = nil
	for i=1, #cs do
		c = cs[i]
		cs_list = cs_map[c]
		if nil == cs_list then
			cs_list = {}
			cs_map[c] = cs_list
		end
		added = false
		for j=1, #cs_list do
			if cs_list[j] == cs then
				added = true
				break
			end
		end
		if not added then
			cs_list[#cs_list+1] = cs
		end
	end
end

function entity.isComponentEnabled(e, c)
	local info = entity_components[e._id]
	if nil == info then
		return false -- no component enabled
	end
	return info[c]
end

function entity.enableComponent(e, c)
	local info = entity_components[e.id]
	if nil == info then
		info = buildComponentsInfo(e)
	end
	info[c] = true
	refreshCache(e, c, true)
end

function entity.disableComponent(e, c)
	local info = entity_components[e._id]
	if nil == info then
		return
	end
	info[c] = false
	refreshCache(e, c, false)
end

function entity.enableAllComponents(e)
	buildComponentsInfo(e, true)
	refreshCache(e, nil, true)
end

function entity.disableAllComponents(e)
	buildComponentsInfo(e, false)
	refreshCache(e, nil, false)
end

function entity.foreachEntities(s, proc, ...)
	assert(nil == matching_system)
	matching_system = s

	local cs = system.getComponents(s)
	local es = entities_cache[cs] 
	if nil == es then
		es = {}
		local i = 1
		for id,info in pairs(entity_components) do
			local e = getObjectByID(id)
			if nil ~= e and checkComponents(info, cs) then
				es[i] = id
				i = i+1
				buildCacheLookup(e, cs)
			end
		end
		entities_cache[cs] = es
	end

	for i=#es, 1, -1 do
		local id = es[i]
		local e = getObjectByID(id)
		if nil == e then
			es[i] = nil
		else
			proc(e, ...)
		end
	end

	matching_system = nil

	-- handle delay refresh
	local e = nil
	for id, info in pairs(delay_entities_id) do
		delay_entities_id[id] = nil
		e = getObjectByID(id)
		if e then
			if nil ~= info.all then
				refreshCache(e, nil, info.all)
			else
				for c, enabled in pairs(info) do
					refreshCache(e, c, enabled)
				end
			end
		end
		deleteTable(info)
	end
end

function entity.printCache()
	local print = _G.print
	for cs, es in pairs(entities_cache) do
		local s_type = system.getTypeByComponentGroup(cs)
		print(string.format("\n--------- %s caches ----------", s_type._type_name))
		for i=1, #es do
			local id = es[i]
			local e = getObjectByID(id)
			if nil ~= e then
				print(e._type_name, id)
			end
		end
		print(string.format("------------------------------\n"))
	end
end

function entity.printCacheLookup()
	local print = _G.print
	for e_type, cs_map in pairs(cache_lookup) do
		print(string.format("\n--------- %s lookup ----------", e_type._type_name))
		for c, cs_list in pairs(cs_map) do
			print(string.format("--- %s map ---", c._type_name))
			for i=1, #cs_list do
				local cs = cs_list[i]
				local s_type = system.getTypeByComponentGroup(cs)
				print(s_type._type_name)
			end
			print(string.format("--------------"))
		end
		print(string.format("------------------------------\n"))
	end
end





