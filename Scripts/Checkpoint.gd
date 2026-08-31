extends Area2D

# Set a unique value for this in the Inspector for every checkpoint you
# place - it doesn't need to mean anything, just needs to be different
# from every other checkpoint's id.
@export var checkpoint_id: String = "checkpoint_1"


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var level_path = get_tree().current_scene.scene_file_path
		SaveManager.set_checkpoint(level_path, checkpoint_id, global_position)
		print("Checkpoint activated: ", checkpoint_id)
