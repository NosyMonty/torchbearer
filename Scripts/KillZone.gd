extends Area2D
@onready var timer: Timer = $Timer

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	print("You DIED!!!")
	Engine.time_scale = 0.5
	fade_to_black()
	

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
