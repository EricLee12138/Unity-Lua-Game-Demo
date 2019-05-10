local logChannel = _Engine.logChannel
local channel = "sys_dmg"

local delete = typesys.delete

SystemDamage = system.SystemDamage {
    _components = {
        component.dmg
    }
}

local move_unit = 2
local Physics = UnityEngine.Physics
local gap = 0.001

local function NextPosition(position, speed, gravity, time, delta_time)
    local next_p, next_v

    local cur_p = position:Clone()
    local cur_v = speed:Clone()

    cur_v.y = cur_v.y + gravity * Time.fixedDeltaTime
    next_v = cur_v:Clone()
    next_p = cur_p:Add(cur_v:Mul(Time.fixedDeltaTime))

    return next_p, next_v
end

local function proc(e, world, time, delta_time)

    if e.dmg_immune_time > 0 then
        e.dmg_immune_time = e.dmg_immune_time - delta_time
    else
        e.mv_next_position, e.mv_next_speed = NextPosition(e.tf_position, e.mv_speed, e.mv_gravity_scale, time, delta_time)

        e.mv_speed = e.mv_next_speed:Clone()

        local center = e.tf_position:Clone():Add(e.cld_collider.center)
        local half = e.cld_collider.extents:Clone()
        local mod_position = e.mv_next_position:Clone()

        center.y = e.mv_next_position.y
        local c_y = Physics.OverlapBox(center, half, Quaternion.New(0, 0, 0, 1), e.cld_damage_layer)
        if c_y.Length > 0 then
            for i = 0, c_y.Length - 1 do
                local c = c_y[i]
                if c.name ~= entity.getTypeName(e) then
                    if e.mv_speed.y < 0 then
                        mod_position.y = c.bounds.max.y + half.y + gap

                        local reg = c.gameObject.GetComponent(c.gameObject, "LuaRegister")
                        if world:getType(reg) == Enemy then
                            e.mv_speed.y = e.ctrl_jump_speed

                            local enemy = world:getEnemyByID(reg.id)
                            enemy.death_dead = true
                            enemy.ai_move_speed = 0
                        end
                    end
                end
            end
        end

        center.y = mod_position.y
        center.x = e.mv_next_position.x
        local c_x = Physics.OverlapBox(center, half, Quaternion.New(0, 0, 0, 1), e.cld_damage_layer)
        if c_x.Length > 0 then
            for i = 0, c_x.Length - 1 do
                local c = c_x[i]
                if c.name ~= entity.getTypeName(e) then
                    e.mv_speed.x = e.tf_position.x < c.bounds.center.x and -move_unit or move_unit
                    e.mv_speed.y = e.ctrl_jump_speed

                    e.ctrl_is_jumping = true
                    
                    e.dmg_duration = 1.2
                    e.dmg_immune_time = 3
                    e.dmg_damage_value = 1

                    entity.disableComponent(e, component.ctrl)
                end
            end
        end

        e.tf_position = mod_position:Clone()
        e.as_go_handler:setPosition(e.tf_position)
    end

    if e.dmg_duration > 0 then
        e.dmg_duration = e.dmg_duration - delta_time
    else
        if not entity.isComponentEnabled(e, component.ctrl) then
            entity.enableComponent(e, component.ctrl)
        end
    end
end

function SystemDamage.update(world, time, delta_time)
	entity.foreachEntities(SystemDamage, proc, world, time, delta_time)
end
