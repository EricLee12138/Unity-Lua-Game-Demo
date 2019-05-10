
local logChannel = _Engine.logChannel
local logWarningChannel = _Engine.logWarningChannel
local channel = "player"

local new = typesys.new

Player = entity.Player {
	_pool_capacity = -1, -- default is -1(infinit)
	_strong_pool = true, -- default is false(weak)

	_components = {
		component.tf,
		component.as,
		component.mv,
		component.cld,
		component.dmg,
		component.ctrl,
		component.collection,
		component.anim
	}
}

local Input = UnityEngine.Input

function Player:ctor(obj)
	self.tf_position = obj.transform.position
	self.tf_scale = obj.transform.localScale
	self.tf_rotation = obj.transform.localEulerAngles

	self.mv_speed = Vector3.New()
	self.mv_next_position = obj.transform.position
	self.mv_next_speed = Vector3.New()

	self.as_go_handler = new(GameObjectHandler, obj, "Player")

	local collider = self.as_go_handler:getBoxCollider()
	self.cld_collider = Bounds.New(collider.center, collider.size)
	self.cld_move_layer = LayerMask.GetMask("Block")
	self.cld_damage_layer = LayerMask.GetMask("Enemy")
	self.cld_collect_layer = LayerMask.GetMask("Coin")

	logChannel(channel, "[Player|{0}]ctor", self._id)
end

function Player:dtor()
	logChannel(channel, "[Player|{0}]dtor", self._id)
end