extends Control

# These paths must exactly match your node names in the scene tree above -
# if you rename a button in the editor, update the path here too.
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var background: TextureRect = $Background
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	# Hide Continue entirely if there's nothing to continue from yet -
	# this is what SaveManager.has_save_file() was built for.
	continue_button.visible = SaveManager.has_save_file()

	var level_path = SaveManager.save_data.current_level
	var current_theme = SaveManager.get_theme_for_level(level_path)
	if current_theme:
		theme = current_theme

	var bg_texture = SaveManager.get_background_for_level(level_path)
	if bg_texture:
		background.texture = bg_texture

	var music = SaveManager.get_music_for_level(level_path)
	if music:
		music_player.stream = music
		music_player.play()


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
