extends Area2D

const DAMAGE = 1

# Tracked via signals rather than polling get_overlapping_bodies() at the
# strike frame - that same-frame-toggle pattern caused the "flushing
# queries" bug on the player's own hitbox earlier, so this stays continuously
# monitoring instead and just reads a boolean at the right moment.
var player_in_zone := false
var player_ref: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite.play("spell")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_zone = true
		player_ref = body


func _on_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_in_zone = false


# Deals damage on the "strike" frame - frame 4 is a placeholder, adjust to
# match the actual moment the hand grabs in your animation.
func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.frame == 6 and player_in_zone and player_ref:
		player_ref.take_damage(DAMAGE)
		player_in_zone = false  # prevents hitting again on later frames


func _on_animation_finished() -> void:
	queue_free()


func _on_animated_sprite_2d_animation_changed() -> void:
	pass


func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
