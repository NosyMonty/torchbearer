extends Area2D
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return
	var fall_speed = body.pre_collision_velocity_y
	var damage = 1
	if fall_speed > 800:
		damage = 9999
	elif fall_speed > 500:
		damage = 3
	elif fall_speed > 350:
		damage = 2
	body.take_damage(damage)
