local logChannel = _Engine.logChannel
local channel = "sys_move"

SystemMove = system.SystemMove {
    _components = {
        component.tf,
        component.mv
    }
}

local Physics = UnityEngine.Physics
local Time = UnityEngine.Time
local gap = 0.001

local function NextPosition(position, speed, gravity, delta_time)
    local next_p, next_v

    local cur_p = position:Clone()
    local cur_v = speed:Clone()

    cur_v.y = cur_v.y + gravity * Time.fixedDeltaTime
    next_v = cur_v:Clone()
    next_p = cur_p:Add(cur_v:Mul(Time.fixedDeltaTime))

    return next_p, next_v
end

local function proc(e, world, time, delta_time)
    e.mv_next_position, e.mv_next_speed = NextPosition(e.tf_position, e.mv_speed, e.mv_gravity_scale, delta_time)

    e.mv_speed = e.mv_next_speed:Clone()

    local center = e.tf_position:Clone():Add(e.cld_collider.center)
    local half = e.cld_collider.extents:Clone()
    local mod_position = e.mv_next_position:Clone()
    local quat = Quaternion:SetEuler(e.tf_rotation.x, e.tf_rotation.y, e.tf_rotation.z)

    center.x = e.mv_next_position.x + e.cld_collider.center.x
	local c_x = Physics.OverlapBox(center, half, quat, e.cld_move_layer)
    if c_x.Length > 0 then
        for i = 0, c_x.Length - 1 do
            local c = c_x[i]
            if c.name ~= entity.getTypeName(e) then
                if e.mv_speed.x > 0 then
                    mod_position.x = c.bounds.min.x - half.x + e.cld_collider.center.x - gap
                elseif e.mv_speed.x < 0 then
                    mod_position.x = c.bounds.max.x + half.x - e.cld_collider.center.y + gap
                else
                    world.camera.cancel = true
                end
            end
        end
        e.mv_speed.x = 0
    end

    center.x = mod_position.x
    center.z = e.mv_next_position.z + e.cld_collider.center.z
    local c_z = Physics.OverlapBox(center, half, quat, e.cld_move_layer)
    if c_z.Length > 0 then
        for i = 0, c_z.Length - 1 do
            local c = c_z[i]
            if c.name ~= entity.getTypeName(e) then
                if e.mv_speed.z > 0 then
                    mod_position.z = c.bounds.min.z - half.x + e.cld_collider.center.z - gap
                elseif e.mv_speed.z < 0 then
                    mod_position.z = c.bounds.max.z + half.x - e.cld_collider.center.z + gap
                else
                    world.camera.cancel = true
                end
            end
        end
        e.mv_speed.z = 0
    end

    center.z = mod_position.z
    center.y = e.mv_next_position.y + e.cld_collider.center.y
    local c_y = Physics.OverlapBox(center, half, quat, e.cld_move_layer)
    if c_y.Length > 0 then

        local rot = e.tf_rotation.y
        if not world.camera.cancel then
            if rot == 0 or rot == 180 or rot == -180 then
                mod_position.z = c_y[0].bounds.center.z
            elseif rot == 90 or rot == -90 then
                mod_position.x = c_y[0].bounds.center.x
            end
        end

        for i = 0, c_y.Length - 1 do
            local c = c_y[i]
            if c.name ~= entity.getTypeName(e) then
                if e.mv_speed.y > 0 then
                    mod_position.y = c.bounds.min.y - half.y + e.cld_collider.center.y - gap
                elseif e.mv_speed.y < 0 then
                    mod_position.y = c.bounds.max.y + half.y - e.cld_collider.center.y + gap

                    if not world.camera.cancel then
                        if rot == 0 then
                            if c.bounds.center.z < mod_position.z then
                                mod_position.z = c.bounds.center.z
                            end
                        elseif rot == 90 then
                            if c.bounds.center.x < mod_position.x then
                                mod_position.x = c.bounds.center.x
                            end
                        elseif rot == -90 then
                            if c.bounds.center.x > mod_position.x then
                                mod_position.x = c.bounds.center.x
                            end
                        elseif rot == 180 or rot == -180 then
                            if c.bounds.center.z > mod_position.z then
                                mod_position.z = c.bounds.center.z
                            end
                        end
                    end

                    if entity.getType(e) == Player then
                        e.dmg_duration = 0
                        e.ctrl_is_jumping = false
                    end
                end
            end
        end
        e.mv_speed.y = 0
    end

    if entity.getType(e) ~= Player then
        if e.mv_speed.x > 0  then
            e.tf_scale.x = 1
        elseif e.mv_speed.x < 0  then
            e.tf_scale.x = -1
        end
    end

    e.tf_position = mod_position:Clone()
    e.as_go_handler:setPosition(e.tf_position)
    e.as_go_handler:setScale(e.tf_scale)
end

function SystemMove.update(world, time, delta_time)
	entity.foreachEntities(SystemMove, proc, world, time, delta_time)
end
