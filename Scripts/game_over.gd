extends CanvasLayer

@onready var control: Control = $Control


func _ready() -> void:
	# By the time this scene is added to the tree, get_tree().current_scene
	# still points to whatever level the player died in (Cave, Village, etc.) -
	# GameOver is added as a sibling of it, not as a replacement for it.
	var level_path = get_tree().current_scene.scene_file_path
	var current_theme = SaveManager.get_theme_for_level(level_path)
	print("level_path: ", level_path)
	print("current_theme: ", current_theme)

	if current_theme:
		control.theme = current_theme


func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()
	queue_free()
