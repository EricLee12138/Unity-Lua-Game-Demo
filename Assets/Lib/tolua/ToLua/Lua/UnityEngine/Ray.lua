--------------------------------------------------------------------------------
--      Copyright (c) 2015 - 2016 , 蒙占志(topameng) topameng@gmail.com
--      All rights reserved.
--      Use, modification and distribution are subject to the "MIT License"
--------------------------------------------------------------------------------
local rawget = rawget
local setmetatable = setmetatable
local Vector3 = Vector3

local Ray = {}

local get = tolua.initget(Ray)

Ray.__index = function(t,k)
	local var = rawget(Ray, k)
		
	if var == nil then							
		var = rawget(get, k)
		
		if var ~= nil then
			return var(t)	
		end
	end
	
	return var
end

Ray.__call = function(t, direction, origin)
	return Ray.New(direction, origin)
end

function Ray.New(direction, origin)
	local ray = {}	
	ray.direction 	= Ray._retainNew(nil, direction:Normalize())
	ray.origin 		= Ray._retainNew(nil, origin:Clone())
	setmetatable(ray, Ray)	
	return ray
end

------- be typesys external type -------
Ray._overrideNew = Ray.New
Ray._retainNew = function(old_v, new_v)
	return new_v
end
Ray.New = function(direction, origin)
	return Ray._overrideNew(direction, origin)
end
----------------------------------------

function Ray:GetPoint(distance)
	local dir = self.direction * distance
	dir:Add(self.origin)
	return dir
end

function Ray:Get()		
	local o = self.origin
	local d = self.direction
	return o.x, o.y, o.z, d.x, d.y, d.z
end

Ray.__tostring = function(self)
	return string.format("Origin:(%f,%f,%f),Dir:(%f,%f, %f)", self.origin.x, self.origin.y, self.origin.z, self.direction.x, self.direction.y, self.direction.z)
end

UnityEngine.Ray = Ray
setmetatable(Ray, Ray)
return Ray