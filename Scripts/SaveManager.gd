extends Node

# This script is an AUTOLOAD (singleton) - it stays loaded for the entire
# game, across every scene change, so it's the right place to hold data
# that needs to survive moving between levels (and even closing the game).

const SAVE_PATH := "user://savegame.save"

# This is the "shape" of everything that gets saved. Think of it as the
# single source of truth for player progress - every other system
# (checkpoints, shop, weapons) will read from and write to this Dictionary.
var save_data := {
	"current_level": "res://Scenes/tutorial_level.tscn",  # default/fallback starting level
	"current_checkpoint": "",                    # id of the last checkpoint activated
	"coins": 0,
	"shards": [],            # e.g. ["mini_boss_1", "mini_boss_2"]
	"unlocked_weapons": []   # e.g. ["fireball_upgrade"]
}


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	# JSON.stringify converts our Dictionary into a text format we can write to disk
	file.store_string(JSON.stringify(save_data))
	file.close()


func load_game() -> bool:
	if not has_save_file():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null:
		# File existed but was corrupt/empty - treat as no save
		return false

	save_data = parsed
	return true


func reset_save() -> void:
	save_data = {
		"current_level": "res://Scenes/tutorial_level.tscn",
		"current_checkpoint": "",
		"coins": 0,
		"shards": [],
		"unlocked_weapons": []
	}
	if has_save_file():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# --- Called by other systems as you build them ---

func set_checkpoint(level_path: String, checkpoint_id: String) -> void:
	save_data.current_level = level_path
	save_data.current_checkpoint = checkpoint_id
	save_game()


func complete_level(next_level_path: String) -> void:
	save_data.current_level = next_level_path
	save_data.current_checkpoint = ""  # fresh level, no checkpoint reached yet
	save_game()


func add_coins(amount: int) -> void:
	save_data.coins += amount


func collect_shard(shard_id: String) -> void:
	if not save_data.shards.has(shard_id):
		save_data.shards.append(shard_id)


func unlock_weapon(weapon_name: String) -> void:
	if not save_data.unlocked_weapons.has(weapon_name):
		save_data.unlocked_weapons.append(weapon_name)
