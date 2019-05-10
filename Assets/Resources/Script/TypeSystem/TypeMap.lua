
local print = typesys.DEBUG_ON and print or function() end
local assert = assert

-------------

local setOwner = typesys.setOwner
local clearOwner = typesys.clearOwner
local hasOwner = typesys.hasOwner
local delete = typesys.delete

local function inElement(e, is_sys_t, weak)
	if nil == e then
		return nil
	elseif is_sys_t and weak then
		return e._id
	end
	return e
end

local function outElement(e, is_sys_t, weak)
	if is_sys_t and weak then
		return typesys.getObjectByID(e)
	end
	return e
end

local map = typesys.map {
	_weak = false,
	_kt = typesys.unmanaged,
	_vt = typesys.unmanaged,
	_is_sys_t = typesys.unmanaged,
	_m = typesys.unmanaged
}

function map:ctor(kt, vt, weak)
	assert("string" == type(kt))
	local is_sys_t = typesys.checkType(vt)
	assert(is_sys_t or "string" == type(vt))

	self._weak = weak or false
	self._kt = kt
	self._vt = vt
	self._is_sys_t = is_sys_t
	self._m = self._m or {}
end

function map:dtor()
	local m = self._m
	if not self._weak and self._is_sys_t then
		for k, v in pairs(m) do
			m[k] = nil
			clearOwner(v)
			delete(v)
		end
	else
		for k, v in pairs(m) do
			m[k] = nil
		end
	end
end

function map:checkKey(k)
	if nil == k then
		return false
	end
	return type(k) == self._kt
end

function map:checkValue(v)
	if nil == v then
		return true
	end
	if self._is_sys_t then
		if typesys.getType(v) == self._vt then
			return self._weak or not hasOwner(v)
		else
			return false
		end
	else
		return type(v) == self._vt
	end
end

function map:containKey(k)
	return nil ~= self._m[k]
end

function map:set(k, v)
	assert(self:checkKey(k))
	assert(self:checkValue(v))
	v = inElement(v, self._is_sys_t, self._weak)

	if self._weak or not self._is_sys_t then
		self._m[k] = v
	else
		-- must be strong sys type ref
		local m = self._m
		local old = m[k]
		m[k] = v
		if nil ~= v then
			setOwner(v)
		end
		if nil ~= old then
			clearOwner(old)
			delete(old)
		end
	end
end

function map:get(k)
	local v = self._m[k]
	if nil == v then
		return nil
	end
	return outElement(v, self._is_sys_t, self._weak)
end

function map:clear()
	local m = self._m
	if self._weak or not self._is_sys_t then
		for k in pairs(m) do
			m[k] = nil
		end
	else
		-- must be strong sys type ref
		for k, old in pairs(m) do
			m[k] = nil
			if nil ~= old then
				clearOwner(old)
				delete(old)
			end
		end
	end
end

function map:_next(k)
	local k, v = next(self._m, k)
	if nil ~= v then
		v = outElement(v, self._is_sys_t, self._weak)
	end
	return k, v
end

function map:pairs()
	return map._next, self
end

if not typesys.DEBUG_ON then
	map.checkKey = function() return true end
	map.checkValue = function() return true end
end




