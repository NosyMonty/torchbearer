extends Area2D

@export var speed := 300.0
@export var catch_distance := 10.0

var target: Node2D = null
var following := false


func _on_body_entered(body: Node2D) -> void:
	# Only start homing in once, toward whichever player entered the
	# magnet radius first - the "not following" guard stops this from
	# re-triggering every physics frame the player stays inside the area.
	if body.is_in_group("player") and not following:
		following = true
		target = body


func _physics_process(delta: float) -> void:
	if following and target:
		global_position = global_position.move_toward(target.global_position, speed * delta)

		if global_position.distance_to(target.global_position) < catch_distance:
			collect()


func collect() -> void:
	SaveManager.add_coins(1)
	queue_free()
