extends StaticBody2D

# StaticBody2D (not Area2D) is what makes this work with your existing
# combat: Player's AttackArea._on_attack_area_body_entered() only checks
# body.has_method("take_damage") - it doesn't care what type of body it is,
# so as long as this is a PhysicsBody2D with that method, it just works.

@export var min_coins := 1
@export var max_coins := 3
@export var coin_scene: PackedScene = preload("res://Scenes/Coin.tscn")
# Set a unique value per vase in the Inspector - same idea as Checkpoint's id.
@export var vase_id: String = "vase_1"

var is_broken := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if SaveManager.is_vase_broken(vase_id):
		# Already broken in a previous session - skip straight to the broken
		# look with no coin spawn, since those coins were already collected.
		is_broken = true
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("default") - 1
		collision_shape.set_deferred("disabled", true)
		z_index = 5


# This is the exact method name Player's attack looks for - matching it
# exactly is what makes the vase "hittable" with zero extra wiring.
func take_damage(_amount: int) -> void:
	if is_broken:
		return
	is_broken = true
	# Just plays the animation here - doesn't spawn coins yet. Since the
	# AnimatedSprite2D isn't set to autoplay, it sits on frame 0 (the intact
	# vase) the whole time until this actually runs.
	animated_sprite.play("default")


# Connected to the AnimatedSprite2D's animation_finished signal - only fires
# once the full breaking animation has actually played through. Since Loop
# is off, the sprite naturally stays sitting on its final frame afterward -
# no extra code needed to "hold" the broken look.
func _on_animated_sprite_2d_animation_finished() -> void:
	# Walk-through rubble, drawn in front of the player rather than behind.
	collision_shape.set_deferred("disabled", true)
	z_index = 5
	SaveManager.mark_vase_broken(vase_id)
	spawn_coins()


func spawn_coins() -> void:
	var coin_count := randi_range(min_coins, max_coins)
	for i in coin_count:
		var coin := coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
