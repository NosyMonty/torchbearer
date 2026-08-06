extends CharacterBody2D
const SPEED = 130.0
const SLIDE_SPEED = 220.0
const JUMP_VELOCITY = -350.0
var is_attacking = false
var count = 0
var sword_drawn = false
var is_toggling_sword = false
var is_sliding = false
var max_health: int = 5
var health: int = max_health
var is_hurt = false
@onready var attack_hitbox = $AttackArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Runs once when the player enters the scene.
# Makes sure the attack hitbox starts OFF so it can't damage anything before an attack happens.
func _ready() -> void:
	attack_hitbox.get_node("CollisionShape2D").disabled = true

# Fires automatically whenever a physics body touches the AttackArea.
# Only counts as a hit if the player is actually mid-attack, preventing accidental damage.
func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(1)
		print("damage delt")

# Fires every time the attack animation advances a frame.
# Turns the hitbox ON only during the exact "swing" frame, and OFF the rest of the time.
func _on_animated_sprite_2d_frame_changed() -> void:
	if animated_sprite.animation in ["attack1", "attack2", "attack3"]:
		if animated_sprite.frame == 2:
			attack_hitbox.get_node("CollisionShape2D").disabled = false
		else:
			attack_hitbox.get_node("CollisionShape2D").disabled = true
	else:
		attack_hitbox.get_node("CollisionShape2D").disabled = true

# Called by enemies (e.g. the bat) when they successfully hit the player.
# Reduces health and plays either the hurt or die animation depending on how much health is left.
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

# Creates a black rectangle covering the whole screen and fades it in over 1 second.
# Once the fade finishes, reloads the current scene (temporary respawn method until checkpoints exist).
func fade_to_black() -> void:
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas = CanvasLayer.new()
	canvas.add_child(fade_rect)
	get_tree().root.add_child(canvas)
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	tween.tween_callback(get_tree().reload_current_scene)

# Fires automatically whenever ANY animation on the player finishes playing.
# Used to reset state variables once their animation is done, so the next
# action can only start after the current one has properly finished.
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
		fade_to_black()
	elif animated_sprite.animation == "drawsword":
		sword_drawn = true
		is_toggling_sword = false
	elif animated_sprite.animation == "sheathesword":
		sword_drawn = false
		is_toggling_sword = false
	elif animated_sprite.animation == "slide":
		is_sliding = false

# Fires when the combo timer runs out (player didn't attack again in time).
# Resets the combo back to the start.
func _on_timer_timeout():
	count = 0
	is_attacking = false
	print("Combo timed out. Next hit will be attack1!")

# Decides whether to play the "jump" (rising) or "fall" (descending) animation,
# based on the current direction of vertical velocity.
func in_air() -> void:
	if velocity.y < 0:
		animated_sprite.play("jump")
	elif velocity.y > 0:
		animated_sprite.play("fall")

# Runs every physics frame. Handles gravity, jumping, movement, attacking,
# sword drawing/sheathing, sliding, and choosing which animation should currently play.
func _physics_process(delta: float) -> void:
	# Apply gravity while airborne.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump only if the jump key was just pressed AND the player is on the ground.
	# Also cancels a slide early if the player jumps out of it.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if is_sliding:
			is_sliding = false

	# Read left/right input and move accordingly.
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Use the faster slide speed while sliding, otherwise normal run speed,
	# and decelerate smoothly when there's no input at all.
	if direction:
		if is_sliding:
			velocity.x = direction * SLIDE_SPEED
		else:
			velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Start a new attack (or continue the combo) only if not already attacking, hurt, or sliding.
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_hurt and not is_sliding:
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

	# Toggle drawing/sheathing the sword, only if not already mid-action.
	if Input.is_action_just_pressed("draw_sword") and not is_toggling_sword and not is_attacking and not is_hurt and not is_sliding:
		is_toggling_sword = true
		if sword_drawn:
			animated_sprite.play("sheathesword")
		else:
			animated_sprite.play("drawsword")

	# Start a slide: only while running (direction != 0), on the ground, and not mid-action.
	if Input.is_action_just_pressed("slide") and is_on_floor() and direction != 0 and not is_sliding and not is_attacking and not is_hurt and not is_toggling_sword:
		is_sliding = true
		animated_sprite.play("slide")

	# Play the correct movement animation, but only when not attacking, hurt,
	# toggling the sword, or sliding (sliding has its own animation already playing above).
	if not is_attacking and not is_hurt and not is_toggling_sword and not is_sliding:
		if is_on_floor():
			if direction == 0:
				if sword_drawn:
					animated_sprite.play("idlewithsword")
				else:
					animated_sprite.play("Idle")
			else:
				animated_sprite.play("Run")
		else:
			in_air()

	# Actually apply the calculated velocity and handle collisions.
	move_and_slide()
