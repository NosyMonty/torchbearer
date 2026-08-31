extends CharacterBody2D

enum State { DORMANT, APPEARING, IDLE, MELEE, RANGE, LASER_TELEGRAPH, LASER, ARMOR_BUFF, IMMUNE, HURT, DEAD }
var current_state: State = State.DORMANT

# Distance thresholds for choosing an attack - tune these once you see it
# in-engine relative to your actual level scale.
const MELEE_RANGE = 60
const RANGE_ATTACK_RANGE = 220.0  # beyond melee, up to this = projectile; beyond this = laser

const MELEE_DAMAGE = 3
const RANGE_DAMAGE = 2
const LASER_DAMAGE = 3

const ARMOR_BUFF_COOLDOWN = 15.0
const IMMUNE_DURATION = 4.0

# Deliberately slow - this is meant to be a lumbering, mostly-stationary
# turret that only creeps toward the player, not a real chaser.
const CHASE_SPEED = 15.0

# How far the laser's damage hitbox reaches - should roughly match how far
# the beam visually extends in the laser-cast animation's later frames.
const LASER_REACH = 280.0
# The first frame (0-indexed) where the beam is considered "fully extended"
# and should start being able to hit the player. Adjust once you see the
# actual animation - count how many frames in laser-cast show the charging
# orb vs the extending beam.
const LASER_ACTIVE_START_FRAME = 5

const PROJECTILE_SCENE := preload("res://Scenes/GolemProjectile.tscn")

var max_health := 20
var health := max_health
var player_ref: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var melee_area: Area2D = $MeleeArea
@onready var laser_area: Area2D = $LaserArea
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var armor_buff_cooldown: Timer = $ArmorBuffCooldown
@onready var immune_duration_timer: Timer = $ImmuneDuration


func _ready() -> void:
	# Sits statically on the collapsed pose until the player is detected -
	# not playing anything yet, just showing the final frame.
	var frame_count = animated_sprite.sprite_frames.get_frame_count("death_apperance")
	animated_sprite.frame = frame_count - 1
	melee_area.get_node("CollisionShape2D").set_deferred("disabled", true)
	laser_area.get_node("CollisionShape2D").set_deferred("disabled", true)


func change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.APPEARING:
			animated_sprite.play("death_apperance", -1.0, true)
		State.IDLE:
			animated_sprite.play("idle")
		State.MELEE:
			animated_sprite.play("melee")
		State.RANGE:
			animated_sprite.play("range_attack")
		State.LASER_TELEGRAPH:
			animated_sprite.play("glowing")
		State.LASER:
			animated_sprite.play("laser-cast")
			position_laser_area()
		State.ARMOR_BUFF:
			animated_sprite.play("armor_buff")
		State.IMMUNE:
			animated_sprite.play("glowing")
			immune_duration_timer.start(IMMUNE_DURATION)
		State.DEAD:
			animated_sprite.play("death_apperance", 1.0, false)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.DORMANT:
		player_ref = body
		change_state(State.APPEARING)


func _physics_process(_delta: float) -> void:
	if current_state != State.IDLE or not player_ref:
		return

	# Face whichever side the player is on.
	animated_sprite.flip_h = player_ref.global_position.x < global_position.x

	var distance = global_position.distance_to(player_ref.global_position)
	print(distance)

	# Creep toward the player at a crawl while out of melee range - stops
	# moving entirely once close enough that an attack decision takes over.
	if distance > MELEE_RANGE:
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * CHASE_SPEED
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# Armor buff takes priority over attacking whenever it's off cooldown.
	if armor_buff_cooldown.is_stopped():
		change_state(State.ARMOR_BUFF)
		return

	if attack_cooldown.is_stopped():
		if distance <= MELEE_RANGE:
			change_state(State.MELEE)
		elif distance <= RANGE_ATTACK_RANGE:
			change_state(State.RANGE)
		else:
			change_state(State.LASER_TELEGRAPH)


func position_laser_area() -> void:
	var shape: CollisionShape2D = laser_area.get_node("CollisionShape2D")
	var direction_sign = -1.0 if animated_sprite.flip_h else 1.0
	laser_area.position.x = direction_sign * (LASER_REACH / 2.0)
	if shape.shape is RectangleShape2D:
		shape.shape.size = Vector2(LASER_REACH, 20)


func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state == State.MELEE and animated_sprite.frame == 2:
		if player_ref and melee_area.overlaps_body(player_ref):
			player_ref.take_damage(MELEE_DAMAGE)

	if current_state == State.RANGE and animated_sprite.frame == 2:
		spawn_projectile()

	if current_state == State.LASER:
		var shape: CollisionShape2D = laser_area.get_node("CollisionShape2D")
		if animated_sprite.frame >= LASER_ACTIVE_START_FRAME:
			shape.set_deferred("disabled", false)
			if player_ref and laser_area.overlaps_body(player_ref):
				player_ref.take_damage(LASER_DAMAGE)
		else:
			shape.set_deferred("disabled", true)


func spawn_projectile() -> void:
	if not player_ref:
		return
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (player_ref.global_position - global_position).normalized()


func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		State.APPEARING:
			change_state(State.IDLE)
			armor_buff_cooldown.start(ARMOR_BUFF_COOLDOWN)
		State.MELEE, State.RANGE, State.LASER:
			if current_state == State.LASER:
				laser_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			attack_cooldown.start()
			change_state(State.IDLE)
		State.LASER_TELEGRAPH:
			change_state(State.LASER)
		State.ARMOR_BUFF:
			change_state(State.IMMUNE)
		State.DEAD:
			detection_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			melee_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			laser_area.get_node("CollisionShape2D").set_deferred("disabled", true)
			$CollisionShape2D.set_deferred("disabled", true)
			queue_free()


func _on_immune_duration_timeout() -> void:
	armor_buff_cooldown.start(ARMOR_BUFF_COOLDOWN)
	change_state(State.IDLE)


func flash_hurt() -> void:
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_callback(func(): change_state(State.IDLE))


func take_damage(amount: int) -> void:
	if current_state in [State.DEAD, State.IMMUNE, State.DORMANT, State.APPEARING]:
		return
	health -= amount
	if health <= 0:
		change_state(State.DEAD)
	else:
		current_state = State.HURT
		flash_hurt()
		
