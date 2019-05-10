
component.tf {
	_name = "Transform",
	position = Vector3,
	scale = Vector3,
	rotation = Vector3
}

component.as {
	_name = "Asset",
	go_handler = GameObjectHandler,
}

component.mv {
	_name = "Move",
	speed = Vector3,
	gravity_scale = -7.5,
	next_speed = Vector3,
	next_position = Vector3,
}

component.ai {
	_name = "AI",
	move_speed = 0.75,
	move_direction = -1,
}

component.cld {
	_name = "Collider",
	collider = Bounds,
	move_layer = 0,
	damage_layer = 0,
	collect_layer = 0
}

component.dmg {
	_name = "Damage",
	duration = 0,
	immune_time = 0,
	damage_value = 0
}

component.ctrl {
	_name = "Control",
	move_speed = 1.9,
	jump_speed = 4.5,
	is_jumping = false
}

component.collection {
	_name = "Collection",
	score = 1
}

component.anim {
	_name = "Animation",
	cur_state = "Idle",
	next_state = "Idle"
}

component.death {
	_name = "Dead",
	dead = false,
	duration = 1,
	reg_id = 0
}