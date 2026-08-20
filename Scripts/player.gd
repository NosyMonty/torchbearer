extends CharacterBody2D
const SPEED = 130.0
const SLIDE_SPEED = 220.0
const JUMP_VELOCITY = -350.0
const AIR_ATTACK_THRUST_SPEED = 600.0
var is_attacking = false
var count = 0
var air_attack_stage = 0          # 0 = none, 1/2 = airattack1/2, 3 = looping airattack3loop
var can_double_jump = true
var is_double_jumping = false
var sword_drawn = false
var is_toggling_sword = false
var is_sliding = false
var max_health: int = 5
var health: int = max_health
var is_hurt = false
var is_dead = false
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
# NOTE: frame == 2 is assumed for the new air attack animations too - verify this
# actually lines up with each animation's swing frame and adjust if not.
func _on_animated_sprite_2d_frame_changed() -> void:
	var attack_animations = ["attack1", "attack2", "attack3", "airattack1", "airattack2", "airattack3loop", "airattack3ground"]
	if animated_sprite.animation in attack_animations:
		if animated_sprite.frame == 2:
			attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
		else:
			attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	else:
		attack_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

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
		is_dead = true
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
	tween.tween_callback(func(): show_game_over(canvas))

func show_game_over(fade_canvas: CanvasLayer) -> void:
	fade_canvas.queue_free()
	var game_over_scene = preload("res://scenes/GameOver.tscn")
	var game_over_instance = game_over_scene.instantiate()
	get_tree().root.add_child(game_over_instance)

# Fires automatically whenever ANY animation on the player finishes playing.
# Used to reset state variables once their animation is done, so the next
# action can only start after the current one has properly finished.
# NOTE: airattack3loop is intentionally NOT handled here - since it loops,
# Godot fires animation_finished every loop cycle, and we don't want that
# to reset is_attacking mid-loop. The loop is only ever exited by landing,
# which is handled directly in _physics_process instead.
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation in ["attack1", "attack2"]:
		is_attacking = false
	elif animated_sprite.animation == "attack3":
		is_attacking = false
		count = 0
	elif animated_sprite.animation in ["airattack1", "airattack2"]:
		is_attacking = false
	elif animated_sprite.animation == "airattack3ground":
		is_attacking = false
		air_attack_stage = 0
	elif animated_sprite.animation == "smrslt":
		is_double_jumping = false
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
	# True only while airattack1 or airattack2 is actively playing - this is
	# what makes the player "hang" in place during those two hits.
	var is_air_attack_frozen := is_attacking and (air_attack_stage == 1 or air_attack_stage == 2)

	# Gravity is skipped entirely while frozen (velocity forced to zero each
	# frame) or while thrusting down in the loop (velocity.y forced to a fixed
	# fast speed instead of accumulating gravity normally). Otherwise, gravity
	# always applies as before, even when dead.
	if not is_on_floor():
		if is_air_attack_frozen:
			velocity = Vector2.ZERO
		elif air_attack_stage == 3:
			velocity.y = AIR_ATTACK_THRUST_SPEED
		else:
			velocity += get_gravity() * delta

	# Landing while in the airattack3 loop auto-triggers the ground finisher.
	# This runs BEFORE the general floor-reset below so it can catch stage == 3
	# before that reset would otherwise clear it.
	if is_on_floor() and air_attack_stage == 3:
		animated_sprite.play("airattack3ground")
		air_attack_stage = 0
		# is_attacking stays true here - the finisher still deals damage,
		# and gets reset automatically when its animation_finished fires above.

	# Any time the player is grounded and not mid-attack, both double jump
	# and any leftover air combo progress reset for the next time they're airborne.
	if is_on_floor():
		can_double_jump = true
		if not is_attacking:
			air_attack_stage = 0

	# Jump — blocked while dead. Ground jump and double jump are separate cases.
	if Input.is_action_just_pressed("jump") and not is_dead:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			if is_sliding:
				is_sliding = false
		elif can_double_jump:
			velocity.y = JUMP_VELOCITY
			can_double_jump = false
			# Jump interrupts an in-progress air attack, per design.
			is_attacking = false
			air_attack_stage = 0
			is_double_jumping = true
			animated_sprite.play("smrslt")

	var direction := Input.get_axis("move_left", "move_right")
	if is_dead:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif is_air_attack_frozen:
		# Fully frozen - velocity.x was already zeroed above and stays that
		# way. Deliberately not touching flip_h either, so facing direction
		# doesn't change mid-freeze.
		pass
	else:
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
		if direction:
			if is_sliding:
				velocity.x = direction * SLIDE_SPEED
			else:
				velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	# Ground attack combo — now correctly requires is_on_floor(), which it
	# didn't before (meaning attack used to fire in mid-air too).
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking and not is_hurt and not is_sliding and not is_dead:
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

	# Air attack combo — mirrors the ground combo, but only while airborne.
	# Reaching stage 3 plays the looping spin instead of a one-shot animation;
	# landing while in that loop is what triggers the ground finisher above.
	if Input.is_action_just_pressed("attack") and not is_on_floor() and not is_attacking and not is_hurt and not is_dead and not is_double_jumping:
		is_attacking = true
		air_attack_stage += 1
		if air_attack_stage == 1:
			animated_sprite.play("airattack1")
			print("Air Attack Combo Step: 1")
		elif air_attack_stage == 2:
			animated_sprite.play("airattack2")
			print("Air Attack Combo Step: 2")
		elif air_attack_stage >= 3:
			air_attack_stage = 3
			animated_sprite.play("airattack3loop") 
			print("Air Attack Combo Step: 3")

	# Sword toggle — blocked while dead.
	if Input.is_action_just_pressed("draw_sword") and not is_toggling_sword and not is_attacking and not is_hurt and not is_sliding and not is_dead:
		is_toggling_sword = true
		if sword_drawn:
			animated_sprite.play("sheathesword")
		else:
			animated_sprite.play("drawsword")

	# Slide — blocked while dead.
	if Input.is_action_just_pressed("slide") and is_on_floor() and direction != 0 and not is_sliding and not is_attacking and not is_hurt and not is_toggling_sword and not is_dead:
		is_sliding = true
		animated_sprite.play("slide")

	# Movement animation — blocked while dead, mid-attack, or mid-double-jump,
	# since those animations are already playing and shouldn't be overridden.
	if not is_attacking and not is_hurt and not is_toggling_sword and not is_sliding and not is_dead and not is_double_jumping:
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

	move_and_slide()
