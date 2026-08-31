extends Area2D

const SPEED = 200.0
const DAMAGE = 2

# Set by the Golem right after spawning - a normalized direction, not a target.
var direction: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lifetime: Timer = $Lifetime


func _ready() -> void:
	animated_sprite.play("arm_projectile")  # rename to match whatever you call this animation
	lifetime.start(5.0)  # safety despawn in case it never hits anything or leaves the level


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()


func _on_lifetime_timeout() -> void:
	queue_free()
