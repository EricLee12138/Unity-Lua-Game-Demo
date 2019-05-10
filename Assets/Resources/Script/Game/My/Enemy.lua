
local logChannel = _Engine.logChannel
local channel = "enemy"

local new = typesys.new
local delete = typesys.delete

Enemy = entity.Enemy {
	_pool_capacity = -1, -- default is -1(infinit)
	_strong_pool = true, -- default is false(weak)

	_components = {
		component.tf,
		component.as,
		component.mv,
		component.ai,
		component.cld,
		component.anim,
		component.death
	}
}

function Enemy:ctor(obj)
	self.tf_position = obj.transform.position
	self.tf_scale = obj.transform.localScale
	self.tf_rotation = obj.transform.localEulerAngles

	self.mv_speed = Vector3.New()
	self.mv_next_position = obj.transform.position
	self.mv_next_speed = Vector3.New()

	self.as_go_handler = new(GameObjectHandler, obj, "Enemy")

	local collider = self.as_go_handler:getBoxCollider()
	self.cld_collider = Bounds.New(collider.center, collider.size)
	self.cld_move_layer = LayerMask.GetMask("Block")

	self.death_reg_id = obj.id
	self.death_duration = 0.85

	logChannel(channel, "[Enemy|{0}]ctor", self._id)
end

function Enemy:dtor()
	logChannel(channel, "[Enemy|{0}]dtor", self._id)
end