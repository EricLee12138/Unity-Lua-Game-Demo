
local _DEBUG_ON = false

local print = _DEBUG_ON and print or function() end
local assert = assert

local NO_NAME = "[no name]"

-------------

local last_id = 0
local type_info = {} -- type -- > info
local alive_objects = {} -- id --> obj

local weak_pool_mt = {__mode = "kv"}
local type_mt = {}
local obj_mt = {}

------- external type --------->
local external_objects = {} -- obj --> type
local external_owners = {} -- obj --> owner

local function newExternal(t, info, ...)

	-- increase id
	local id = last_id + 1
	last_id = id

	local obj
	local pool = info.pool
	local n = #pool
	if n > 0 then
		-- pool pop
		obj = pool[n]
		pool[n] = nil

		info.setID(t, obj, id)
		info.onReuse(t, obj, ...)
		print("reuse external type:", t._type_name or NO_NAME)
	else
		-- create new
		obj = info.new(t, id, ...)
		print("new external type:", t._type_name or NO_NAME)
	end

	-- register object
	alive_objects[id] = obj
	external_objects[obj] = t

	return obj
end

local function deleteExternal(obj, t, info)
	assert(nil ~= external_objects[obj])

	-- unregister object
	alive_objects[info.getID(t, obj)] = nil
	external_objects[obj] = nil

	local pool = info.pool
	local pool_size = #pool
	local pool_capacity = info.pool_capacity
	if 0 > pool_capacity or 0 ~= pool_capacity and pool_size < pool_capacity then
		-- pool push
		print("recycle external type:", t._type_name or NO_NAME, info.getID(t, obj))
		info.onRecycle(t, obj)
		pool[pool_size+1] = obj
	else
		print("delete external type:", t._type_name or NO_NAME, info.getID(t, obj))
		info.delete(t, obj)
	end

	info.setID(t, obj, 0)
end

------- external type ---------<

local function objSetOwner(obj, t)
	local info = type_info[t]
	if info.external_type then
		external_owners[obj] = true
	else
		obj._owner = true
	end
end

local function objBreakOwner(obj, t)
	local info = type_info[t]
	if info.external_type then
		external_owners[obj] = nil
	else
		obj._owner = false
	end
end

local function objHasOwner(obj)
	return obj._owner or nil ~= external_owners[obj]
end

local function objTryAssignStrongRef(obj, k, v, info)
	local rt = info.ref[k]
	if nil == rt then
		return false
	end

	if nil ~= v then
		assert(not objHasOwner(v))
		local rt_info = type_info[rt]
		if rt_info.external_type then
			if external_objects[v] ~= rt then
				error(error(string.format("type(%s)'s filed %s require external type: %s, but received: %s", 
					t._type_name, k, rt._type_name or NO_NAME, external_objects[v]._type_name or NO_NAME)))
				return false
			end
			external_owners[v] = obj
		else
			if v._type_name ~= rt._type_name then
				error(string.format("type(%s)'s filed %s require type: %s, but received: %s", 
					t._type_name, k, rt._type_name, v._type_name))
				return false
			end
			v._owner = obj
		end
	else
		v = false
	end

	local old = obj._refs[k]
	obj._refs[k] = v

	-- delete old
	if old then
		-- break hold
		objBreakOwner(old, rt)
		-- delete old
		typesys.delete(old)
	end
	return true
end

local function objTryAssignWeakRef(obj, k, v, info)
	local rt = info.w_ref[k]
	if nil == rt then
		return false
	end

	if nil ~= v then
		local rt_info = type_info[rt]
		if rt_info.external_type then
			if external_objects[v] ~= rt then
				error(error(string.format("type(%s)'s filed %s require external type: %s, but received: %s", 
					t._type_name, k, rt._type_name or NO_NAME, external_objects[v]._type_name or NO_NAME)))
				return false
			end
			obj._refs[k] = rt_info.getID(rt, v)
		else
			if v._type_name ~= rt._type_name then
				error(string.format("type(%s)'s filed %s require type: %s, but received: %s", 
					t._type_name, k, rt._type_name, v._type_name))
				return false
			end
			obj._refs[k] = v._id
		end
	else
		obj._refs[k] = false
	end
	return true
end

local function objFieldAssign(obj, k, v)
	local t = typesys[obj._type_name]
	assert(nil ~= t)
	local info = type_info[t]
	assert(nil ~= info)

	if objTryAssignStrongRef(obj, k, v, info) then
		return
	end
	if objTryAssignWeakRef(obj, k, v, info) then
		return
	end

	error(string.format("type(%s) field assign failed: %s", t._type_name, tostring(k)))
