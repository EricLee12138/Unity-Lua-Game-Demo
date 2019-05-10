
local function toluaSetID(t, obj, id)
	obj._id = id
end

local function toluaGetID(t, obj)
	return obj._id
end

local function toluaNew(t, id, ...)
	local obj = t._originNew(...)
	toluaSetID(t, obj, id)
	return obj
end

local function toluaDelete(t, obj)
end

local function toluaOnReuse(t, obj, ...)
	t._onReuse(t, obj, ...)
end

local function toluaOnRecycle(t, obj)
	t._onRecycle(t, obj)
end

local base_proto = {
	pool_capacity = -1, -- -1 is infinit
	strong_pool = true,
	new = toluaNew,
	delete = toluaDelete,
	onReuse = toluaOnReuse,
	onRecycle = toluaOnRecycle,
	setID = toluaSetID,
	getID = toluaGetID,
}

------------------------------------

local new = typesys.new
local setOwner = typesys.setOwner
local clearOwner = typesys.clearOwner

local function retainNew(old_v, new_v)
	-- print("retain", old_v and old_v._id or nil, new_v and new_v._id or nil)
	-- DON't use old_v ~= new_v, maybe __eq was setted
	-- 1.
	if nil ~= old_v then
		clearOwner(old_v)
	end
	-- 2.
	if nil ~= new_v then
		setOwner(new_v)
	end
	return new_v
end
-----------
Vector2._type_name = "Vector2"
Vector2._originNew = Vector2._overrideNew
Vector2._overrideNew = function(x, y)
	return new(Vector2, x, y)
end
Vector2._onReuse = function(t, obj, x, y)
	obj:Set(x, y)
end
Vector2._onRecycle = function(t, obj)
end
typesys.regExternal(Vector2, base_proto)
-----------
Vector3._type_name = "Vector3"
Vector3._originNew = Vector3._overrideNew
Vector3._overrideNew = function(x, y, z)
	return new(Vector3, x, y, z)
end
Vector3._onReuse = function(t, obj, x, y, z)
	obj:Set(x, y, z)
end
Vector3._onRecycle = function(t, obj)
end
typesys.regExternal(Vector3, base_proto)
-----------
Vector4._type_name = "Vector4"
Vector4._originNew = Vector4._overrideNew
Vector4._overrideNew = function(x, y, z, w)
	return new(Vector4, x, y, z, w)
end
Vector4._onReuse = function(t, obj, x, y, z, w)
	obj:Set(x, y, z, w)
end
Vector4._onRecycle = function(t, obj)
end
typesys.regExternal(Vector4, base_proto)
-----------
Quaternion._type_name = "Quaternion"
Quaternion._originNew = Quaternion._overrideNew
Quaternion._overrideNew = function(x, y, z, w)
	return new(Quaternion, x, y, z, w)
end
Quaternion._onReuse = function(t, obj, x, y, z, w)
	obj:Set(x, y, z, w)
end
Quaternion._onRecycle = function(t, obj)
end
typesys.regExternal(Quaternion, base_proto)
-----------
Bounds._type_name = "Bounds"
Bounds._originNew = Bounds._overrideNew
Bounds._overrideNew = function(center, size)
	return new(Bounds, center, size)
end
Bounds._retainNew = retainNew
Bounds._onReuse = function(t, obj, center, size)
	obj:SetCenter(center)
	obj:SetSize(size)
end
Bounds._onRecycle = function(t, obj)
	obj:Destroy()
end
typesys.regExternal(Bounds, base_proto)
-----------
Plane._type_name = "Plane"
Plane._originNew = Plane._overrideNew
Plane._overrideNew = function(in_normal, distance)
	return new(Plane, in_normal, distance)
end
Plane._retainNew = retainNew
Plane._onReuse = function(t, obj, in_normal, distance)
	obj.normal = retainNew(obj.normal, in_normal:Normalize())
	obj.distance = d
end
Plane._onRecycle = function(t, obj)
	obj.normal = retainNew(obj.normal, nil)
end
typesys.regExternal(Plane, base_proto)
-----------
Ray._type_name = "Ray"
Ray._originNew = Ray._overrideNew
Ray._overrideNew = function(direction, origin)
	return new(Ray, direction, origin)
end
Ray._retainNew = retainNew
Ray._onReuse = function(t, obj, direction, origin)
	obj.direction = retainNew(obj.direction, direction:Normalize())
	obj.origin = retainNew(obj.origin, origin:Clone())
end
Ray._onRecycle = function(t, obj)
	obj.direction = retainNew(obj.direction, nil)
	obj.origin = retainNew(obj.origin, nil)
end
typesys.regExternal(Ray, base_proto)
-----------
Color._type_name = "Color"
Color._originNew = Color._overrideNew
Color._overrideNew = function(r, g, b, a)
	return new(Color, r, g, b, a)
end
Color._onReuse = function(t, obj, r, g, b, a)
	obj:Set(r, g, b, a)
end
Color._onRecycle = function(t, obj)
end
typesys.regExternal(Color, base_proto)
-----------
LayerMask._type_name = "LayerMask"
LayerMask._originNew = LayerMask._overrideNew
LayerMask._overrideNew = function(r, v)
	return new(LayerMask, v)
end
LayerMask._onReuse = function(t, obj, v)
	obj.value = v
end
LayerMask._onRecycle = function(t, obj)
end
typesys.regExternal(LayerMask, base_proto)
-----------
Touch._type_name = "Touch"
Touch._originNew = Touch._overrideNew
Touch._overrideNew = function(fingerId, position, rawPosition, deltaPosition, deltaTime, tapCount, phase)
	return new(Touch, fingerId, position, rawPosition, deltaPosition, deltaTime, tapCount, phase)
end
Touch._retainNew = retainNew
Touch._onReuse = function(t, obj, fingerId, position, rawPosition, deltaPosition, deltaTime, tapCount, phase)
	obj:Init(fingerId, position, rawPosition, deltaPosition, deltaTime, tapCount, phase)
end
Touch._onRecycle = function(t, obj)
	obj:Destroy()
end
typesys.regExternal(Touch, base_proto)
-----------
RaycastHit._type_name = "RaycastHit"
RaycastHit._originNew = RaycastHit._overrideNew
RaycastHit._overrideNew = function(collider, distance, normal, point, rigidbody, transform)
	return new(RaycastHit, collider, distance, normal, point, rigidbody, transform)
end
RaycastHit._retainNew = retainNew
RaycastHit._onReuse = function(t, obj, collider, distance, normal, point, rigidbody, transform)
	obj:Init(collider, distance, normal, point, rigidbody, transform)
end
RaycastHit._onRecycle = function(t, obj)
	obj:Destroy()
end
typesys.regExternal(RaycastHit, base_proto)
-----------

