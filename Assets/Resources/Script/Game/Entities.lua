
local logChannel = _Engine.logChannel
local channel = "entity"

Creature = entity.Creature {
	_pool_capacity = -1, -- default is -1(infinit)
	_strong_pool = true, -- default is false(weak)

	_components = {
		component.tf,
		component.as,
		component.mv,
		component.ai,
	}
}

function Creature:ctor(world, p, mv_speed, ai_scope)
	local id = self._id
	logChannel(channel, "[Creature|{0}]ctor", id, p)

	self.tf_position = p:Clone()
	self.mv_speed = mv_speed or self.mv_speed
	self.mv_target_position = p:Clone()
	self.ai_born_position = p:Clone()
	self.ai_scope = ai_scope or self.ai_scope

	self.as_go_handler = world.asset_manager:newCreature("creature_"..id)
end

function Creature:dtor()
	local id = self._id
	logChannel(channel, "[Creature|{0}]dtor", id)
end