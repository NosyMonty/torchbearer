extends CharacterBody2D

# THE CORE IDEA: ONE STATE VARIABLE
enum State { SLEEP, WAKE, CHASE, ATTACK, HURT, DEAD, IDLEFLY }
var current_state: State = State.SLEEP

var speed: float = 80.0
var health: int = 3
var damage_amount: int = 1
var player: CharacterBody2D = null

@onready var anim = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var hurt_area = $HurtArea

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state == State.ATTACK:
		if anim.frame == 2:
			deal_damage_to_player()

func _ready() -> void:
	# Ensure the bat starts strictly in the sleep state
	change_state(State.SLEEP)

func _physics_process(_delta: float) -> void:
	# Only move if we are actively chasing
	if current_state == State.CHASE and player != null:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

		# Flip the sprite to face the player
		if direction.x != 0:
			anim.flip_h = direction.x < 0
	else:
		# Halt movement in all other states (sleep, wake, attack, hurt, dead)
		velocity = Vector2.ZERO

# state transition manger
func change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return

	current_state = new_state

	# Play the corresponding animation the moment the state changes
	match current_state:
		State.SLEEP:
			anim.play("sleep")
		State.WAKE:
			anim.play("wakeup")
		State.CHASE:
			anim.play("run") # or "idlefly"
		State.ATTACK:
			anim.play("attack1")
		State.HURT:
			anim.play("hurt")
		State.DEAD:
			anim.play("die")
		State.IDLEFLY:
			anim.pay("idlefly")
			disable_hitboxes()

# SIGNALS: WHAT ENDS OR BEGINS STATES 

func _on_detection_area_body_entered(body: Node2D) -> void:
	# Check if the overlapping body is the player using Groups
	if body.is_in_group("player") and current_state == State.SLEEP:
		player = body
		change_state(State.WAKE)

func _on_detection_area_body_exited(body: Node2D) -> void:
	# Optional give-up behaviour
	if body == player and current_state == State.CHASE:
		player = null
		change_state(State.SLEEP)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player and current_state == State.CHASE:
		change_state(State.ATTACK)

func _on_animated_sprite_2d_animation_finished() -> void:
	# Purely animation-driven transitions
	match current_state:
		State.WAKE:
			change_state(State.CHASE)
		State.ATTACK:
			# Cooldown spacing: naturally created by returning to chase.
			change_state(State.CHASE) 
		State.HURT:
			change_state(State.CHASE)
		State.DEAD:
			queue_free() # Deletes the node permanently

# MIRRORED DAMAGE SYSTEM

# 1. Bat takes damage (Call this when player's attack hits the Bat's HurtBox)
func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	health -= amount
	if health <= 0:
		change_state(State.DEAD)
	else:
		change_state(State.HURT)

# 2. Player takes damage 
# (Call this function partway through the bat's attack animation)
func deal_damage_to_player() -> void:
	if attack_area.overlaps_body(player):
		if player.has_method("take_damage"):
			player.take_damage(damage_amount)

# Gap 5 Fix: Disabling collisions
func disable_hitboxes() -> void:
	# Use set_deferred because disabling collision shapes during physics calculations causes Godot errors
	detection_area.get_node("CollisionShape2D").set_deferred("disabled", true)
	attack_area.get_node("CollisionShape2D").set_deferred("disabled", true)
	hurt_area.get_node("CollisionShape2D").set_deferred("disabled", true)