end

local function objFieldGet(obj, k)
	local t = typesys[obj._type_name]
	assert(nil ~= t)

	local tv = t[k]
	if nil ~= tv then
		return tv
	end

	local info = type_info[t]
	assert(nil ~= info)

	local ref = info.ref[k]
	if nil ~= ref then
		return obj._refs[k] or nil
	end
	ref = info.w_ref[k]
	if nil ~= ref then
		local ref_id = obj._refs[k]
		if ref_id then
			return alive_objects[ref_id]
		end
		return nil
	end

	return nil
end

obj_mt.__index = objFieldGet
obj_mt.__newindex = objFieldAssign

type_mt.__call = function(t, proto)
	if nil ~= type_info[t] then
		error(string.format("redifined type: %s", t._type_name))
	end

	print("\n------define type:", t._type_name, "begin--------")

	local info = {
		pool_capacity = -1,
		strong_pool = false,
		num = {},
		str = {},
		bool = {},
		ref = {},
		w_ref = {},
		unmanaged = {},
		pool = {}
	}

	for k,v in pairs(proto) do
		assert(type(k) == "string")
		if "_pool_capacity" == k then
			assert("number" == type(v))
			info.pool_capacity = v
		elseif "_strong_pool" == k then
			assert("boolean" == type(v))
			info.strong_pool = v
		elseif typesys.unmanaged == v then
			print("unmanaged field:", k)
			info.unmanaged[k] = false
		else
			local vt = type(v)
			if "number" == vt then
				info.num[k] = v
				print("number:", k, "=", v)
			elseif "string" == vt then
				info.str[k] = v
				print("string:", k, "=", v)
			elseif "boolean" == vt  then
				info.bool[k] = v
				print("boolean:", k, "=", v)
			elseif vt == "table" and (nil ~= type_info[v] or getmetatable(v) == type_mt) then
				local field_name = k:match("^weak_(.+)")
				if field_name then
					k = field_name
					assert(nil == info.ref[k])
					info.w_ref[k] = v
					print("weak reference:", k, "=", v._type_name)
				else
					assert(nil == info.w_ref[k])
					info.ref[k] = v
					print("strong reference:", k, "=", v._type_name)
				end
			else
				error(string.format("Invalid field %s with type %s", k, vt))
			end
		end
	end

	if not info.strong_pool then
		setmetatable(info.pool, weak_pool_mt)
	end

	type_info[t] = info

	print("------define type:", t._type_name, "end--------\n")
	return t
end

typesys = setmetatable({},{
	__index = function(t, name)
		local new_t = setmetatable({
			_type_name = name
		}, type_mt)
		t[name] = new_t
		return new_t
	end
})

typesys.unmanaged = {}

-- proto = {
-- 	pool_capacity = -1, -- -1 is infinit
-- 	strong_pool = false,
-- 	new = function(t, id, ...) end -- ... is construct arguments, return a new object
-- 	delete = function(t, obj) end
-- 	onReuse = function(t, obj, ...) end -- ... is construct arguments
-- 	onRecycle = function(t, obj) end
-- 	setID = function(t, obj, id) end
-- 	getID = function(t, obj) end
-- }
--
-- external type object CAN NOT hold typesys type object!!!!
-- but typesys type object can hold external type as strong or weak
local function regExternal(t, proto)
	if nil ~= type_info[t] then
		error("reregister external type: ", t._type_name or NO_NAME)
	end
	assert(nil ~= proto.new and type(proto.new) == "function")
	assert(nil ~= proto.delete and type(proto.delete) == "function")
	assert(nil ~= proto.onReuse and type(proto.onReuse) == "function")
	assert(nil ~= proto.onRecycle and type(proto.onRecycle) == "function")
	assert(nil ~= proto.setID and type(proto.setID) == "function")
	assert(nil ~= proto.getID and type(proto.getID) == "function")

	print("\n------register external type:", t._type_name or NO_NAME, "egin--------")

	local info = {
		pool_capacity = proto.pool_capacity or -1,
		strong_pool = proto.strong_pool or false,
		pool = {},
		external_type = true,

		new = proto.new,
		delete = proto.delete,
		onReuse = proto.onReuse,
		onRecycle = proto.onRecycle,
		setID = proto.setID,
		getID = proto.getID
	}

	if not info.strong_pool then
		setmetatable(info.pool, weak_pool_mt)
	end

	type_info[t] = info

	print("------register external type:", t._type_name or NO_NAME, "end--------\n")
