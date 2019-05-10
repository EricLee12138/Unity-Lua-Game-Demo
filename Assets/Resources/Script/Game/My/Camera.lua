
local logChannel = _Engine.logChannel
local channel = "camera"

local new = typesys.new

Camera = typesys.Camera {
	world_type = 0,
	world_id = 0,

	position = Vector3,
	rotation = Vector3,
	target = Vector3,

	from_rotation = Vector3,
	to_rotation = Vector3,

	cancel = false,
	cancel_rest = 0.3,

	go_handler = GameObjectHandler,
}

local MainCamera = UnityEngine.Camera
local Input = UnityEngine.Input

function Camera:ctor(obj)
	self.world_type = obj.type
	self.world_id = obj.id

	self.position = obj.transform.position
	self.rotation = obj.transform.localEulerAngles
	self.target = Vector3.New()

	self.from_rotation = obj.transform.localEulerAngles
	self.to_rotation = obj.transform.localEulerAngles

	self.go_handler = new(GameObjectHandler, obj, "Camera")

	logChannel(channel, "[Camera|{0}]ctor", self._id)
end

function Camera:dtor()
	logChannel(channel, "[Camera|{0}]dtor", self._id)
end


local dist = 100
local sensitivity_x = 10
local sensitivity_y = 10

local min_y = -60
local max_y = 60

local rot_x = 0
local rot_y = 0


function Camera:update(world, time, delta_time)
	
	local player = world.player
	self.target = player.tf_position:Clone()

	if Input.GetMouseButtonDown(0) then
		self.from_rotation = self.rotation:Clone()
	end

	if Input.GetMouseButton(0) then
		entity.disableAllComponents(player)

		rot_x = rot_x + Input.GetAxis("Mouse X") * sensitivity_x
		rot_y = rot_y + Input.GetAxis("Mouse Y") * sensitivity_y

		if rot_x > 180 then
			rot_x = rot_x - 360
		elseif rot_x < -180 then
			rot_x = rot_x + 360
		end

		rot_y = math.min(rot_y, max_y)
		rot_y = math.max(rot_y, min_y)

		self.rotation = Vector3.New(-rot_y, rot_x, 0)
		self.go_handler:setRotation(self.rotation)
	else
		if Input.GetMouseButtonUp(0) then
			local x_pos = self.position.x - self.target.x
			local z_pos = self.position.z - self.target.z

			if math.abs(x_pos) >= math.abs(z_pos) then
				if x_pos >= 0 then	-- right
					self.to_rotation = Vector3.New(0, -90, 0)
				else	-- left
					self.to_rotation = Vector3.New(0, 90, 0)
				end
			else
				if z_pos >= 0 then	-- back
					if x_pos >= 0 and self.rotation.y ~= 180 then
						self.to_rotation = Vector3.New(0, -180, 0)
					elseif x_pos < 0 and self.rotation.y ~= -180 then
						self.to_rotation = Vector3.New(0, 180, 0)
					end
				else	-- front
					self.to_rotation = Vector3.New(0, 0, 0)
				end
			end
		end

		if self.to_rotation ~= self.rotation then
			local speed = self.from_rotation == self.to_rotation and 1.5 or 0.4

			self.rotation = Vector3.RotateTowards(self.rotation, self.to_rotation, delta_time * speed, delta_time * speed * dist)
			self.go_handler:setRotation(self.rotation)

			rot_x = self.rotation.y
			rot_y = 0
		else
			if self.cancel then
				entity.disableAllComponents(player)

				if self.cancel_rest > 0 then
					self.cancel_rest = self.cancel_rest - delta_time
				else
					self.cancel_rest = 0.3
					self.to_rotation = self.from_rotation:Clone()
					self.cancel = false
				end
			end
		end

		if self.to_rotation ~= player.tf_rotation then
			player.tf_rotation = Vector3.MoveTowards(player.tf_rotation, self.to_rotation, delta_time * 200)

			player.as_go_handler:setRotation(player.tf_rotation)
		else
			if not entity.isComponentEnabled(player, component.mv) then
				entity.enableAllComponents(player)
			end
		end
	end
end

function Camera:lateupdate(world, time, delta_time)
	local point = MainCamera.main.ViewportToWorldPoint(MainCamera.main, Vector3.New(0.5, 0.5, dist))

	self.position = self.target:Clone():Sub(point:Sub(self.position))
	self.go_handler:setPosition(self.position)
end