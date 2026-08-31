extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, CAST, HURT, DEAD }
var current_state: State = State.IDLE

const SPEED = 40.0
const MELEE_DAMAGE = 2
# How far above the player's position the portal spawns.
const PORTAL_SPAWN_OFFSET = Vector2(0, -32)

var max_health := 10
var health := max_health
var player_ref: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_cooldown: Timer = $AttackCooldown

const PORTAL_SCENE := preload("res://Scenes/Portal.tscn")


func _ready() -> void:
	change_state(State.IDLE)


# Central place that both sets the animation AND updates current_state -
# keeps the two from ever falling out of sync with each other.
func change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.IDLE:
			animated_sprite.play("idle")
		State.CHASE:
			animated_sprite.play("walk")
		State.ATTACK:
			animated_sprite.play("attack")
		State.CAST:
			animated_sprite.play("cast")
		State.HURT:
			animated_sprite.play("hurt")
		State.DEAD:
			animated_sprite.play("die")


func _physics_process(_delta: float) -> void:
	if current_state == State.CHASE and player_ref:
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * SPEED
		animated_sprite.flip_h = direction.x > 0
		move_and_slide()

		# Once off cooldown, decide what to do next. If the player happens to
		# be in melee range right now, it's a coin-flip between melee and
		# cast; if not in range, cast is the only option (melee can't reach).
		if attack_cooldown.is_stopped():
			var in_melee_range = attack_area.overlaps_body(player_ref)
			if in_melee_range and randi() % 2 == 0:
				change_state(State.ATTACK)
			else:
				change_state(State.CAST)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.IDLE:
		player_ref = body
		change_state(State.CHASE)


# Deals melee damage on the swing frame - assumes frame 2, same convention
# as your other attack animations. Verify against the actual art.
func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame == 2:
		if player_ref and attack_area.overlaps_body(player_ref):
			player_ref.take_damage(MELEE_DAMAGE)


func spawn_portal() -> void:
	if not player_ref:
		return
	var portal = PORTAL_SCENE.instantiate()
	get_parent().add_child(portal)
	portal.global_position = player_ref.global_position + PORTAL_SPAWN_OFFSET


func _on_animated_sprite_2d_animation_finished() -> void:
	match animated_sprite.animation:
		"attack":
			attack_cooldown.start()
			change_state(State.CHASE if player_ref else State.IDLE)
		"cast":
			spawn_portal()
			attack_cooldown.start()
			change_state(State.CHASE if player_ref else State.IDLE)
		"hurt":
			change_state(State.CHASE if player_ref else State.IDLE)
		"die":
			detection_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			attack_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			$CollisionShape2D.set_deferred("disabled", true)
			# Rename this shard id to whatever you want tracked in the save file.
			SaveManager.collect_shard("bringer_of_death")
			queue_free()


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	health -= amount
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)


func _on_animated_sprite_2d_animation_changed() -> void:
	pass # Replace with function body.
