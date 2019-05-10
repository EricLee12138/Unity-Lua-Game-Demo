

local print = typesys.DEBUG_ON and print or function() end
local assert = assert

-------------

local setOwner = typesys.setOwner
local clearOwner = typesys.clearOwner
local hasOwner = typesys.hasOwner
local delete = typesys.delete

local nil_slot = {}

local function inElement(e, is_sys_t, weak)
	if nil == e then
		return nil_slot
	elseif is_sys_t and weak then
		return e._id
	end
	return e
end

local function outElement(e, is_sys_t, weak)
	if nil_slot == e then
		return nil
	elseif is_sys_t and weak then
		return typesys.getObjectByID(e)
	end
	return e
end

local array = typesys.array {
	_weak = false,
	_t = typesys.unmanaged,
	_is_sys_t = typesys.unmanaged,
	_a = typesys.unmanaged
}

function array:ctor(t, weak)
	local is_sys_t = typesys.checkType(t)
	assert(is_sys_t or "string" == t)

	self._weak = weak or false
	self._t = t
	self._is_sys_t = is_sys_t
	self._a = self._a or {}
end

function array:dtor()
	local a = self._a

	if not self._weak and self._is_sys_t then
		-- must be strong sys type ref
		for i=#a, 1, -1 do
			local e = a[i]
			a[i] = nil
			if nil_slot ~= e then
				clearOwner(e)
				delete(e)
			end
		end
	else
		for i=#a, 1, -1 do
			a[i] = nil
		end
	end
end

function array:checkElement(e)
	if nil == e then
		return true
	end
	if self._is_sys_t then
		if typesys.getType(e) == self._t then
			return self._weak or not hasOwner(e)
		else
			return false
		end
	else
		return type(e) == self._t
	end
end

function array:size()
	return #self._a
end

function array:set(i, v)
	assert(self:checkElement(v))
	local a = self._a
	assert(0 < i and #a >= i)

	v = inElement(v, self._is_sys_t, self._weak)

	if self._weak or not self._is_sys_t then
		a[i] = v
	else
		-- must be strong sys type ref
		local old = a[i]
		a[i] = v
		if nil ~= v then
			setOwner(v)
		end
		if nil_slot ~= old then
			clearOwner(old)
			delete(old)
		end
	end
end

function array:get(i)
	assert(0 < i)
	return outElement(self._a[i], self._is_sys_t, self._weak)
end

function array:pushBack(v)
	assert(self:checkElement(v))

	local a = self._a
	v = inElement(v, self._is_sys_t, self._weak)
	a[#a+1] = v
	if nil_slot ~= v and self._is_sys_t and not self._weak then
		setOwner(v)
	end
end

function array:popBack()
	local a = self._a
	local n = #a
	if 0 < n then
		local v = a[n]
		a[n] = nil
		if nil_slot ~= v and self._is_sys_t and not self._weak then
			clearOwner(v)
		end
		return outElement(v, self._is_sys_t, self._weak)
	else
		return nil
	end
end

function array:peekBack()
	local a = self._a
	local n = #a
	if 0 < n then
		return outElement(a[n], self._is_sys_t, self._weak)
	else
		return nil
	end
end

function array:pushFront(v)
	if nil == v and 0 == #self._a then
		return
	end
	assert(self:checkElement(v))
	
	v = inElement(v, self._is_sys_t, self._weak)
	table.insert(self._a, 1, v)
	if nil_slot ~= v and self._is_sys_t and not self._weak then
		setOwner(v)
	end
end

function array:popFront()
	local a = self._a
	if 0 < #a then
		local v = a[1]
		table.remove(a, 1)
		if nil_slot ~= v and self._is_sys_t and not self._weak then
			clearOwner(v)
		end
		return outElement(v, self._is_sys_t, self._weak)
	else
		return nil
	end
end

function array:peekFront()
	local a = self._a
	if 0 < #a then
		return outElement(a[1], self._is_sys_t, self._weak)
	else
		return nil
	end
end

function array:clear()
	local a = self._a
	if self._weak or not self._is_sys_t then
		for i=#a, 1, -1 do
			a[i] = nil
		end
	else
		-- must be strong sys type ref
		for i=#a, 1, -1 do
			local e = a[i]
			a[i] = nil
			if nil_slot ~= e then
				clearOwner(e)
				delete(e)
			end
		end
	end
end

if not typesys.DEBUG_ON then
	array.checkElement = function() return true end
end