end

local function getObjectByID(id)  
	return alive_objects[id]
end

local function getType(obj)
	local t = external_objects[obj]
	if nil ~= t then
		return t
	end
	return typesys[obj._type_name]
end

local function getTypeName(objOrType)
	local t = external_objects[obj]
	if nil ~= t then
		return t._type_name or NO_NAME
	end
	return objOrType._type_name
end

local function checkType(t)
	return nil ~= type_info[t]
end

local function setOwner(obj)
	objSetOwner(obj, getType(obj))
end

local function clearOwner(obj)
	objBreakOwner(obj, getType(obj))
end

local function hasOwner(obj)
	return objHasOwner(obj)
end

local function new(t, ...)
	local info = type_info[t]
	assert(nil ~= info)

	if info.external_type then
		return newExternal(t, info, ...)
	end

	local obj
	local pool = info.pool
	local n = #pool
	if n > 0 then
		-- pool pop
		obj = pool[n]
		pool[n] = nil
		print("reuse", t._type_name)
	else
		-- create new
		local refs = nil
		if nil ~= next(info.ref) or nil ~= next(info.w_ref) then
			refs = {}
			for k in pairs(info.ref) do
				refs[k] = false
			end
			for k in pairs(info.w_ref) do
				refs[k] = false
			end
		end
		obj = {_type_name = t._type_name, _refs = refs, _owner = false}
		for k,v in pairs(info.unmanaged) do
			obj[k] = v
		end
		print("new", t._type_name)
	end

	-- increase id
	local id = last_id + 1
	last_id = id

	obj._id = id
	-- set default values
	for k,v in pairs(info.num) do
		obj[k] = v
	end
	for k,v in pairs(info.str) do
		obj[k] = v
	end
	for k,v in pairs(info.bool) do
		obj[k] = v
	end

	setmetatable(obj, obj_mt)

	-- register object
	alive_objects[id] = obj

	-- construct
	if nil ~= obj.ctor then
		obj:ctor(...)
	end
	return obj
end

local function delete(obj)
	assert(not objHasOwner(obj))

	local t = external_objects[obj]
	if nil ~= t then
		return deleteExternal(obj, t, type_info[t])
	end

	assert(nil ~= alive_objects[obj._id], tostring(obj._type_name)..":"..tostring(obj._id)) -- circular reference will fail
	t = typesys[obj._type_name]
	assert(nil ~= t)
	local info = type_info[t]
	assert(nil ~= info)

	-- unregister object
	alive_objects[obj._id] = nil

	-- deconstruct
	if nil ~= obj.dtor then
		obj:dtor()
	end

	
	local refs = obj._refs
	if nil ~= refs then
		-- delete strong references
		local ref
		for k, v in pairs(info.ref) do
			ref = refs[k]
			refs[k] = false
			if ref then
				-- break hold
				objBreakOwner(ref, v)
				typesys.delete(ref)
			end
		end

		-- clear weak references
		for k in pairs(info.w_ref) do
			refs[k] = false
		end
	end

	local pool = info.pool
	local pool_size = #pool
	local pool_capacity = info.pool_capacity
	if 0 > pool_capacity or 0 ~= pool_capacity and pool_size < pool_capacity then
		-- pool push
		print("recycle", t._type_name, obj._id)
		pool[pool_size+1] = obj
	else
		print("delete", t._type_name, obj._id)
	end
	obj._id = 0

	setmetatable(obj, nil)
end

local temp_pool = {}
local function deleteNoOwnerObjects()
	local temp = nil
	local temp_n = #temp_pool
	if 0 < temp_n then
		temp = temp_pool[temp_n]
		temp_pool[temp_n] = nil
	else
		temp = {}
	end
	local i = 1
	for id,obj in pairs(alive_objects) do
		if not objHasOwner(obj) then
			temp[i] = obj
			i = i+1
		end
	end
	for i=#temp, 1, -1 do
		delete(temp[i])
		temp[i] = nil
	end
	temp_pool[#temp_pool+1] = temp
end

obj_mt.__gc = function(obj)
	delete(obj)
end

typesys.regExternal = regExternal
typesys.getObjectByID = getObjectByID
typesys.getType = getType
typesys.getTypeName = getTypeName
typesys.checkType = checkType
typesys.setOwner = setOwner
typesys.clearOwner = clearOwner
typesys.hasOwner = hasOwner
typesys.new = new
typesys.delete = delete
typesys.deleteNoOwnerObjects = deleteNoOwnerObjects

typesys.DEBUG_ON = _DEBUG_ON

