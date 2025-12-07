extends Node3D
class_name NPCDialogue

@export var timeline: String = ""
@export var one_time_only: bool = false

var has_talked: bool = false

func dialogue(player: Player, timeline) -> void:
	
	
	if one_time_only and has_talked:
		return
	if timeline.is_empty():
		push_warning("NPC %s has no timeline assigned" % name)
		return

	# Get the SplitScreenManager singleton
	var ssm = get_tree().get_root().get_node_or_null("Node3D/CanvasLayer/SplitScreenManager")
	if not ssm:
		push_warning("SplitScreenManager not found in scene tree!")
		return

	# Get the correct UI layer for this player index
	var ui_layer = ssm.ui_layers[player.player_data.player_index] if player.player_data.player_index < ssm.ui_layers.size() else null
	if not ui_layer:
		push_warning("UI layer not found for player %d" % player.player_index)
		return

	# Start the timeline and attach it to the player's UI
	var dialog_instance = Dialogic.start(timeline)
	if dialog_instance:
		if dialog_instance.get_parent():
			dialog_instance.get_parent().remove_child(dialog_instance)
		ui_layer.add_child(dialog_instance)
		dialog_instance.show()

	has_talked = true
