
local _DEBUG_ON = typesys.DEBUG_ON

local print = _DEBUG_ON and print or function() end
local assert = assert

local NO_NAME = "[no name]"

-------------

local proto_info = {}
local type_mt = {}

type_mt.__call = function(t, proto)
	if nil ~= proto_info[t] then
		error(string.format("redifined component: %s", t._type_name))
	end

	print("\n------define component:", string.format("%s(%s)", t._type_name, proto._name or NO_NAME), "begin--------")

	for k,v in pairs(proto) do
		assert(type(k) == "string")
		if "_name" == k then
			assert("string" == type(v))
		else
			local vt = type(v)
			if "number" == vt then
				print("number:", k, "=", v)
			elseif "string" == vt then
				print("string:", k, "=", v)
			elseif "boolean" == vt  then
				print("boolean:", k, "=", v)
			elseif vt == "table" and typesys.checkType(v) then
				print(string.format("%s:", typesys.getTypeName(v)), k)
			else
				error(string.format("Invalid field %s with type %s", k, vt))
			end
		end
	end

	proto_info[t] = proto

	print("------define component:", string.format("%s[%s]", t._type_name, proto._name or NO_NAME), "end--------\n")
	return t
end

component = setmetatable({},{
	__index = function(t, name)
		local new_t = setmetatable({
			_type_name = name
		}, type_mt)
		t[name] = new_t
		return new_t
	end
})

function component.fillEntityField(t, e)
	local info = proto_info[t]
	for k,v in pairs(info) do
		if "_name" ~= k then
			k = string.format("%s_%s", t._type_name, k)
			e[k] = v
			if _DEBUG_ON then
				if "table" == type(v) then
					print(string.format("%s:", v._type_name or NO_NAME), k)
				else
					print(string.format("%s:", type(v)), k, "=", v)
				end
			end
		end
	end
end

function component.checkType(t)
	return nil ~= proto_info[t]
end

function component.getTypeName(t)
	local info = proto_info[t]
	return info._name or NO_NAME
end



