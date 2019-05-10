
local _DEBUG_ON = typesys.DEBUG_ON

local print = _DEBUG_ON and print or function() end
local assert = assert

-------------

local proto_info = {}
local type_mt = {}

type_mt.__call = function(t, proto)
	if nil ~= proto_info[t] then
		error(string.format("redifined system: %s", t._type_name))
	end

	local cs = proto._components
	assert(nil ~= cs)

	print("\n------define system:", t._type_name, "begin--------")

	for i=1, #cs do
		c = cs[i]
		assert(component.checkType(c))
		print("component:", component.getTypeName(c))

		-- TODO
	end

	proto_info[t] = proto

	print("------define system:", t._type_name, "end--------\n")
	return t
end

system = setmetatable({},{
	__index = function(t, name)
		local new_t = setmetatable({
			_type_name = name
		}, type_mt)
		t[name] = new_t
		return new_t
	end
})

function system.getComponents(s)
	return proto_info[s]._components
end

function system.getTypeByComponentGroup(cs)
	for t, proto in pairs(proto_info) do
		if proto._components == cs then
			return t
		end
	end
	return nil
end


