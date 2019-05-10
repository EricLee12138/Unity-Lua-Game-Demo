
component.tf {
	_name = "Transform",
	position = Vector3,
}

component.as {
	_name = "Asset",
	go_handler = GameObjectHandler,
}

component.mv {
	_name = "Move",
	speed = 3,
	target_position = Vector3,
}

component.ai {
	_name = "AI",
	born_position = Vector3,
	scope = 10,
	rest_time = 0,
}