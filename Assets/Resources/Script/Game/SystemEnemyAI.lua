local logChannel = _Engine.logChannel
local channel = "sys_enemy_ai"

local function randomN2M(n, m)
	return math.random() * (m-n) + n
end

SystemEnemyAI = system.SystemEnemyAI {
	_components = {
		component.ai,
		component.mv,
	}
}

local Physics = UnityEngine.Physics

local function proc(e, world, time, delta_time)
	local center = e.tf_position:Clone():Add(e.cld_collider.center)
	local extent = e.cld_collider.extents:Clone()
	local offset = Vector3.New(e.ai_move_direction * extent.x, -extent.y, 0)
	local origin = center:Add(offset)
	local down = Vector3.New(0, -1, 0)
	local front = Vector3.New(e.ai_move_direction, 0, 0)
	local dist = 0.01
	
	local safe = Physics.Raycast(origin, down, dist, e.cld_move_layer)
	local blocked = Physics.Raycast(origin, front, dist, e.cld_move_layer)
	if not safe or blocked then
		e.ai_move_direction = e.ai_move_direction * -1
	end

	e.mv_speed.x = e.ai_move_direction * e.ai_move_speed
end

function SystemEnemyAI.update(world, time, delta_time)
	entity.foreachEntities(SystemEnemyAI, proc, world, time, delta_time)
end