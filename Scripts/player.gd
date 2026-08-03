extends CharacterBody2D
const SPEED = 130.0
const JUMP_VELOCITY = -350.0
var is_attacking = false
var count = 0
var sword_drawn = false
var max_health: int = 5
var health: int = max_health
var is_hurt = false

@onready var attack_hitbox = $AttackArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func deal_damage() -> void:
	var bodies = attack_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(1)
			
func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation in ["attack1", "attack2", "attack3"]:
		if animated_sprite.frame == 2:
			attack_hitbox.get_node("CollisionShape2D").disabled = false
			deal_damage()
		else:
			attack_hitbox.get_node("CollisionShape2D").disabled = true

func take_damage(amount: int) -> void:
	if is_hurt:
		return
	health -= amount
	print("Player health:", health)
	if health <= 0:
		is_attacking = false 
		is_hurt = true 
		animated_sprite.play("die")
	else:
		is_attacking = false 
		is_hurt = true
		animated_sprite.play("hurt")

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack1":
		is_attacking = false
	elif animated_sprite.animation == "attack2":
		is_attacking = false
	elif animated_sprite.animation == "attack3":
		is_attacking = false 
		count = 0
	elif animated_sprite.animation == "hurt":
		is_hurt = false 
	elif animated_sprite.animation == "die":
		get_tree().reload_current_scene()

func _on_timer_timeout():
	count = 0
	is_attacking = false 
	print("Combo timed out. Next hit will be attack1!")


func in_air() -> void:
	if velocity.y < 0:
		animated_sprite.play("jump")
	elif velocity.y > 0:
		animated_sprite.play("fall")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false 
	elif direction < 0:
		animated_sprite.flip_h = true
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# Handle attack input
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_hurt:
		is_attacking = true
		count += 1
		print("current combo step: ", count)
		if count == 1:
			animated_sprite.play("attack1")
			$Timer.start()
		elif count == 2:
			animated_sprite.play("attack2")
			$Timer.start()
		elif count == 3:
			animated_sprite.play("attack3")
			$Timer.start()

	# Play animations (only if NOT attacking)
	if not is_attacking and not is_hurt:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		else:
			in_air()
		
	move_and_slide()
