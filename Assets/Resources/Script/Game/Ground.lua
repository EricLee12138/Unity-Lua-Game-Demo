
local logChannel = _Engine.logChannel
local channel = "ground"

local new = typesys.new

---------

Ground = typesys.Ground {
	plane = Plane,
	world_type = 0,
	world_id = 0,
	position = Vector3,
	hit_position = Vector3,
}

local Camera = UnityEngine.Camera
local Input = UnityEngine.Input

function Ground:ctor(obj)
	self.world_type = obj.type
	self.world_id = obj.id
	self.position = obj.transform.position

	local plane = new(Plane, Vector3.up, 0)
	plane:SetNormalAndPosition(Vector3.up, self.position)
	self.plane = plane

	logChannel(channel, "ctor:{0}, {1}, {2}", self.world_type, self.world_id, position)
end

function Ground:dtor()
	logChannel(channel, "dtor")
end

function Ground:update(world, time, delta_time)
	if Input.GetMouseButton(0) or Input.GetMouseButtonDown(0) then
		local camera = Camera.main
		local ray = camera:ScreenPointToRay(Input.mousePosition)
	    local hited, enter = self.plane:Raycast(ray)
	    if hited then
			self.hit_position = ray:GetPoint(enter)
			logChannel(channel, "<hit> {0}", self.hit_position)
		else
			self.hit_position = nil
		end
	else
		self.hit_position = nil
	end
end


