local logChannel = _Engine.logChannel
local channel = "sys_collect"

local delete = typesys.delete

SystemCollect = system.SystemCollect {
    _components = {
        component.collection
    }
}

local Physics = UnityEngine.Physics

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
    e.mv_next_position = NextPosition(e.tf_position, e.mv_speed, e.mv_gravity_scale, delta_time)

    local center = e.mv_next_position:Clone():Add(e.cld_collider.center)
    local half = e.cld_collider.extents:Clone()

    local cs = Physics.OverlapBox(center, half, Quaternion.New(0, 0, 0, 1), e.cld_collect_layer)
    if cs.Length > 0 then
        for i = 0, cs.Length - 1 do
            local c = cs[i]
            if c.name ~= entity.getTypeName(e) then
                local reg = c.gameObject.GetComponent(c.gameObject, "LuaRegister")
                if world:getType(reg) == Coin then
                    world:destroyCoin(reg)
                end
            end
        end
    end
end

function SystemCollect.update(world, time, delta_time)
	entity.foreachEntities(SystemCollect, proc, world, time, delta_time)
end
