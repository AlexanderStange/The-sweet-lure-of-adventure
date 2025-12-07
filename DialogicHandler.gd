# DialogicHelper.gd
extends Node

# Start a Dialogic timeline for a specific player, ensuring it's shown in their viewport/UI
func start_timeline_for_player(player_index: int, timeline_name: String) -> void:
	# Assume you have a SplitScreenManager autoload or singleton to get player's UI root
	var player_ui_root = SplitScreenManager.get_ui_root_for_player(player_index)
	if player_ui_root == null:
		push_error("No UI root for player %d" % player_index)
		return

	# Check if Dialogic node exists under player's UI root, else instance one
	var dialogic_node = player_ui_root.get_node_or_null("Dialogic")
	if dialogic_node == null:
		dialogic_node = preload("res://addons/dialogic/Dialogic.tscn").instantiate()
		player_ui_root.add_child(dialogic_node)
	
	# Start timeline (Dialogic's start_timeline requires a timeline name and optionally a custom node for UI)
	dialogic_node.start_timeline(timeline_name)
