
local logChannel = _Engine.logChannel
local channel = "coin"

local new = typesys.new

Coin = entity.Coin {
	_pool_capacity = -1, -- default is -1(infinit)
	_strong_pool = true, -- default is false(weak)

	_components = {
		component.tf,
		component.as,
		component.cld,
	}
}

function Coin:ctor(obj)
	self.tf_position = obj.transform.position
	self.tf_scale = obj.transform.localScale

	self.as_go_handler = new(GameObjectHandler, obj, "Coin")

	local collider = self.as_go_handler:getBoxCollider()
	self.cld_collider = Bounds.New(collider.center, collider.size)

	logChannel(channel, "[Coin|{0}]ctor", self._id)
end

function Coin:dtor()
	logChannel(channel, "[Coin|{0}]dtor", self._id)
end