
local logChannel = _Engine.logChannel
local channel = "sys_ctrl"

SystemControl = system.SystemControl {
	_components = {
		component.ctrl,
	}
}

local Input = UnityEngine.Input
local function proc(e, world, time, delta_time)
	local left = Input.GetButton("Left")
	local right = Input.GetButton("Right")
	local jump = Input.GetButtonDown("Jump")

	local rot = e.tf_rotation.y
	local dir = math.sin(math.rad(rot)) - math.cos(math.rad(rot)) < 0 and -1 or 1

	if rot == 0 or rot == 180 or rot == -180 then
		if left then
			e.mv_speed.x = dir * e.ctrl_move_speed;
			e.tf_scale.x = -1
		elseif right then
			e.mv_speed.x = -dir * e.ctrl_move_speed;
			e.tf_scale.x = 1
		else
			e.mv_speed.x = 0;
		end
	elseif rot == -90 or rot == 90 then
		if left then
			e.mv_speed.z = dir * e.ctrl_move_speed;
			e.tf_scale.x = -1
		elseif right then
			e.mv_speed.z = -dir * e.ctrl_move_speed;
			e.tf_scale.x = 1
		else
			e.mv_speed.z = 0;
		end
	end

	if jump and not e.ctrl_is_jumping and e.mv_speed.y == 0 then
		e.mv_speed.y = e.ctrl_jump_speed
		e.ctrl_is_jumping = true
	end
end

function SystemControl.update(world, time, delta_time)
	entity.foreachEntities(SystemControl, proc, world, time, delta_time)
end