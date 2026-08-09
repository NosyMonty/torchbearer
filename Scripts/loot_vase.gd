extends StaticBody2D

# StaticBody2D (not Area2D) is what makes this work with your existing
# combat: Player's AttackArea._on_attack_area_body_entered() only checks
# body.has_method("take_damage") - it doesn't care what type of body it is,
# so as long as this is a PhysicsBody2D with that method, it just works.

@export var min_coins := 1
@export var max_coins := 3
@export var coin_scene: PackedScene = preload("res://Scenes/coin.tscn")

var is_broken := false


# This is the exact method name Player's attack looks for - matching it
# exactly is what makes the vase "hittable" with zero extra wiring.
func take_damage(_amount: int) -> void:
	if is_broken:
		return
	break_vase()


func break_vase() -> void:
	is_broken = true

	var coin_count := randi_range(min_coins, max_coins)
	for i in coin_count:
		var coin := coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position

	queue_free()
