
local logChannel = _Engine.logChannel
local channel = "sys_death"

SystemDeath = system.SystemDeath {
	_components = {
		component.death,
	}
}

local function proc(e, world, time, delta_time)
	if e.death_dead then
		e.death_duration = e.death_duration - delta_time
		if e.death_duration <= 0 then
			world:destroyEnemyByID(e.death_reg_id)
		end
	end
end

function SystemDeath.update(world, time, delta_time)
	entity.foreachEntities(SystemDeath, proc, world, time, delta_time)
end

