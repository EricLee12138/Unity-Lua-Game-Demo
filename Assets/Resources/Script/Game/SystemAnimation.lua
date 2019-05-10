
local logChannel = _Engine.logChannel
local channel = "sys_animation"

SystemAnimation = system.SystemAnimation {
	_components = {
		component.anim,
	}
}

local function proc(e, world, time, delta_time)
	local cur_s = e.anim_cur_state
	local next_s = e.anim_next_state

	if entity.getType(e) == Player then
		if e.ctrl_is_jumping then
			next_s = "Jump"
			e.as_go_handler:animSetFloat("SpeedY", e.mv_next_speed.y)
			if e.mv_next_speed.y < 0 then
				next_s = "Drop"
			end
		else
			next_s = "Idle"
			if e.mv_next_speed.x ~= 0 or e.mv_next_speed.z ~= 0 then
				next_s = "Run"
			end
		end

		if e.dmg_immune_time > 0 then
			e.as_go_handler:animSetBool("Immune", true)
		else
			e.as_go_handler:animSetBool("Immune", false)
		end

		if cur_s ~= next_s then
			local go = e.as_go_handler
			if cur_s == "Idle" then
				if next_s == "Run" then
					go:animSetBool("Run", true)
				elseif next_s == "Jump" then
					go:animSetBool("Jump", true)
				end
			elseif cur_s == "Run" then
				if next_s == "Jump" then
					go:animSetBool("Jump", true)
				elseif next_s == "Idle" then
					go:animSetBool("Run", false)
				end
			elseif cur_s == "Drop" then
				if next_s == "Idle" then
					go:animSetBool("Jump", false)
					go:animSetBool("Run", false)
				elseif next_s == "Run" then
					go:animSetBool("Jump", false)
					go:animSetBool("Run", true)
				end
			end
		end
	end

	if entity.getType(e) == Enemy then
		if e.death_dead then
			next_s = "Dead"
		end

		if cur_s ~= next_s then
			local go = e.as_go_handler
			if next_s == "Dead" then
				go:animSetBool("Dead", true)
			end
		end
	end

	e.anim_cur_state = next_s
end

function SystemAnimation.update(world, time, delta_time)
	entity.foreachEntities(SystemAnimation, proc, world, time, delta_time)
end

