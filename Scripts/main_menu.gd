extends Control

# These paths must exactly match your node names in the scene tree above -
# if you rename a button in the editor, update the path here too.
@onready var continue_button: Button = $VBoxContainer/ContinueButton


func _ready() -> void:
	# Hide Continue entirely if there's nothing to continue from yet -
	# this is what SaveManager.has_save_file() was built for.
	continue_button.visible = SaveManager.has_save_file()
	var current_theme = SaveManager.get_theme_for_level(SaveManager.save_data.current_level)
	if current_theme:
		theme = current_theme


func _on_new_game_button_pressed() -> void:
	# Wipe any old progress so a fresh playthrough doesn't inherit
	# leftover coins/shards/checkpoint from a previous save.
	SaveManager.reset_save()
	get_tree().change_scene_to_file(SaveManager.save_data.current_level)


func _on_continue_button_pressed() -> void:
	SaveManager.load_game()
	get_tree().change_scene_to_file(SaveManager.save_data.current_level)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
